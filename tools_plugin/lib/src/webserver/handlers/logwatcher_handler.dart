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

import 'package:flutter/cupertino.dart';
import 'package:k_debug_tools/src/logwatcher/log_watcher_controller.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart' as shelf;

import '../handler_def.dart';

class LogWatcherHandler extends AbsAppHandler {
  @override
  shelf.Router get router {
    final router = shelf.Router();

    router.post('/toggle', _toggle);
    router.get('/state', _state);

    router.all('/<ignored|.*>', (Request request) => notFound());

    return router;
  }

  ///切换开关
  Future<Response> _toggle(Request request) async {
    Map body = jsonDecode(await request.readAsString());
    bool? enable = body['enable'];
    debugPrint('set LogWatcher to $enable');
    LogWatcherController.instance.enable = enable;
    return ok(null);
  }

  ///读取状态
  Future<Response> _state(Request request) async {
    Map<String, Object?> data = Map<String, Object?>();
    data['enable'] = LogWatcherController.instance.enable;
    return ok(data);
  }
}
