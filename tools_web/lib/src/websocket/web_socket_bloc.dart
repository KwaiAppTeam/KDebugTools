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

import 'package:flutter/widgets.dart';
import 'package:k_debug_tools_web/src/event/PinEvent.dart';
import 'package:k_debug_tools_web/src/event_bus.dart';
import 'package:k_debug_tools_web/src/web_bloc.dart';
import 'package:k_debug_tools_web/src/web_http.dart';
import 'package:k_debug_tools_web/src/websocket/web_socket_models.dart';
import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../bloc_provider.dart';

///定义心跳间隔 未收到则重新连接
const int HBTS = 10 * 1000;

typedef OnSocketData = void Function(WsMessage);

class WebSocketBloc extends BlocBase {
  Map<String, List<OnSocketData>> _dataSubs = Map<String, List<OnSocketData>>();

  final BuildContext context;

  Timer _connectWatcher;

  HtmlWebSocketChannel _channel;
  StreamSubscription _pinStat;

  ///上次心跳时间
  int lastHbTs = 0;

  WebSocketBloc(this.context) {
    _connect();
    _pinStat = eventBus.on<PinVerified>().listen((event) {
      _connect();
    });
    _connectWatcher = Timer.periodic(Duration(seconds: 5), (t) {
      //检查是否连接
      if (!isConnected()) {
        //重新连接
        _channel?.sink?.close(status.normalClosure, 'HeartBeat timeout');
        _channel = null;
        _connect();
      }
    });
  }

  void _connect() {
    if(getPin().isEmpty){
      return;
    }
    debugPrint('start websocket connect...');
    _channel = HtmlWebSocketChannel.connect(
        "ws://${WebBloc.getHost()}/ws/0/?Pin=${getPin()}");
    _channel.stream.listen((data) {
      if (!isConnected()) {
        //通知连接变化
        debugPrint('websocket connected');
        lastHbTs = DateTime.now().millisecondsSinceEpoch;
        _dispatchStat();
      }
      //更新数据接受时间
      lastHbTs = DateTime.now().millisecondsSinceEpoch;

      WsMessage msg =
          WsMessage.fromJson(jsonDecode(data) as Map<String, dynamic>);
      _dispatchMessage(msg);
    })
      ..onDone(() {
        print('websocket done');
        lastHbTs = 0;
        _dispatchStat();
        //不断重试
      })
      ..onError((e) {
        print('websocket error: $e');
        lastHbTs = 0;
        _dispatchStat();
      });
  }

  void _dispatchStat() {
    eventBus.fire(WsStat(isConnected()));
  }

  void _dispatchMessage(WsMessage msg) {
    _dataSubs[msg.module]?.forEach((onData) {
      onData(msg);
    });
  }

  ///是否已连接服务器
  bool isConnected() {
    return _channel != null &&
        DateTime.now().millisecondsSinceEpoch - lastHbTs < HBTS;
  }

  ///注册监听
  void registerSub(String module, OnSocketData sub) {
    debugPrint('registerSub $module');
    if (_dataSubs[module] == null) {
      _dataSubs[module] = <OnSocketData>[];
    }
    if (!_dataSubs[module].contains(sub)) {
      _dataSubs[module].add(sub);
    }
  }

  ///反注册监听
  void unregisterSub(String module, OnSocketData sub) {
    _dataSubs[module]?.remove(sub);
  }

  ///发送消息
  void sendMessage(WsMessage message) {
    _channel.sink.add(jsonEncode(message));
  }

  @override
  void dispose() {
    _connectWatcher?.cancel();
    _pinStat?.cancel();
    _channel?.sink?.close(status.normalClosure, 'HeartBeat timeout');
    _channel = null;
  }
}
