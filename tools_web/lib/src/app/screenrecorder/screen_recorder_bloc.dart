// Copyright 2021 Kwai, Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';
import 'package:k_debug_tools_web/src/app/fileexplorer/file_explorer_bloc.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/web_http.dart';
import 'package:k_debug_tools_web/src/websocket/web_socket_bloc.dart';
import 'package:k_debug_tools_web/src/websocket/web_socket_models.dart';
import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../model.dart';

class ScreenRecorderBloc extends AppBlocBase {
  static const String PATH = 'api/screenrecorder';
  static const String MODULE = 'screenrecorder';

  static const int CMD_STATE = 0;
  static const int CMD_KEEP_ALIVE = 1;

  HtmlWebSocketChannel _wsChannel;
  int _st = 0;
  BehaviorSubject<int> _stateSub = BehaviorSubject<int>();

  Sink<int> get _stateSink => _stateSub.sink;

  Stream<int> get stateStream => _stateSub.stream;

  ///定时发送心跳 保持预览
  Timer _keepAliveTimer;

  ///检查收取状态数据时间 超时认为断开
  Timer _stateWatcher;

  ///ws重连
  Timer _connectWatcher;
  WebSocketBloc _webSocketBloc;
  OnSocketData _onWsData;

  String _dir;

  String get fileDir => _dir ?? '';

  String get cgiUrl =>
      '${getHostWithSchema()}/$PATH/previewcgi/1.cgi?Token=${getToken()}';

  bool _isAppServiceRunning = false;
  bool _isAppRecording = false;
  bool _isWsPause = false;

  BytesBuilder _imgDataBuffer;

  Uint8List _lastPreviewData;

  Uint8List get lastPreviewData => _lastPreviewData;

  ///app投屏服务是否启动
  bool get isAppServiceRunning => _isAppServiceRunning ?? false;

  ///web预览中
  bool get isWebPreviewing => isAppServiceRunning && !_isWsPause;

  ///app是否录制屏幕中
  bool get isAppRecording => _isAppRecording ?? false;

  int _startRecordingTs = 0;

  ///已录制时长
  Duration get recordingDuration => isAppRecording
      ? Duration(
          milliseconds:
              DateTime.now().millisecondsSinceEpoch - _startRecordingTs)
      : Duration.zero;

  ///用于统计帧率码率
  List<FrameInfo> _frameTs = List<FrameInfo>();

  ///fps
  int get fps {
    _clearOldFrame();
    return _frameTs.length;
  }

  ///bps
  int get bps {
    _clearOldFrame();
    int b = 0;
    _frameTs.forEach((element) {
      b += element.length;
    });
    return b;
  }

  ScreenRecorderBloc(context) : super(context) {
    _webSocketBloc = BlocProvider.of<WebSocketBloc>(context).first;
    _onWsData = (m) {
      //5s内没有收到任何数据 状态信息 认为停止录屏
      _stateWatcher?.cancel();
      _stateWatcher = Timer(Duration(seconds: 5), () {
        _isAppServiceRunning = false;
        _isAppRecording = false;
        _stateSink.add(_st++);
      });
      if (m.cmd == CMD_STATE) {
        //状态信息
        Map map = (jsonDecode(utf8.decode(m.data)) as Map<String, dynamic>);
        _isAppServiceRunning = map['previewing'];
        _isAppRecording = map['recording'];
        _dir = map['dir'];
        _stateSink.add(_st++);
      }
    };
    _webSocketBloc.registerSub(MODULE, _onWsData);

    _connectPreviewWs();
  }

