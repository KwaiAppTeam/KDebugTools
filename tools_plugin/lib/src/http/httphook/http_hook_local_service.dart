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

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http_multi_server/http_multi_server.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'package:shelf_router/shelf_router.dart' as shelf_router;

import 'config_models.dart';
import 'config_provider.dart';

///用于maplocal的本地服务器
class HttpHookLocalService {
  HttpHookLocalService._privateConstructor();

  static final HttpHookLocalService instance =
      HttpHookLocalService._privateConstructor();

  static const int _DEFAULT_PORT = 61111;
  HttpServer? _server;

  int _usingPort = _DEFAULT_PORT;

  String get mapLocalServiceUri => 'http://localhost:$_usingPort/mapLocal';

  ConfigProvider? _hookConfigProvider;

  ///开启服务
  Future start() async {
    _hookConfigProvider ??= ConfigProvider(dbTableName: 'hook_config');
    await _server?.close(force: true);
    try {
      _usingPort = _DEFAULT_PORT;
      //找到一个可用的端口绑定 找10次
      int tryTimes = 0;
      while (tryTimes < 10) {
        try {
          _server = await HttpMultiServer.bind('localhost', _usingPort);
          break;
        } catch (e) {
          debugPrint('bind port error. $e');
          tryTimes++;
          _usingPort++;
        }
      }
      var router = shelf_router.Router();
      router.get('/mapLocal', _mapLocal);
      router.post('/mapLocal', _mapLocal);

      var handler = const shelf.Pipeline()
          .addMiddleware(shelf.logRequests())
          .addHandler(router);
      shelf_io.serveRequests(_server!, handler);
    } catch (e) {
      debugPrint('start server error. $e');
      _server = null;
      return Future.error(e);
    }
    return Future.value();
  }

  ///停止服务
  Future stop() async {
    if (_server == null) {
      return Future.value();
    }
    await _server!.close(force: true);
    _server = null;
    return Future.value();
  }


  Future<shelf.Response> _mapLocal(shelf.Request request) async {
    if (request.url.hasQuery &&
        request.url.queryParameters['id']?.isNotEmpty == true) {
      int id = int.parse(request.url.queryParameters['id']!);
      ConfigRecord? configRecord = await _hookConfigProvider!.getRecord(id);
      if (configRecord != null) {
        HookConfig config = HookConfig.fromRecord(configRecord);
        String body = config.mapLocalBody ?? '';
        Map<String, Object> headers = Map<String, String>();
        if (isJsonStr(body)) {
          headers['content-type'] = 'application/json;charset=UTF-8';
        } else {
          headers['content-type'] = 'text/plain; charset=utf-8';
        }
        return shelf.Response.ok(body, headers: headers);
      } else {
        return shelf.Response.notFound('config#$id not found');
      }
    } else {
      return shelf.Response.notFound('id required');
    }
  }

  bool isJsonStr(String data) {
    try {
      jsonDecode(data);
      return true;
    } catch (e) {
      return false;
    }
  }
}
