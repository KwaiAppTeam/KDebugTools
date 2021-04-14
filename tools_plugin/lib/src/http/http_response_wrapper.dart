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
import 'dart:io';
import 'dart:typed_data';

import 'httphook/http_hook.dart';
import 'httphook/http_throttle_controller.dart';

class HttpClientResponseWrapper extends Stream<List<int>>
    implements HttpClientResponse {
  HttpClientResponse _realResponse;

  HttpHook _httpHook;

  HttpClientResponseWrapper(this._realResponse, this._httpHook);

  int get statusCode => _realResponse.statusCode;

  String get reasonPhrase => _realResponse.reasonPhrase;

  int get contentLength => _realResponse.contentLength;

  HttpClientResponseCompressionState get compressionState =>
      _realResponse.compressionState;

  bool get persistentConnection => _realResponse.persistentConnection;

  bool get isRedirect => _realResponse.isRedirect;

  List<RedirectInfo> get redirects => _realResponse.redirects;

  Future<HttpClientResponse> redirect(
      [String? method, Uri? url, bool? followLoops]) {
    return _realResponse.redirect(method, url, followLoops);
  }

  HttpHeaders get headers => _realResponse.headers;

  Future<Socket> detachSocket() {
    return _realResponse.detachSocket();
  }

  List<Cookie> get cookies => _realResponse.cookies;

  X509Certificate? get certificate => _realResponse.certificate;

  HttpConnectionInfo? get connectionInfo => _realResponse.connectionInfo;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return _realResponse.transform(_ByteTransformer(this)).listen(onData,
        onDone: () {
      if (onDone != null) {
        onDone();
      }
      _httpHook.afterResponseDone(_realResponse);
    }, onError: (e) {
      if (onError != null) {
        onError(e);
      }
      _httpHook.afterResponseError(_realResponse, e);
    }, cancelOnError: cancelOnError);
  }
}

class _ByteTransformer extends StreamTransformerBase<List<int>, List<int>>
    implements EventSink<List<int>> {
  final HttpClientResponseWrapper responseWrapper;
  Uint8List _buffer = Uint8List(0);
  EventSink<List<int>?>? _outSink;

  _ByteTransformer(this.responseWrapper);

  Stream<List<int>> bind(Stream<List<int>> stream) {
    return new Stream<List<int>>.eventTransformed(stream,
        (EventSink<List<int>?> sink) {
      if (_outSink != null) {
        throw new StateError("ByteTransformer already used");
      }
      _outSink = sink;
      return this;
    });
  }

  void add(List<int> data) {
    //先读取所有输入
    _buffer = Uint8List.fromList(_buffer + data);
  }

  void addError(error, [StackTrace? stackTrace]) {
    _outSink!.addError(error, stackTrace);
  }

  void close() async {
    //写入hook之后的数据
    List<int>? data = responseWrapper._httpHook
        .hookResponseData(responseWrapper._realResponse, _buffer.toList());
    //限流
    await HttpThrottleController.instance.doDownTask(_outSink, data);
    _outSink!.close();
  }
}