  void _connectPreviewWs() {
    debugPrint('connectPreviewWs...');
    _connectWatcher?.cancel();
    _connectWatcher = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_wsChannel == null) {
        _connectPreviewWs();
      }
    });
    _imgDataBuffer = BytesBuilder(copy: true);
    _wsChannel?.sink?.close(status.normalClosure, 'reconnect');
    _wsChannel = HtmlWebSocketChannel.connect(
        "ws://${getHost()}/$PATH/previewws/?Pin=${getPin()}",
        binaryType: BinaryType.list);
    int start = -1;
    int end = -1;
    _wsChannel.stream.listen((dt) {
      _isAppServiceRunning = true;
      var data = dt as Uint8List;
      for (var i = 0; i < data.length - 1; i++) {
        if (data[i] == 0xff && data[i + 1] == 0xd8) {
          start = _imgDataBuffer.length + i;
        }
        if (data[i] == 0xff && data[i + 1] == 0xd9) {
          end = _imgDataBuffer.length + i;
        }
      }
      _imgDataBuffer.add(data);
      if (start != -1 && end != -1) {
        //解析到一个图
        _lastPreviewData = _imgDataBuffer.takeBytes().sublist(start, end + 2);
        start = end = -1;
        _imgDataBuffer = BytesBuilder(copy: true);
        //统计fps
        _addFrame(FrameInfo(
            ts: DateTime.now().millisecondsSinceEpoch,
            length: _lastPreviewData.length));
        _stateSink.add(_st++);
      }
    })
      ..onDone(() {
        print('preview ws done');
        _wsChannel = null;
      })
      ..onError((e) {
        print('preview ws error: $e');
        _wsChannel = null;
      });
  }

  ///暂停 断开ws
  void pausePreview() {
    _isWsPause = true;
    _connectWatcher?.cancel();
    _wsChannel?.sink?.close(status.normalClosure, 'pause');
  }

  ///恢复ws连接
  void _resumePreview() {
    _isWsPause = false;
    _connectPreviewWs();
  }

  ///统计帧
  void _addFrame(FrameInfo f) {
    _frameTs.add(f);
    _clearOldFrame();
  }

  ///清除1s前的帧
  void _clearOldFrame() {
    while (true) {
      if (_frameTs.isEmpty ||
          DateTime.now().millisecondsSinceEpoch - _frameTs.elementAt(0).ts <
              1000) {
        break;
      }
      _frameTs.removeAt(0);
    }
  }

  ///开启预览
  Future startPreview() async {
    if (_isAppServiceRunning) {
      _resumePreview();
      return Future.value();
    } else {
      Uri uri = Uri.http(getHost(), '$PATH/startPreview');
      var response = await httpPost(uri);
      if (response.statusCode == 200) {
        _startKeepAliveTimer();
        return Future.value();
      } else {
        return Future.error(
            ErrorResult.create('Error', jsonDecode(response.body)));
      }
    }
  }

  ///停止预览 在dispose时会调用
  Future _stopPreview() async {
    Uri uri = Uri.http(getHost(), '$PATH/stopPreview');
    var response = await httpPost(uri);
    if (response.statusCode == 200) {
      _keepAliveTimer?.cancel();
      return Future.value();
    } else {
      return Future.error(
          ErrorResult.create('Error', jsonDecode(response.body)));
    }
  }

  ///录制到文件
  Future startRecordToFile() async {
    Uri uri = Uri.http(getHost(), '$PATH/startRecordToFile');
    var response = await httpPost(uri);
    if (response.statusCode == 200) {
      _startRecordingTs = DateTime.now().millisecondsSinceEpoch;
      _stateSink.add(_st++);
      _isAppRecording = true;
      return Future.value();
    } else {
      return Future.error(
          ErrorResult.create('Error', jsonDecode(response.body)));
    }
  }

  ///停止录制到文件 返回文件路径
  Future<String> stopRecordToFile() async {
    Uri uri = Uri.http(getHost(), '$PATH/stopRecordToFile');
    var response = await httpPost(uri);
    if (response.statusCode == 200) {
      _startRecordingTs = 0;
      _isAppRecording = false;
      _stateSink.add(_st++);
      Map<String, Object> jsonResponse = jsonDecode(response.body);
      var data = (jsonResponse['data'] as Map);
      return Future.value(data['path']);
    } else {
      return Future.error(
          ErrorResult.create('Error', jsonDecode(response.body)));
    }
  }

  ///检查状态
  Future fetchState() async {
    Uri uri = Uri.http(getHost(), '$PATH/state');
    var response = await httpGet(uri);
    if (response.statusCode == 200) {
      Map<String, Object> jsonResponse = jsonDecode(response.body);
      var data = (jsonResponse['data'] as Map);
      _isAppServiceRunning = data['previewing'];
      _isAppRecording = data['recording'];
      _dir = data['dir'];
      return Future.value();
    } else {
      return Future.error(
          ErrorResult.create('Error', jsonDecode(response.body)));
    }
  }

  ///截图下载
  Future downloadCapture() async {
    Uri uri = Uri.http(getHost(), '$PATH/takeCapture');
    var response = await httpPost(uri);
    if (response.statusCode == 200) {
      Map<String, Object> jsonResponse = jsonDecode(response.body);
      var data = (jsonResponse['data'] as Map);
      var path = data['path'];
      FileExplorerBloc b = FileExplorerBloc(context);
      b.downloadFile(path);
      b.dispose();
      return Future.value();
    } else {
      return Future.error(
          ErrorResult.create('Error', jsonDecode(response.body)));
    }
  }

  ///定时发送心跳 保持预览
  void _startKeepAliveTimer() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _webSocketBloc
          .sendMessage(WsMessage(module: MODULE, cmd: CMD_KEEP_ALIVE));
    });
  }

  @override
  void dispose() {
    _stopPreview();
    _keepAliveTimer?.cancel();
    _stateWatcher?.cancel();
    _connectWatcher?.cancel();
    _wsChannel?.sink?.close(status.normalClosure, 'dispose');
    _webSocketBloc.unregisterSub(MODULE, _onWsData);
    _stateSub.close();
  }
}

///帧信息
class FrameInfo {
  int ts;
  int length;

  FrameInfo({this.ts, this.length});
}
