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
import 'package:flutter/services.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart' as shelf;

import '../handler_def.dart';

///用于读取、写入手机剪切板
class ClipBoardHandler extends AbsAppHandler {
  @override
  shelf.Router get router {
    final router = shelf.Router();
    router.post('/read', _read);
    router.post('/write', _write);
    router.all('/<ignored|.*>', (Request request) => notFound());
    return router;
  }

  Future<Response> _read(Request request) async {
    ClipboardData data = await Clipboard.getData(Clipboard.kTextPlain);
    return ok({'text': data?.text ?? ''});
  }

  Future<Response> _write(Request request) async {
    Map body = jsonDecode(await request.readAsString());
    String text = body['text'];
    await Clipboard.setData(ClipboardData(text: text));
    return ok(null);
  }
}
