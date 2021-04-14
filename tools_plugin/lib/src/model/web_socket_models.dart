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

class WsStat {
  final bool connected;

  WsStat(this.connected);
}

///websocket的消息
class WsMessage {
  String? module;
  int? cmd;
  ContentType? type;
  Uint8List? data;

  WsMessage({this.module, this.cmd, this.type, this.data});

  static WsMessage? fromJson(Map<String, dynamic>? result) {
    if (result == null) {
      return null;
    }
    WsMessage message = WsMessage();

    message.module = result['module'];
    message.cmd = result['cmd'] ?? 0;
    message.type = ContentType.parse(result['type'] ?? '');
    if (result['data'] != null) {
      if (message.type == ContentType.binary) {
        message.data = base64Decode(result['data']);
      } else {
        message.data = utf8.encode(result['data']) as Uint8List?;
      }
    }
    return message;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = Map<String, dynamic>();
    result['module'] = module;
    result['cmd'] = cmd;

    result['type'] = type.toString();
    if (data != null) {
      if (type == ContentType.binary) {
        result['data'] = base64Encode(data!);
      } else {
        result['data'] = utf8.decode(data!);
      }
    }
    return result;
  }
}
