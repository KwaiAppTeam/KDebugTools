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

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http_multi_server/http_multi_server.dart';
import 'package:k_debug_tools/src/webserver/handlers/app_info_handler.dart';
import 'package:k_debug_tools/src/webserver/handlers/db_view_handler.dart';
import 'package:k_debug_tools/src/webserver/handlers/device_info_handler.dart';
import 'package:k_debug_tools/src/webserver/handlers/navigator_handler.dart';
import 'package:k_debug_tools/src/webserver/handlers/pin_handler.dart';
import 'package:k_debug_tools/src/webserver/handlers/ui_check_handler.dart';
import 'package:k_debug_tools/src/webserver/handlers/ws_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart';
import 'package:wifi_info_flutter/wifi_info_flutter.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'package:shelf_proxy/shelf_proxy.dart';
import 'package:shelf_router/shelf_router.dart' as shelf_router;

import 'handler_def.dart';
import 'handlers/clip_board_handler.dart';
import 'handlers/file_handler.dart';
import 'handlers/httphook_handler.dart';
import 'handlers/logwatcher_handler.dart';
import 'handlers/photo_handler.dart';
import 'handlers/screen_recorder_handler.dart';
import 'handlers/sp_handler.dart';

///对应发布到cdn的web版本
const _WEB_VERSION = 'v1.0.2';

///用于校验身份请求
String _pinCode;

///用于校验get请求(图片视频预览 下载等会用到)
///每次开启服务均变化 通过websocket发送更新
String _token;

class WebServer {
  WebServer._privateConstructor();

  static final WebServer instance = WebServer._privateConstructor();

  static const int _DEFAULT_PORT = 9000;
  HttpServer _server;
  String _ip;

  ValueNotifier<bool> started = ValueNotifier(false);
  int _usingPort = _DEFAULT_PORT;

  int get port => _usingPort;

  String get addressV4 => _ip ?? '';

  String get url =>
      addressV4.isEmpty ? 'Wifi not connected' : 'http://$_ip:$_usingPort';

  String get pin => _pinCode ?? '';

  String get token => _token ?? '';

  ///开启服务
  Future start() async {
    await _server?.close(force: true);
    try {
      _initPinAndToken();
      _ip = await WifiInfo().getWifiIP() ?? '';
      _usingPort = _DEFAULT_PORT;
      //找到一个可用的端口绑定 找10次
      int tryTimes = 0;
      while (tryTimes < 10) {
        try {
          _server = await HttpMultiServer.bind('any', _usingPort);
          break;
        } catch (e) {
          debugPrint('bind port error. $e');
          tryTimes++;
          _usingPort++;
        }
      }
      var handler = const shelf.Pipeline()
          .addMiddleware(errorHandler())
          .addMiddleware(shelf.logRequests())
          .addMiddleware(optionsHandler())
          .addMiddleware(authRequests())
          .addHandler(_requestRouter);
      shelf_io.serveRequests(_server, handler);
      started.value = true;
    } catch (e) {
      debugPrint('start server error. $e');
      _server = null;
      //启动失败
      started.value = false;
      return Future.error(e);
    }
    return Future.value();
  }

  ///停止服务
  Future stop() async {
    if (_server == null) {
      return Future.value();
    }
    await _server.close(force: true);
    _server = null;
    started.value = false;
    WebSocketHandler.disconnectAll();
    return Future.value();
  }

  ///开启或停止
  Future startOrStop() async {
    if (_server == null) {
      return start();
    } else {
      return stop();
    }
  }

  Future _initPinAndToken() async {
    //token
    _token = '';
    while (_token.length < 4) {
      _token += Random().nextInt(10).toString();
    }
    //pin
    var pref = await SharedPreferences.getInstance();
    //从sp读取
    if (_pinCode == null) {
      var pinCreateTs = pref.getInt('KDebugTools_PIN_TS') ?? 0;
      //有效期暂定24小时
      if (DateTime.now().millisecondsSinceEpoch - pinCreateTs <
          24 * 60 * 60 * 1000) {
        _pinCode = pref.getString('KDebugTools_PIN');
      }
    }
    _pinCode ??= '';
    //生成一个并存入sp
    if (_pinCode.isEmpty) {
      while (_pinCode.length < 4) {
        _pinCode += Random().nextInt(10).toString();
      }
      pref.setInt('KDebugTools_PIN_TS', DateTime.now().millisecondsSinceEpoch);
      pref.setString('KDebugTools_PIN', _pinCode);
    }
  }

