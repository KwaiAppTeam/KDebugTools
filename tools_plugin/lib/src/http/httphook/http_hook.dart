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

import 'package:flutter/widgets.dart';
import 'package:k_debug_tools/src/http/httphook/http_throttle_controller.dart';

import '../http_models.dart';
import '../http_request_wrapper.dart';
import 'config_models.dart';
import 'http_hook_controller.dart';

class HttpHook {
  final String method;
  final Uri url;

  // ignore: close_sinks
  HttpClientRequest? _realRequest;

  late HttpArchive _archive;

  HookConfig? _hookConfig;

  bool hookRequestOnce = false;
  List<int>? modifiedRequestData;
  bool hookResponseOnce = false;
  List<int>? modifiedResponseData;

  ///映射请求
  bool get needMapRemote => _hookConfig?.mapRemote ?? false;

  bool get needMapLocal => _hookConfig?.mapLocal ?? false;

  ///修改请求
  bool get needModifyRequest => _hookConfig?.modifyRequest ?? false;

  ///修改响应
  bool get needModifyResponse => _hookConfig?.modifyResponse ?? false;

  HttpHook(this.method, this.url, {HttpArchive? archive}) {
    _archive = archive ?? HttpArchive();
  }

  ///读取配置是否需要映射或者修改
  Future prepareBeforeOpen() async {
    _archiveRequestBase();
    var configs = HttpHookController.instance.hookConfigs;
    for (var config in configs) {
      //检查是否匹配 todo 匹配规则需要再优化
      RegExp reg = RegExp(
          '^${config.uriPattern!.replaceAll('?', r'\?').replaceAll('*', r'[^ /]*').replaceAll(r'[^ /]*[^ /]*', r'[^ ]*')}\$');
      if (config.enable! && reg.hasMatch(url.toString())) {
        _hookConfig = config;
        break;
      }
    }
    _archive.hookConfig = _hookConfig;

    if (needModifyRequest) {
      modifiedRequestData = utf8.encode(_hookConfig!.modifyRequestBody ?? '');
    }
    if (needModifyResponse) {
      modifiedResponseData = utf8.encode(_hookConfig!.modifyResponseBody ?? '');
    }
    _archive.status = 'Connecting';
    HttpHookController.instance.sendToWeb(_archive);
    return Future.value();
  }

  ///开始写入请求数据前,请求体中没有数据时不会调用 所以没有内容的请求无法修改; 或者在beforeRequestClose时写入自定义内容
  ///需要根据情况修改header内容
  void beforeAddRequestData() {
    _archiveRequestHeadersIfNeed();
    if (needModifyRequest) {
      //需要在写入数据前修改头部长度信息
      _realRequest!.headers.contentLength = modifiedRequestData!.length;
      _archiveModifiedRequestHeaders();
    }
  }

  ///请求数据写入完成
  void beforeRequestClose() {
    _archiveRequestHeadersIfNeed();
  }

  ///记录基础信息
  void _archiveRequestBase() {
    _archive.method = method.toUpperCase();
    _archive.url = url.toString();
    _archive.start = DateTime.now().millisecondsSinceEpoch;
  }

  ///记录原请求头
  void _archiveRequestHeadersIfNeed() {
    //只记录一次
    if (_archive.requestHeaders == null) {
      _archive.requestHeaders = Map<String, List<String>>();
      _realRequest!.headers.forEach((name, values) {
        _archive.requestHeaders![name] = values.toList(growable: false);
      });
      _archive.requestContentType = _realRequest!.headers.contentType.toString();
    }
  }

  ///记录修改后的请求头
  void _archiveModifiedRequestHeaders() {}

  ///请求的done方法完成 记录响应基础信息
  void afterRequestDone(HttpClientResponse realResponse) {
    _archive.statusCode = realResponse.statusCode;
    //记录一次结束时间，后续OnDone或OnError时覆盖（有些请求在获取状态码后就不读内容了 没有OnDone或OnError）
    _archive.end = DateTime.now().millisecondsSinceEpoch;
    _archiveResponseHeadersIfNeed(realResponse);
    _archive.status = 'Waiting';
    //记录连接
    HttpConnectionInfo info = realResponse.connectionInfo!;
    _archive.responseConnectInfo = ConnectInfo()
      ..localPort = info.localPort
      ..remotePort = info.remotePort
      ..remoteAddress = info.remoteAddress.address;
    HttpHookController.instance.sendToWeb(_archive);
  }

