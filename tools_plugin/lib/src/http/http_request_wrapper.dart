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
import 'dart:io';
import 'dart:typed_data';

import 'package:k_debug_tools/src/http/httphook/http_throttle_controller.dart';

import 'http_response_wrapper.dart';
import 'httphook/http_hook.dart';

//解决1.22.4新增abort导致不兼容问题
extension _abort on HttpClientRequest {
  void abort([Object exception, StackTrace stackTrace]) {
    this.abort(exception, stackTrace);
  }
}

class HttpClientRequestWrapper extends HttpClientRequest {
  HttpClientRequest _realRequest;

  HttpHook _httpHook;

  _BodyBuffer _bodyBuffer;

  HttpClientRequestWrapper(this._realRequest, this._httpHook) {
    _bodyBuffer = _BodyBuffer();
  }

  @override
  Encoding get encoding => _realRequest.encoding;

  @override
  void abort([Object exception, StackTrace stackTrace]) {
    _realRequest.abort(exception, stackTrace);
  }

  @override
  void addError(Object error, [StackTrace stackTrace]) {
    //todo
//    debugPrint('_interceptRequest addError');
    _realRequest.addError(error, stackTrace);
  }

  @override
  void add(List<int> data) {
    _bodyBuffer.add(data);
  }

  @override
  Future addStream(Stream<List<int>> stream) {
    return _bodyBuffer.addStream(stream);
  }

  @override
  Future<HttpClientResponse> close() async {
    //写入内容
    _httpHook.beforeAddRequestData();
    List<int> data =
        _httpHook.hookRequestData(_realRequest, _bodyBuffer._buffer.toList());
    //限流
    await HttpThrottleController.instance.doUpTask(_realRequest, data);
    _bodyBuffer.close();
    _httpHook.beforeRequestClose();
    _realRequest.close();
    return done;
  }

  @override
  HttpConnectionInfo get connectionInfo => _realRequest.connectionInfo;

  @override
  List<Cookie> get cookies => _realRequest.cookies;

  @override
  Future<HttpClientResponse> get done async {
    HttpClientResponse _realResp = await _realRequest.done;
    _httpHook.afterRequestDone(_realResp);
    return HttpClientResponseWrapper(_realResp, _httpHook);
  }

  @override
  Future flush() {
    return _realRequest.flush();
  }

  @override
  HttpHeaders get headers => _realRequest.headers;

  @override
  String get method => _realRequest.method;

  @override
  Uri get uri => _realRequest.uri;

  @override
  void write(Object obj) {
    String string = '$obj';
    if (string.isEmpty) return;
    add(_realRequest.encoding.encode(string));
  }

  @override
  void writeAll(Iterable objects, [String separator = ""]) {
    Iterator iterator = objects.iterator;
    if (!iterator.moveNext()) return;
    if (separator.isEmpty) {
      do {
        write(iterator.current);
      } while (iterator.moveNext());
    } else {
      write(iterator.current);
      while (iterator.moveNext()) {
        write(separator);
        write(iterator.current);
      }
    }
  }

  @override
  void writeCharCode(int charCode) {
    write(new String.fromCharCode(charCode));
  }

  @override
  void writeln([Object object = ""]) {
    write(object);
    write("\n");
  }

  @override
  set encoding(Encoding _encoding) {
    _realRequest.encoding = _encoding;
  }
}

class _BodyBuffer implements StreamConsumer<List<int>> {
  Completer _doneCompleter;

  Uint8List _buffer = Uint8List(0);

  void add(List<int> data) {
    _buffer = Uint8List.fromList(_buffer + data);
  }

  Future addStream(Stream<List<int>> stream) {
    _doneCompleter = Completer();
    stream.listen((data) {
      if (data.length == 0) return;
      add(data);
    }, onDone: () {
      _doneCompleter.complete();
      _doneCompleter = null;
    }, onError: (e, s) {
      _doneCompleter.completeError(e, s);
      _doneCompleter = null;
    });
    return _doneCompleter.future;
  }

  Future close() {
//    _buffer.clear();
    return Future.value();
  }
}
