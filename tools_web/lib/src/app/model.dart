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

class ErrorResult {
  String message;
  int respCode;
  String respMessage;

  ErrorResult.create(String msg, Map respMap) {
    message = msg;
    respCode = respMap['code'];
    respMessage = respMap['message'];
  }

  @override
  String toString() {
    return '$message: $respCode#$respMessage';
  }
}

class BaseKeyValue {
  String key;
  String value;

  BaseKeyValue(this.key, this.value);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = Map<String, dynamic>();
    result['key'] = key;
    result['value'] = value;
    return result;
  }

  BaseKeyValue.fromMap(Map map) {
    key = map['key'];
    value = map['value'];
  }
}