  ///记录原响应头
  void _archiveResponseHeadersIfNeed(HttpClientResponse realResponse) {
    //只记录一次
    if (_archive.responseHeaders == null) {
      _archive.responseHeaders = Map<String, List<String>>();
      realResponse.headers.forEach((name, values) {
        _archive.responseHeaders![name] = values.toList(growable: false);
      });
      _archive.responseContentType = realResponse.headers.contentType.toString();
    }
  }

  ///是否可以记录body 不记录二进制数据
  bool _canArchiveBody(HttpHeaders headers) {
    var contentType = headers.contentType;
    //目前只记录文本(text和json), 和其他小于1m的数据
    return contentType != null &&
        (contentType.primaryType == ContentType.text.primaryType ||
            contentType.subType == ContentType.json.subType ||
            (headers.contentLength > 0 && headers.contentLength < 1000000));
  }

  ///拦截请求数据 进行记录、修改
  List<int>? hookRequestData(HttpClientRequest realRequest, List<int> allData) {
    if (_canArchiveBody(realRequest.headers)) {
      //记录原始请求体
      _archive.requestBody = Uint8List.fromList(allData);
    }
    if (needModifyRequest) {
      if (hookRequestOnce) {
        throw new StateError("Request can only hook once");
      }
      hookRequestOnce = true;
      return modifiedRequestData;
    } else {
      return allData;
    }
  }

  ///拦截响应数据  进行记录、修改
  ///一个响应只能拦截一次
  List<int>? hookResponseData(
      HttpClientResponse realResponse, List<int> allData) {
    if (_canArchiveBody(realResponse.headers)) {
      //记录原始响应内容
      _archive.responseBody = Uint8List.fromList(allData);
    }
    _archive.responseLength = allData.length;
    if (needModifyResponse) {
      if (hookResponseOnce) {
        throw new StateError("Response can only hook once");
      }
      hookResponseOnce = true;
      return modifiedResponseData;
    }
    //未修改
    return allData;
  }

  void afterResponseDone(HttpClientResponse realResponse) {
    _archive.statusCode = realResponse.statusCode;
    _archive.end = DateTime.now().millisecondsSinceEpoch;
    _archiveResponseHeadersIfNeed(realResponse);
    _archive.status = 'Complete';
    _archive.throttleConfig =
        HttpThrottleController.instance.throttleConfig.clone();
    HttpHookController.instance.sendToWeb(_archive);
  }

  void afterResponseError(HttpClientResponse realResponse, e) {
    debugPrint('hookResponseOnError $e'); //todo
  }

  ///打开请求
  Future<HttpClientRequest> open(HttpClient realClient) async {
    //check map remote or map local
    Uri requestUri = url;
    if (needMapRemote) {
      //todo 需要处理这里的url的通配符
      debugPrint(
          'map remote: ${url.toString()} >>> ${_hookConfig!.mapRemoteUrl}');
      requestUri = Uri.parse(_hookConfig!.mapRemoteUrl!);
    }
    if (needMapLocal) {
      debugPrint('map local: ${url.toString()} >>> config#${_hookConfig!.id}');
      //本地起服务进行连接
      requestUri = HttpHookController.instance.mapLocalUri(_hookConfig);
    }
    try {
      _realRequest = await realClient.openUrl(method, requestUri);
      //记录连接
      HttpConnectionInfo info = _realRequest!.connectionInfo!;
      _archive.requestConnectInfo = ConnectInfo()
        ..localPort = info.localPort
        ..remotePort = info.remotePort
        ..remoteAddress = info.remoteAddress.address;
    } catch (e) {
      print('openUrl error: $e');
      rethrow;
    }
    HttpClientRequestWrapper wrapper =
        HttpClientRequestWrapper(_realRequest, this);
    return wrapper;
  }
}
