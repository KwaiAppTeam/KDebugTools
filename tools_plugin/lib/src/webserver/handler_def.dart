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

import 'package:flutter/widgets.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart' as shelf;

abstract class AbsAppHandler {
  shelf.Router get router;

  static Map<String, Object> headers() {
    Map<String, Object> headers = Map<String, String>();
    //允许跨域
    headers['Access-Control-Allow-Origin'] = '*';
    headers['Access-Control-Allow-Headers'] = "Token, Pin, Content-Type";
    headers['Content-Type'] = 'application/json; charset=utf-8';
    return headers;
  }

  Response notFound({String msg}) {
    return Response.notFound(
        buildResponseBody(null, message: msg ?? 'Not Found', code: 404),
        headers: headers());
  }

  Response error(String error) {
    return Response.internalServerError(
        body: buildResponseBody(null, message: error, code: 500),
        headers: headers());
  }

  Response ok([Object data]) {
    return Response.ok(buildResponseBody(data), headers: headers());
  }

  static String buildResponseBody(Object data, {String message, int code}) {
    Map<String, Object> resp = Map<String, Object>();
    resp['data'] = data;
    resp['message'] = message ?? 'success';
    resp['code'] = code ?? 200;
    String str;
    try {
      str = jsonEncode(resp);
    } catch (e, s) {
      debugPrint('encode error, $e $s');
      throw e;
    }
    return str;
  }
}
