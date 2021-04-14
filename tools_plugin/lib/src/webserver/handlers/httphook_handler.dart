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
import 'package:k_debug_tools/src/http/httphook/config_models.dart';
import 'package:k_debug_tools/src/http/httphook/http_hook_controller.dart';
import 'package:k_debug_tools/src/http/httphook/http_throttle_controller.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart' as shelf;

import '../handler_def.dart';

class HttpHookHandler extends AbsAppHandler {
  @override
  shelf.Router get router {
    final router = shelf.Router();

    router.post('/toggle', _toggle);
    router.post('/throttle', _throttle);
    router.get('/state', _state);
    router.get('/history', _history);
    router.post('/clear', _clear);
    //>>>>>>>>>config>>>>>>>>>
    //list
    router.get('/config/list', _list);
    //delete
    router.post('/config/delete', _delete);
    //update
    router.post('/config/update', _update);
    //add
    router.post('/config/add', _add);

    router.all('/<ignored|.*>', (Request request) => notFound());

    return router;
  }

  ///切换开关
  Future<Response> _toggle(Request request) async {
    Map body = jsonDecode(await request.readAsString());
    bool enable = body['enable'];
    debugPrint('set HttpHook to $enable');
    HttpHookController.instance.setEnable(enable);
    return ok(null);
  }

  ///清空历史
  Future<Response> _clear(Request request) async {
    debugPrint('clear archives');
    HttpHookController.instance.clearArchive();
    return ok(null);
  }

  ///读取历史记录
  Future<Response> _history(Request request) async {
    Map<String, Object> data = Map<String, Object>();
    data['list'] = HttpHookController.instance.httpArchives;
    return ok(data);
  }

  ///限速配置
  Future<Response> _throttle(Request request) async {
    Map? body = jsonDecode(await request.readAsString());
    ThrottleConfig config =
        ThrottleConfig.fromJson(body as Map<String, dynamic>?)!;
    HttpThrottleController.instance
        .setLimitDownload(config.limitDown, config.downKb);
    HttpThrottleController.instance.setLimitUpload(config.limitUp, config.upKb);
    return ok(null);
  }

  ///读取状态
  Future<Response> _state(Request request) async {
    Map<String, Object> data = Map<String, Object>();
    data['enable'] = HttpHookController.instance.enableHook.value;
    data['throttle'] = HttpThrottleController.instance.throttleConfig;
    data['configLength'] = HttpHookController.instance.hookConfigs.length;
    return ok(data);
  }

  Future<Response> _list(Request request) async {
    Map<String, Object> data = Map<String, Object>();
    data['config'] = HttpHookController.instance.hookConfigs;
    return ok(data);
  }

  Future<Response> _delete(Request request) async {
    Map? body = jsonDecode(await request.readAsString());
    HookConfig config = HookConfig.fromJson(body as Map<String, dynamic>?)!;
    int rows = await HttpHookController.instance.delete(config.id);
    return ok(rows);
  }

  Future<Response> _update(Request request) async {
    Map? body = jsonDecode(await request.readAsString());
    HookConfig config = HookConfig.fromJson(body as Map<String, dynamic>?)!;
    int rows = await HttpHookController.instance.update(config);
    return ok(rows);
  }

  Future<Response> _add(Request request) async {
    Map? body = jsonDecode(await request.readAsString());
    HookConfig? config = HookConfig.fromJson(body as Map<String, dynamic>?);
    int id = await HttpHookController.instance.add(config);
    return ok(id);
  }
}
