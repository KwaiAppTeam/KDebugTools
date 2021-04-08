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
import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:k_debug_tools/src/webserver/handlers/ws_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart' as shelf;
import 'package:shelf_web_socket/shelf_web_socket.dart' as ws;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:stream_channel/stream_channel.dart';

import '../handler_def.dart';

const String JpgBoundaryTag = 'boundaryaaaaaxiba'; //随机字符串 用于分割响应内容

class ScreenRecorderHandler extends AbsAppHandler {
  static const MethodChannel _recordChannel =
      const MethodChannel('kdebugtools/screen_preview');
  static const String MODULE = 'screenrecorder';
  static const int CMD_STATE = 0;
  static const int CMD_KEEP_ALIVE = 1;

  OnSocketData _onData;
  Timer _closeWatcher;

  List<StreamChannel<List<int>>> _previewCgiRequests =
      <StreamChannel<List<int>>>[];
  List<WebSocketChannel> _previewWs = <WebSocketChannel>[];

  @override
  shelf.Router get router {
    final router = shelf.Router();

    router.get('/state', _recordStat);
    //preview websocket todo 目前flutter web使用mjpeg有bug xhr直接阻塞了 或者onprogress中reponse数据为空 提供websocket进行推送
    router.get('/previewws/<ws|.*>', ws.webSocketHandler(_handlePreviewWs));
    router.get('/previewcgi/<name|.*>', _previewCgi);
    //截图
    router.post('/takeCapture', _takeCapture);
    router.post('/startPreview', _startPreview);
    router.post('/stopPreview', _stopPreview);
    router.post('/startRecordToFile', _startRecordToFile);
    router.post('/stopRecordToFile', _stopRecordToFile);

    router.all('/<ignored|.*>', (Request request) => notFound());

    return router;
  }

  ///投屏预览 websocket连接
  void _handlePreviewWs(WebSocketChannel webSocket) {
    debugPrint('preview ws onConnect');
    _previewWs.add(webSocket);
    //立即输入第一张图
    _recordChannel.invokeMethod('lastPreviewJpg').then((jpgBytes) {
      if (jpgBytes != null && jpgBytes is Uint8List) {
        debugPrint('write lastPreviewJpg to ws...');
        _sendPreviewJpgToWs(jpgBytes, webSocket.sink);
      }
    });
    webSocket.stream.listen((m) {})
      ..onDone(() {
        debugPrint('preview ws onDone');
        _previewWs.remove(webSocket);
      })
      ..onError((e) {
        debugPrint('preview ws onError, $e');
        _previewWs.remove(webSocket);
      });
  }

  ///状态
  Future<Response> _recordStat(Request request) async {
    var state = await _recordChannel.invokeMethod('state');
    if (state['code'] == 0) {
      //success
      Map data = state['data'] as Map;
      data['dir'] = await _recordFilePath('');
      return ok(data);
    } else {
      return error(state['msg']);
    }
  }

  ///开启预览
  Future<Response> _startPreview(Request request) async {
    Map result = await _recordChannel.invokeMethod('startPreview');
    //register data callback
    _recordChannel.setMethodCallHandler(handleMethodCall);
    _onData ??= (m) {
      //web端发来的心跳 返回给它一个状态信息
      if (m.cmd == CMD_KEEP_ALIVE) {
        //send state
        _sendRecorderState();
      }
    };
    _setupCloseWatcher();
    WebSocketHandler.registerSub(MODULE, _onData);
    if (result['code'] == 0) {
      //success
      return ok(result);
    } else {
      return error(result['msg']);
    }
  }

  ///是否已经开启屏幕预览
  Future<bool> _isPreviewing() async {
    var state = await _recordChannel.invokeMethod('state');
    Map data = state['data'] as Map;
    bool previewing = data['previewing'];
    return previewing;
  }

  ///mjpeg流
  Future<Response> _previewCgi(Request request, String name) async {
    debugPrint('previewCgi: $name');
    //check is previewing
    if (!await _isPreviewing()) {
      //未进行预览
      return notFound(msg: 'Not Previewing');
    }
    //目前shelf无法获取浏览器断开事件,进行hijack后自己写入response和管理socket
    request.hijack((socket) async {
      //通过sink写入response
      BytesBuilder header = BytesBuilder(copy: true);
      header.add('HTTP/1.1 200 OK\r\n'.codeUnits);
      header.add(
          'date: ${HttpDate.format(DateTime.now().toUtc())}\r\n'.codeUnits);
      header.add('access-control-allow-origin: *\r\n'.codeUnits);
      header.add('Cache-Control: no-cache\r\n'.codeUnits);
      header.add('Pragma: no-cache\r\n'.codeUnits);
      header.add(
          'content-type: multipart/x-mixed-replace; boundary=$JpgBoundaryTag\r\n'
              .codeUnits);
      header.add('server: dart:io with Shelf\r\n'.codeUnits);
      header.add('transfer-encoding: chunked\r\n'.codeUnits);
      header.add('\r\n'.codeUnits);
      socket.sink.add(header.takeBytes());
      header.clear();

      //之后就是不断写入文件
      //立即输入第一张图 x2才能显示出来
      var jpgBytes = await _recordChannel.invokeMethod('lastPreviewJpg');
      if (jpgBytes != null && jpgBytes is Uint8List) {
        debugPrint('write lastPreviewJpg...');
        _sendPreviewJpgToRequest(jpgBytes, socket.sink);
        _sendPreviewJpgToRequest(jpgBytes, socket.sink);
      }

      //socket保存起来 后面更新后还要发送
      _previewCgiRequests.add(socket);

      //监听断开 之后不再发送
      socket.stream.listen((dt) {}, onDone: () {
        debugPrint('previewCgi request onDone');
        _previewCgiRequests.remove(socket);
      }, onError: (e) {
        debugPrint('previewCgi request onError $e');
        _previewCgiRequests.remove(socket);
      }, cancelOnError: true);
    });
    return null;
  }

