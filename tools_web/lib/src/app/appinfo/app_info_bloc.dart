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
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert' as convert;
import 'package:flutter/widgets.dart';
import 'package:k_debug_tools_web/src/app/model.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/web_http.dart';

class AppInfoBloc extends AppBlocBase {
  static const String PATH = 'api/app';

  ///全局缓存
  static Map<String, Object> _data = Map<String, Object>();

  Map<String, Object> get data => _data;

  String get appName => _data['appName'] ?? '';

  AppInfoBloc(BuildContext context) : super(context);

  ///初始化数据
  Future<Map<String, Object>> initData() async {
    if (_data.isNotEmpty) {
      return _data;
    } else {
      Uri uri = Uri.http(getHost(), '$PATH/info');
      var response = await httpGet(uri);
      Map<String, Object> jsonResponse = convert.jsonDecode(response.body);
      if (response.statusCode == 200) {
        jsonResponse = (jsonResponse['data'] as Map);
        _data.addAll(jsonResponse);
        return _data;
      } else {
        return Future.error(
            ErrorResult.create('fetch data failed', jsonResponse));
      }
    }
  }

  @override
  void dispose() {
    _data.clear();
  }
}
