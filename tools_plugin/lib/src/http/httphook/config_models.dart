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

class ConfigRecord {
  int? id;
  String? data;

  ConfigRecord.fromMap(Map map) {
    id = map['id'];
    data = map['data'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = Map<String, dynamic>();
    result['id'] = id;
    result['data'] = data;
    return result;
  }
}

class HookConfig {
  int? id;

  ///配置是否启用
  bool? enable = false;

  String? uriPattern;

  ///修改请求 之后会向服务器发出请求
  bool? modifyRequest = false;
  String? modifyRequestBody;

  ///修改响应 会实际发出请求并收到响应后进行修改内容
  bool? modifyResponse = false;
  String? modifyResponseBody;

  ///映射请求 之后会向映射地址发出请求
  bool? mapRemote = false;

  ///映射地址
  String? mapRemoteUrl;

  ///映射请求到内容 之后会使用内容进行返回
  bool? mapLocal = false;

  ///映射内容
  String? mapLocalBody;

  static HookConfig fromRecord(ConfigRecord element) {
    HookConfig config = fromJson(jsonDecode(element.data!))!;
    config.id = element.id;
    return config;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = Map<String, dynamic>();
    result['id'] = id;
    result['enable'] = enable;
    result['uriPattern'] = uriPattern;

    result['modifyRequest'] = modifyRequest;
    result['modifyRequestBody'] = modifyRequestBody;

    result['modifyResponse'] = modifyResponse;
    result['modifyResponseBody'] = modifyResponseBody;

    result['mapRemote'] = mapRemote;
    result['mapRemoteUrl'] = mapRemoteUrl;

    result['mapLocal'] = mapLocal;
    result['mapLocalBody'] = mapLocalBody;
    return result;
  }

  static HookConfig? fromJson(Map<String, dynamic>? result) {
    if (result == null) {
      return null;
    }
    HookConfig config = HookConfig();

    config.id = result['id'];
    config.enable = result['enable'];
    config.uriPattern = result['uriPattern'];

    config.modifyRequest = result['modifyRequest'];
    config.modifyRequestBody = result['modifyRequestBody'];

    config.modifyResponse = result['modifyResponse'];
    config.modifyResponseBody = result['modifyResponseBody'];

    config.mapRemote = result['mapRemote'];
    config.mapRemoteUrl = result['mapRemoteUrl'];

    config.mapLocal = result['mapLocal'];
    config.mapLocalBody = result['mapLocalBody'];

    return config;
  }
}

///限流配置
class ThrottleConfig {
  bool? limitUp = false;
  bool? limitDown = false;

  int? upKb = 50;
  int? downKb = 50;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = Map<String, dynamic>();
    result['limitUp'] = limitUp;
    result['limitDown'] = limitDown;
    result['upKb'] = upKb;
    result['downKb'] = downKb;
    return result;
  }

  static ThrottleConfig? fromJson(Map<String, dynamic>? result) {
    if (result == null) {
      return null;
    }
    ThrottleConfig config = ThrottleConfig();

    config.limitUp = result['limitUp'];
    config.limitDown = result['limitDown'];
    config.upKb = result['upKb'];
    config.downKb = result['downKb'];

    return config;
  }

  ThrottleConfig? clone() {
    return fromJson(toJson());
  }
}
