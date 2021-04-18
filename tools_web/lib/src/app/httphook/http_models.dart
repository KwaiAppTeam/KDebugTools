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
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:k_debug_tools_web/src/app/httphookconfig/hook_config_models.dart';
import 'package:uuid/uuid.dart';

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

  String requestContentType;
  String responseContentType;

  @override
  String toString() {
    return 'HttpArchive${toJson()}';
  }

  String get requestBodyString {
    if (requestBody == null || requestContentType == null) return null;
    try {
      if (ContentType.parse(requestContentType)
              .charset
              ?.toLowerCase()
              ?.endsWith('utf-8') ??
          true) {
        return utf8.decode(requestBody);
      } else {
        //todo process other charsets
        return latin1.decode(requestBody);
      }
    } catch (e) {
      debugPrint(
          'decode body failed. ContentType: $requestContentType, error:$e');
      return null;
    }
  }

  String get responseBodyString {
    if (responseBody == null || responseContentType == null) return null;
    try {
      if (ContentType.parse(responseContentType)
              .charset
              ?.toLowerCase()
              ?.endsWith('utf-8') ??
          true) {
        return utf8.decode(responseBody);
      } else {
        //todo process other charsets
        return latin1.decode(responseBody);
      }
    } catch (e) {
      debugPrint(
          'decode body failed. ContentType: $responseContentType, error:$e');
      return null;
    }
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
    result['requestBodyBase64'] = _bodyBase64(requestBody);
    result['requestContentType'] = requestContentType;

    result['responseHeaders'] = responseHeaders;
    result['responseBodyBase64'] = _bodyBase64(responseBody);
    result['responseContentType'] = responseContentType;

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
    archive.requestBody = map['requestBodyBase64'] != null
        ? base64Decode(map['requestBodyBase64'])
        : null;
    archive.requestContentType = map['requestContentType'];

    archive.responseHeaders = convertHeadersMap(map['responseHeaders']);
    archive.responseBody = map['responseBodyBase64'] != null
        ? base64Decode(map['responseBodyBase64'])
        : null;
    archive.responseContentType = map['responseContentType'];

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

  static String _bodyBase64(Uint8List body) {
    if (body == null) return null;
    try {
      return base64.encode(body);
    } catch (e) {
      debugPrint('encode body to base64 failed. $e');
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
