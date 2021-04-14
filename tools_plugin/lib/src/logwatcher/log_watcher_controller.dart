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

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:k_debug_tools/src/webserver/handlers/ws_handler.dart';

import 'log_models.dart';

///日志显示
class LogWatcherController {
  LogWatcherController._privateConstructor();

  static final LogWatcherController instance =
      LogWatcherController._privateConstructor();

  DebugPrintCallback? _originalDebugPrint;

  ///默认不打开
  bool? _enable = false;

  bool? get enable => _enable;

  ///设置
  set enable(n) {
    if (_enable != n) {
      _enable = n;
      _update();
    }
  }

  void _update() {
    _updatePrint();
    _updateDebugPrint();
  }

  void _updatePrint() {}

  void _updateDebugPrint() {
    if (enable!) {
      _originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        _sendToWeb(message, wrapWidth: wrapWidth);

        //send to original
        if (_originalDebugPrint != null) {
          _originalDebugPrint!(message, wrapWidth: wrapWidth);
        }
      };
    } else {
      debugPrint = _originalDebugPrint!;
      _originalDebugPrint = null;
    }
  }

  void _sendToWeb(String? message, {int? wrapWidth}) {
    //注意这里面不能再调用 debugPrint
    LogEntry logEntry = LogEntry();
    logEntry.level = LogLevel.debug.index;
    logEntry.msg = message;
    logEntry.time = DateTime.now().millisecondsSinceEpoch;
    WebSocketHandler.broadcastJson('logwatcher', 1, logEntry);
  }

  ///会发送给web 并且本地debugPrint
  void customDebugPrint(String message) {
    if (enable!) {
      _sendToWeb(message);
      //send to original
      if (_originalDebugPrint != null) {
        _originalDebugPrint!(message);
      }
    } else {
      debugPrint(message);
    }
  }
}