  ///发送图像给websocket
  void _sendPreviewJpgToWs(Uint8List jpgBytes, WebSocketSink sink) {
    if (jpgBytes != null && jpgBytes is Uint8List && jpgBytes.length > 0) {
      BytesBuilder jpgBoundary = BytesBuilder(copy: true);
      jpgBoundary
          .add(jpgBytes.length.toRadixString(16).toUpperCase().codeUnits);
      jpgBoundary.add('\r\n'.codeUnits);
      jpgBoundary.add(jpgBytes);
      jpgBoundary.add('\r\n'.codeUnits);

      sink.add(jpgBoundary.takeBytes());
    }
  }

  ///发送图像给cgi请求
  void _sendPreviewJpgToRequest(
      Uint8List jpgBytes, StreamSink<List<int>> sink) {
    if (jpgBytes != null && jpgBytes is Uint8List && jpgBytes.length > 0) {
      BytesBuilder jpgBoundary = BytesBuilder(copy: true);

      jpgBoundary.add('--$JpgBoundaryTag\r\n'.codeUnits);
      jpgBoundary.add('Content-Type: image/jpeg\r\n'.codeUnits);
      jpgBoundary.add('Content-Length: ${jpgBytes.length}\r\n'.codeUnits);
      jpgBoundary.add('\r\n'.codeUnits);
      jpgBoundary.add(jpgBytes);
      jpgBoundary.add('\r\n'.codeUnits);
      jpgBoundary.add('\r\n'.codeUnits);

      BytesBuilder chunk = BytesBuilder(copy: true);
      chunk.add(jpgBoundary.length.toRadixString(16).toUpperCase().codeUnits);
      chunk.add('\r\n'.codeUnits);
      chunk.add(jpgBoundary.takeBytes());
      chunk.add('\r\n'.codeUnits);
      //结束写0
//      chunk.add('0\r\n\r\n'.codeUnits);
      sink.add(chunk.takeBytes());
    }
  }

  ///监听是否还有需要推送的websocket或者cgi, 没有后5s 停止预览 停止录像
  void _setupCloseWatcher() {
    _closeWatcher?.cancel();
    _closeWatcher = Timer(Duration(seconds: 5), () {
      if (_previewCgiRequests.isEmpty && _previewWs.isEmpty) {
        debugPrint('Client not alive, stop preview ');
        _recordChannel.invokeMethod('stopPreview');
        _closeWatcher?.cancel();
      }
    });
  }

  ///发送状态信息给web 收到心跳后调用
  Future _sendRecorderState() async {
    var state = await _recordChannel.invokeMethod('state');
    Map data = state['data'] as Map;
    data['dir'] = await _recordFilePath('');
    WebSocketHandler.broadcastJson(MODULE, CMD_STATE, data);
  }

  ///处理平台端发来的调用
  Future<dynamic> handleMethodCall(MethodCall call) {
//    debugPrint('handleMethodCall >>> ${call.method}');
    if (call.method == 'onPreviewData') {
      //发送给websocket
      _previewWs.forEach((element) {
        _sendPreviewJpgToWs(call.arguments['data'], element.sink);
      });
      //发送给cgi请求
      _previewCgiRequests.forEach((element) {
        _sendPreviewJpgToRequest(call.arguments['data'], element.sink);
      });
      return Future.value(0);
    }
    return Future.value("ok");
  }

  ///结束预览
  Future<Response> _stopPreview(Request request) async {
    var result = await _recordChannel.invokeMethod('stopPreview');
    WebSocketHandler.unregisterSub(MODULE, _onData);
    if (result['code'] == 0) {
      return ok(result['data']);
    } else {
      return error(result['msg']);
    }
  }

  ///开始录入文件
  Future<Response> _startRecordToFile(Request request) async {
    var result = await _recordChannel.invokeMethod('startRecordToFile', {
      "fileAbsolutePath": await _recordFilePath(
          DateFormat('yyyy-MM-dd HH:mm:ss').format((DateTime.now())) + '.mp4')
    });
    if (result['code'] == 0) {
      return ok(result['data']);
    } else {
      return error(result['msg']);
    }
  }

  ///结束录入文件
  Future<Response> _stopRecordToFile(Request request) async {
    var result = await _recordChannel.invokeMethod('stopRecordToFile');
    //返回文件路径 todo 时长等信息
    if (result['code'] == 0) {
      return ok(result['data']);
    } else {
      return error(result['msg']);
    }
  }

  ///预览截图到png
  Future<Response> _takeCapture(Request request) async {
    var result = await _recordChannel.invokeMethod('takeCapture', {
      "fileAbsolutePath": await _recordFilePath('screenshot-' +
          DateFormat('yyyy-MM-dd HH:mm:ss').format((DateTime.now())) +
          '.png')
    });
    if (result['code'] == 0) {
      return ok(result['data']);
    } else {
      return error(result['msg']);
    }
  }

  ///录入到文件的路径
  Future<String> _recordFilePath(String name) async {
    String path;
    if (Platform.isAndroid) {
      final appDir = await getApplicationSupportDirectory();
      path = appDir.path.substring(0, appDir.path.lastIndexOf('/'));
//
//      final exAppDir = await getExternalStorageDirectory();
//      List<String> ps = exAppDir.path.split('/');
//      String externalPath = ps.sublist(0, ps.length - 1).join('/');
    } else {
      //ios
      final docDir = await getApplicationDocumentsDirectory();
      path = docDir.path;
    }
    return '$path/screen/$name';
  }
}
