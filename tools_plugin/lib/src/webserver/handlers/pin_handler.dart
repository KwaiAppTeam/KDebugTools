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

import 'package:k_debug_tools/src/webserver/web_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart' as shelf;

import '../handler_def.dart';

class PinHandler extends AbsAppHandler {
  @override
  shelf.Router get router {
    final router = shelf.Router();
    router.post('/check', _check);
    router.all('/<ignored|.*>', (Request request) => notFound());
    return router;
  }

  Future<Response> _check(Request request) async {
    Map body = jsonDecode(await request.readAsString());
    String? pin = body['pin'];
    if (pin == WebServer.instance.pin) {
      return ok();
    }
    return error('PIN Error');
  }
}