  shelf.Handler get _requestRouter {
    final router = shelf_router.Router();

//    // Handlers can be added with `router.<verb>('<route>', handler)`, the
//    // '<route>' may embed URL-parameters, and these may be taken as parameters
//    // by the handler (but either all URL parameters or no URL parameters, must
//    // be taken parameters by the handler).
//    router.get('/say-hi/<name>', (Request request, String name) {
//      return Response.ok('hi $name');
//    });
//
//    // Embedded URL parameters may also be associated with a regular-expression
//    // that the pattern must match.
//    router.get('/user/<userId|[0-9]+>', (Request request, String userId) {
//      return Response.ok('User has the user-number: $userId');
//    });
//
//    // Handlers can be asynchronous (returning `FutureOr` is also allowed).
//    router.get('/wave', (Request request) async {
//      await Future.delayed(Duration(milliseconds: 100));
//      return Response.ok('_o/');
//    });

    //index
    router.get('/', (shelf.Request request) {
      return shelf.Response.seeOther('index.html');
    });
    //WebSocket
    router.mount('/ws/', WebSocketHandler().router);
    //api
    router.mount('/api/sp/', SharedPreferencesHandler().router);
    router.mount('/api/file/', FileHandler().router);
    router.mount('/api/photo/', PhotoHandler().router);
    router.mount('/api/app/', AppInfoHandler().router);
    router.mount('/api/device/', DeviceInfoHandler().router);
    router.mount('/api/httphook/', HttpHookHandler().router);
    router.mount('/api/logwatcher/', LogWatcherHandler().router);
    router.mount('/api/dbview/', DbViewHandler().router);
    router.mount('/api/screenrecorder/', ScreenRecorderHandler().router);
    router.mount('/api/uicheck/', UiCheckHandler().router);
    router.mount('/api/clipboard/', ClipBoardHandler().router);
    router.mount('/api/navigator/', NavigatorHandler().router);
    router.mount('/api/pin/', PinHandler().router);

    //proxy other get request
    var proxy = proxyHandler(
        "http://static.yximgs.com/udata/pkg/KS-IDEA/k_debug_tools/web/$_WEB_VERSION/");
    router.get('/<proxypath|.*>', (shelf.Request request, String proxypath) {
      debugPrint('proxy request >>>>> $proxypath');
      return proxy(request);
    });
    //others
    router.all('/<ignored|.*>', (shelf.Request request) {
      return shelf.Response.notFound('Page not found');
    });
    return router.handler;
  }
}

///拦截错误 统一输出
Middleware errorHandler() {
  return (innerHandler) {
    return (request) {
      return Future.sync(() => innerHandler(request)).then((response) {
        return response;
      }, onError: (error, StackTrace stackTrace) {
        if (error is HijackException) throw error;
        debugPrint(
            'handler request error: ${request.canHijack} ${request.url}\n$error\n$stackTrace}');
        return Response.internalServerError(
            body: AbsAppHandler.buildResponseBody({'error': '$error'},
                code: 500, message: 'server error'),
            headers: AbsAppHandler.headers());
      });
    };
  };
}

///process OPTIONS requests, return OK with some headers
Middleware optionsHandler() {
  return (innerHandler) {
    return (request) {
      if (request.method.toUpperCase() == 'OPTIONS') {
        return Response.ok(AbsAppHandler.buildResponseBody(null),
            headers: AbsAppHandler.headers());
      } else {
        return innerHandler(request);
      }
    };
  };
}

///Verify requests with PIN or Token
Middleware authRequests() {
  return (innerHandler) {
    return (request) {
      bool needCheck = true;
      //only /api and /ws
      if (!request.url.path.startsWith('api') &&
          !request.url.path.startsWith('ws')) {
        needCheck = false;
      }
      //for PIN check requests
      if (request.url.path.startsWith('api/pin/check')) {
        needCheck = false;
      }
      if (needCheck) {
        String pin =
            request.headers['Pin'] ?? request.url.queryParameters['Pin'] ?? '';
        String token = request.headers['Token'] ??
            request.url.queryParameters['Token'] ??
            '';
        //GET allowed request with PIN or Token, others must request with PIN
        if (request.method.toUpperCase() == 'GET') {
          if (_pinCode != pin && _token != token) {
            return Response.forbidden(
                AbsAppHandler.buildResponseBody({'path': request.url.path},
                    message: 'auth failed', code: 403),
                headers: AbsAppHandler.headers());
          }
        } else if (_pinCode != pin) {
          return Response.forbidden(
              AbsAppHandler.buildResponseBody({'path': request.url.path},
                  message: 'auth failed', code: 403),
              headers: AbsAppHandler.headers());
        }
      }
      //verify success
      return innerHandler(request);
    };
  };
}
