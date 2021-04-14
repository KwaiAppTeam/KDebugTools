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
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:k_debug_tools/src/model/web_socket_models.dart';
import 'package:k_debug_tools/src/webserver/web_server.dart';
import 'package:shelf_router/shelf_router.dart' as shelf;
import 'package:shelf_web_socket/shelf_web_socket.dart' as ws;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../handler_def.dart';

typedef OnSocketData = void Function(WsMessage);

///websocket
class WebSocketHandler extends AbsAppHandler {
  static int _seq = 0;
  static Map<String, List<OnSocketData?>> _dataSubs =
      Map<String, List<OnSocketData?>>();
  static List<WebSocketChannel> _connects = <WebSocketChannel>[];

  static disconnectAll() {
    _connects.forEach((element) {
      element.sink.close(status.goingAway);
    });
  }

  //发送心跳
  Timer? _hbTimer;

  @override
  shelf.Router get router {
    final router = shelf.Router();
    router.get('/<id|.*>', ws.webSocketHandler(_handleWebSocketConnect));
    return router;
  }

  void _handleWebSocketConnect(WebSocketChannel webSocket) {
    debugPrint('WebSocket onConnect');
    _connects.add(webSocket);
    webSocket.stream.listen((message) {
//      webSocket.sink.add("echo $message");
      try {
        WsMessage msg =
            WsMessage.fromJson(jsonDecode(message) as Map<String, dynamic>?)!;
        _dispatchMessage(msg);
      } catch (e) {
        debugPrint('parse message error $e');
      }
    })
      ..onDone(() {
        debugPrint('WebSocket onDone');
        _connects.remove(webSocket);
      })
      ..onError((e) {
        debugPrint('WebSocket onError, $e');
        _connects.remove(webSocket);
      });
    _sendInitInfo(webSocket);
    //start heart
    _startHeartIfNeed();
  }

  void _sendInitInfo(WebSocketChannel webSocket) {
    ///给客户端发送token
    Map d = {
      'seq': 0,
      'module': 'init',
      'cmd': 0,
      'type': ContentType.json.toString(),
      'data': jsonEncode({'token': WebServer.instance.token})
    };
    _connects.forEach((element) {
      element.sink.add(jsonEncode(d));
    });
  }

  void _startHeartIfNeed() {
    if (_hbTimer == null || !_hbTimer!.isActive) {
      _hbTimer = Timer.periodic(Duration(seconds: 3), (timer) {
        if (_connects.isEmpty) {
          _hbTimer!.cancel();
          return;
        }
        broadcastJson(
            'heartbeat', 0, {'ts': DateTime.now().millisecondsSinceEpoch});
      });
    } else {
      //send heartbeat immediately
      broadcastJson(
          'heartbeat', 0, {'ts': DateTime.now().millisecondsSinceEpoch});
    }
  }

  void _dispatchMessage(WsMessage msg) {
    _dataSubs[msg.module!]?.forEach((onData) {
      try {
        onData!(msg);
      } catch (e) {
        debugPrint('dispatchMessage error $e');
      }
    });
  }

  ///注册监听
  static void registerSub(String module, OnSocketData? sub) {
    debugPrint('registerSub $module');
    if (_dataSubs[module] == null) {
      _dataSubs[module] = <OnSocketData?>[];
    }
    if (!_dataSubs[module]!.contains(sub)) {
      _dataSubs[module]!.add(sub);
    }
  }

  ///反注册监听
  static void unregisterSub(String module, OnSocketData? sub) {
    _dataSubs[module]?.remove(sub);
  }

  ///给所有连接发送数据
  static int broadcastJson(String module, int cmd, Object data) {
    _seq++;
    Map d = {
      'seq': _seq,
      'module': module,
      'cmd': cmd,
      'type': ContentType.json.toString(),
      'data': jsonEncode(data)
    };
    _connects.forEach((element) {
      element.sink.add(jsonEncode(d));
    });
    return _seq;
  }

  ///给所有连接发送数据
  static int broadcastBinary(String module, int cmd, List<int> data) {
    _seq++;
    Map d = {
      'seq': _seq,
      'module': module,
      'cmd': cmd,
      'type': ContentType.binary.toString(),
      'data': base64Encode(data) //二进制使用base64进行编码
    };
    _connects.forEach((element) {
      element.sink.add(jsonEncode(d));
    });
    return _seq;
  }

  ///给所有连接发送数据
  static int broadcastText(String module, int cmd, String data,
      {bool subscriberOnly = false}) {
    _seq++;
    Map d = {
      'seq': _seq,
      'module': module,
      'cmd': cmd,
      'type': ContentType.text.toString(),
      'data': data
    };
    _connects.forEach((element) {
      element.sink.add(jsonEncode(d));
    });
    return _seq;
  }
}
