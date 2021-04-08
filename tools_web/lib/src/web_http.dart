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

import 'package:http/http.dart' as http;

String _pinCode = '';

String getPin() => _pinCode ?? '';

void setPin(pin) => _pinCode = pin;

String _token = '';

String getToken() => _token ?? '';

void setToken(tk) => _token = tk;

Future<http.Response> httpPost(url,
    {Map<String, String> headers, body, Encoding encoding}) {
  headers ??= Map<String, String>();
  headers = _addPin(headers);
  if (!(body is List) && !(body is String)) {
    body = jsonEncode(body);
    headers['Content-Type'] = 'application/json; charset=utf-8';
  }
  return http.post(url, headers: headers, body: body, encoding: encoding);
}

Future<http.Response> httpGet(url,
    {Map<String, String> headers, body, Encoding encoding}) {
  headers = _addPin(headers);
  return http.get(url, headers: headers);
}

Map<String, String> _addPin(Map<String, String> headers) {
  if (_pinCode?.isNotEmpty ?? false) {
    headers ??= Map<String, String>();
    headers['Pin'] = _pinCode;
  }
  return headers;
}
