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
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/web_http.dart';

import '../model.dart';

class ClipBoardBloc extends AppBlocBase {
  static const String PATH = 'api/clipboard';
  BuildContext context;

  ClipBoardBloc(this.context) : super(context);

  ///读取设备剪切板
  Future readFromDevice() async {
    Uri uri = Uri.http(getHost(), '$PATH/read');
    var response = await httpPost(uri);
    if (response.statusCode == 200) {
      Map<String, Object> jsonResponse = jsonDecode(response.body);
      var data = (jsonResponse['data'] as Map);
      return Future.value(data['text']);
    } else {
      return Future.error(
          ErrorResult.create('Error', jsonDecode(response.body)));
    }
  }

  ///写入设备剪切板
  Future writeToDevice(String text) async {
    Uri uri = Uri.http(getHost(), '$PATH/write');
    var response = await httpPost(uri, body: {'text': text});
    if (response.statusCode == 200) {
      return Future.value();
    } else {
      return Future.error(
          ErrorResult.create('Error', jsonDecode(response.body)));
    }
  }

  @override
  void dispose() {}
}
