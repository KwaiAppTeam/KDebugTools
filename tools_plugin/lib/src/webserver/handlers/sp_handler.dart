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

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart' as shelf;

import '../handler_def.dart';

class SharedPreferencesHandler extends AbsAppHandler {
  SharedPreferences _sharedPreferences;

  @override
  shelf.Router get router {
    SharedPreferences.getInstance().then((value) => _sharedPreferences = value);
    final router = shelf.Router();
    //list key value
    router.get('/list', _list);
    router.post('/delete', _delete);
    router.post('/commit', _commit);

    router.all('/<ignored|.*>', (Request request) => notFound());

    return router;
  }

  Future _ensureInitialized() async {
    if (_sharedPreferences == null) {
      _sharedPreferences = await SharedPreferences.getInstance();
    }
  }

  ///读取数据
  Future<Response> _list(Request request) async {
    await _ensureInitialized();
    await _sharedPreferences.reload();
    Map<String, Object> data = Map<String, Object>();
    List<Object> kvs = List<Object>();
    data['list'] = kvs;
    _sharedPreferences.getKeys().forEach((key) {
      kvs.add(buildDataModel(key: key, value: _sharedPreferences.get(key)));
    });
    return ok(data);
  }

  ///删除
  Future<Response> _delete(Request request) async {
    await _ensureInitialized();
    await _sharedPreferences.reload();
    Map body = jsonDecode(await request.readAsString());
    String key = body['key'];
    _sharedPreferences.remove(key);
    return ok();
  }

  ///新增 或 修改
  Future<Response> _commit(Request request) async {
    await _ensureInitialized();
    await _sharedPreferences.reload();
    Map body = jsonDecode(await request.readAsString());
    String key = body['key'];
    String value = body['value'];
    String valueType = body['valueType'];
    try {
      switch (valueType) {
        case 'String':
          _sharedPreferences.setString(key, value);
          break;
        case 'bool':
          _sharedPreferences.setBool(key, value?.toLowerCase() == 'true');
          break;
        case 'int':
          _sharedPreferences.setInt(key, int.parse(value));
          break;
        case 'double':
          _sharedPreferences.setDouble(key, double.parse(value));
          break;
        default:
          return error('unknown valueType');
          break;
      }
    } catch (e) {
      return error('commit error: $e');
    }
    return ok();
  }

  Object buildDataModel({String key, Object value}) {
    Map<String, Object> model = Map<String, Object>();
    model['key'] = key;
    model['value'] = value;
    model['valueType'] = value?.runtimeType?.toString();
    return model;
  }
}
