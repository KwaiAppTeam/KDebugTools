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
import 'package:k_debug_tools_web/src/app/httphookconfig/hook_config_models.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/web_http.dart';

import '../model.dart';

class HookConfigBloc extends AppBlocBase {
  static const String PATH = 'api/httphook/config';

  final List<HookConfig> _allConfig = List<HookConfig>();

  List<HookConfig> get configs => _allConfig;

  HookConfigBloc(context) : super(context);

  @override
  void dispose() {}

  ///加载ThrottleConfig
  Future<ThrottleConfig> loadThrottleConfig() async {
    Uri uri = Uri.http(getHost(), 'api/httphook/state');
    var response = await httpGet(uri);
    Map<String, Object> jsonResponse = jsonDecode(response.body);
    var ret = ThrottleConfig.fromJson(
        (jsonResponse['data'] as Map)['throttle'] as Map);
    return ret;
  }

  ///保存ThrottleConfig
  Future<ThrottleConfig> saveThrottleConfig(ThrottleConfig config) async {
    Uri uri = Uri.http(getHost(), 'api/httphook/throttle');
    var response = await httpPost(uri, body: config);
    if (response.statusCode == 200) {
      return Future.value();
    } else {
      return Future.error(
          ErrorResult.create('Error', jsonDecode(response.body)));
    }
  }

  ///读取所有配置
  Future<List<HookConfig>> loadConfigs() async {
    Uri uri = Uri.http(getHost(), '$PATH/list');
    var response = await httpGet(uri);
    Map<String, Object> jsonResponse = jsonDecode(response.body);
    if (response.statusCode == 200) {
      List list = (jsonResponse['data'] as Map)['config'] as List;
      _allConfig.clear();
      list.forEach((element) {
        _allConfig.add(HookConfig.fromJson(element as Map<String, Object>));
      });
      return Future.value(_allConfig);
    } else {
      return Future.error(
          ErrorResult.create('fetch data failed', jsonResponse));
    }
  }

  ///添加或更新
  Future save(HookConfig config) async {
    Uri uri =
        Uri.http(getHost(), config.id == null ? '$PATH/add' : '$PATH/update');
    var response = await httpPost(uri, body: config);
    if (response.statusCode == 200) {
      return Future.value();
    } else {
      return Future.error(
          ErrorResult.create('Error', jsonDecode(response.body)));
    }
  }

  ///删除
  Future delete(HookConfig config) async {
    Uri uri = Uri.http(getHost(), '$PATH/delete');
    var response = await httpPost(uri, body: config);
    if (response.statusCode == 200) {
      return Future.value();
    } else {
      return Future.error(
          ErrorResult.create('Error', jsonDecode(response.body)));
    }
  }
}
