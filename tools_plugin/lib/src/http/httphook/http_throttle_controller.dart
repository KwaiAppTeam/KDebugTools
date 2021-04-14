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
import 'dart:math';

import 'package:flutter/cupertino.dart';

import 'config_models.dart';

///网络限流控制
class HttpThrottleController {
  HttpThrottleController._privateConstructor();

  static final HttpThrottleController instance =
      HttpThrottleController._privateConstructor();

  final ThrottleConfig _throttleConfig = ThrottleConfig();
  final List<_Task> _downTasks = <_Task>[];
  final List<_Task> _upTasks = <_Task>[];

  ThrottleConfig get throttleConfig => _throttleConfig;

  Timer? _upTimer;

  Timer? _downTimer;

  ///统计流量
  ValueNotifier<int> totalUp = ValueNotifier(0);
  ValueNotifier<int> totalDown = ValueNotifier(0);

  void resetStatistics() {
    totalUp.value = 0;
    totalDown.value = 0;
  }

  void setLimitUpload(bool? enable, int? kbPerSec) {
    _throttleConfig.limitUp = enable;
    _throttleConfig.upKb = kbPerSec;
  }

  void setLimitDownload(bool? enable, int? kbPerSec) {
    _throttleConfig.limitDown = enable;
    _throttleConfig.downKb = kbPerSec;
  }

  Future doUpTask(Sink<List<int>?>? sink, List<int>? data) {
    _ensureUpTimer();
    Completer completer = Completer();
    if (throttleConfig.limitUp! && (throttleConfig.upKb ?? 0) > 0) {
      //add to queue
      _upTasks.add(_Task()
        ..sink = sink
        ..data = data
        ..completer = completer);
      _ensureUpTimer();
    } else {
      sink!.add(data);
      totalUp.value += data!.length;
      completer.complete();
    }
    return completer.future;
  }

  Future doDownTask(Sink<List<int>?>? sink, List<int>? data) {
    Completer completer = Completer();
    if (throttleConfig.limitDown! && (throttleConfig.downKb ?? 0) > 0) {
      //add to queue
      _downTasks.add(_Task()
        ..sink = sink
        ..data = data
        ..completer = completer);
      _ensureDownTimer();
    } else {
      sink!.add(data);
      totalDown.value += data!.length;
      completer.complete();
    }
    return completer.future;
  }

  void _ensureUpTimer() {
    if (_upTimer != null && _upTimer!.isActive) {
      return;
    }
    _upTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (_upTasks.isEmpty) {
        timer.cancel();
        return;
      }
      bool limited = throttleConfig.limitUp! && (throttleConfig.upKb ?? 0) > 0;
      int maxLen = (throttleConfig.upKb ?? 0) * 50; // *1000/20=50
      int len = _doTasks(_upTasks, limited, maxLen);
      totalUp.value += len;
    });
  }

  void _ensureDownTimer() {
    if (_downTimer != null && _downTimer!.isActive) {
      return;
    }
    _downTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (_downTasks.isEmpty) {
        timer.cancel();
        return;
      }
      bool limited =
          throttleConfig.limitDown! && (throttleConfig.downKb ?? 0) > 0;
      int maxLen = (throttleConfig.downKb ?? 0) * 50; // *1000/20=50
      int len = _doTasks(_downTasks, limited, maxLen);
      totalDown.value += len;
    });
  }

  ///返回总共写入了多少数据
  int _doTasks(List<_Task> queue, bool limited, int limitLength) {
    int remain = limitLength;
    int writeLen = 0;
    while (!limited || remain > 0) {
      if (queue.isNotEmpty) {
        _Task firstTask = queue.first;
        if (firstTask.data!.length <= firstTask.idx) {
          //done 移除完成任务
          queue.removeAt(0);
          firstTask.completer.complete();
        } else if (!limited) {
          //未限速 全部写入
          firstTask.sink!.add(
              firstTask.data!.sublist(firstTask.idx, firstTask.data!.length));
          firstTask.idx = firstTask.data!.length;
          writeLen += firstTask.data!.length - firstTask.idx;
        } else {
          //限速 写入可用长度数据
          int len = min(remain, firstTask.data!.length - firstTask.idx);
          remain -= len;
          firstTask.sink!
              .add(firstTask.data!.sublist(firstTask.idx, firstTask.idx + len));
//          debugPrint(
//              'write data>>>>>> [${firstTask.idx},${firstTask.idx + len}] / ${queue.length}');
          firstTask.idx += len;
          writeLen += len;
        }
      } else {
        break;
      }
    }
    return writeLen;
  }
}

class _Task {
  int idx = 0;
  late Completer completer;
  List<int>? data;

  // ignore: close_sinks
  Sink<List<int>?>? sink;
}
