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
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';

import 'httphook/config_models.dart';

///http包数据 app和web两端对应
class HttpArchive {
  String uuid = Uuid().v4();
  String status; //Connecting/Waiting/Failed/Complete
  String method;
  String url;

  Uri get uri => url != null ? Uri.parse(url) : null;

  ///开始时间
  int start;

  ///结束时间
  int end;

  ///http statusCode
  int statusCode;

  int responseLength;

  Map<String, List<String>> requestHeaders;
  Uint8List requestBody;

  Map<String, List<String>> responseHeaders;
  Uint8List responseBody;

  ///hook配置
  HookConfig hookConfig;
  ThrottleConfig throttleConfig;

  ConnectInfo requestConnectInfo;
  ConnectInfo responseConnectInfo;

  @override
  String toString() {
    return 'HttpArchive${toJson()}';
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = Map<String, dynamic>();
    result['uuid'] = uuid;
    result['status'] = status;
    result['method'] = method;
    result['url'] = url;
    result['start'] = start;
    result['end'] = end;
    result['statusCode'] = statusCode;
    result['responseLength'] = responseLength;

    result['requestHeaders'] = requestHeaders;
    result['requestBody'] = decodeBody(requestBody);

    result['responseHeaders'] = responseHeaders;
    result['responseBody'] = decodeBody(responseBody);

    result['hookConfig'] = hookConfig;
    result['throttleConfig'] = throttleConfig;
    result['requestConnectInfo'] = requestConnectInfo;
    result['responseConnectInfo'] = responseConnectInfo;

    return result;
  }

  static HttpArchive fromJson(Map<String, dynamic> map) {
    if (map == null) {
      return null;
    }
    HttpArchive archive = HttpArchive();
    archive.uuid = map['uuid'];
    archive.status = map['status'];
    archive.method = map['method'];
    archive.url = map['url'];

    archive.start = map['start'];
    archive.end = map['end'];
    archive.statusCode = map['statusCode'];
    archive.responseLength = map['responseLength'];
    archive.requestHeaders = convertHeadersMap(map['requestHeaders']);
    archive.requestBody = utf8.encode(map['requestBody'] ?? '');

    archive.responseHeaders = convertHeadersMap(map['responseHeaders']);
    archive.responseBody = utf8.encode(map['responseBody'] ?? '');

    archive.hookConfig = map['hookConfig'] != null
        ? HookConfig.fromJson(map['hookConfig'])
        : null;
    archive.throttleConfig = map['throttleConfig'] != null
        ? ThrottleConfig.fromJson(map['throttleConfig'])
        : null;

    archive.requestConnectInfo = map['requestConnectInfo'] != null
        ? ConnectInfo.fromJson(map['requestConnectInfo'])
        : null;

    archive.responseConnectInfo = map['responseConnectInfo'] != null
        ? ConnectInfo.fromJson(map['responseConnectInfo'])
        : null;
    return archive;
  }

  static Map<String, List<String>> convertHeadersMap(Object map) {
    if (map == null) {
      return null;
    }
    return (map as Map<String, dynamic>)
        .map((key, value) => MapEntry(key, (value as List).cast<String>()));
  }

  static String decodeBody(Uint8List body) {
    if (body == null) return null;
    try {
      return utf8.decode(body);
    } catch (e) {
      debugPrint('Encode body failed. $e');
      return null;
    }
  }
}

class ConnectInfo {
  int remotePort;
  int localPort;
  String remoteAddress;

  @override
  String toString() {
    return 'ConnectInfo${toJson()}';
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = Map<String, dynamic>();
    result['remotePort'] = remotePort;
    result['localPort'] = localPort;
    result['remoteAddress'] = remoteAddress;
    return result;
  }

  static ConnectInfo fromJson(Map<String, dynamic> map) {
    if (map == null) {
      return null;
    }
    ConnectInfo info = ConnectInfo();
    info.remotePort = map['remotePort'];
    info.localPort = map['localPort'];
    info.remoteAddress = map['remoteAddress'];

    return info;
  }
}
