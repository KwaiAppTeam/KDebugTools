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
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert' as convert;
import 'package:flutter/widgets.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/web_bloc.dart';
import 'package:k_debug_tools_web/src/web_http.dart';

import 'shared_preferences_models.dart';

class SharedPreferencesBloc extends BlocBase {
  static const String PATH = 'api/sp';

  BuildContext context;

  ///所有数据
  final List<SpModel> _items = <SpModel>[];

  ///当前选中
  SpModel _focusedItem;

  ///编辑中
  SpModel _editingItem;

  bool get hasFocused => _focusedItem != null;

  SpModel get focusItem => _focusedItem;

  List<SpModel> get items => _items.toList();

  int get itemCount => items.length;

  SharedPreferencesBloc(this.context);

  String getHost() {
    return WebBloc.getHost();
  }

  ///是否正在编辑
  bool isEditing(SpModel model) {
    return _editingItem == model;
  }

  ///是否聚焦
  bool isFocused(SpModel model) {
    return _focusedItem == model;
  }

  ///设置为聚焦
  void markFocused(SpModel model) {
    _focusedItem = model;
  }

  ///设置为编辑中
  void markEditing(SpModel model) {
    _editingItem = model;
  }

  ///初始化数据
  Future<List<SpModel>> initData() {
    return _loadData();
  }

  ///请求数据
  Future<List<SpModel>> _loadData() async {
    _items.clear();
    //fetch data
    Uri uri = Uri.http(getHost(), '$PATH/list');
    var response = await httpGet(uri);
    if (response.statusCode == 200) {
      //success
      Map<String, Object> jsonResponse = convert.jsonDecode(response.body);
      List list = (jsonResponse['data'] as Map)['list'] as List;
      list.forEach((element) {
        _items.add(SpModel.fromMap(element as Map<String, Object>));
      });
      return Future.value(_items.toList());
    } else {
      return Future.error('fetch data failed');
    }
  }

  ///刷新数据
  Future reload() async {
    await _loadData();
    markFocused(null);
    markEditing(null);
    return Future.value(_items.toList());
  }

  ///添加key value
  Future commitAddingValue(String key, String value) {
    //todo type
    return _commitValue(key, value, 'String');
  }

  ///删除选中的key
  Future deleteFocused() async {
    Uri uri = Uri.http(getHost(), '$PATH/delete');
    var response = await httpPost(uri, body: {
      'key': _focusedItem?.key ?? '',
    });
    return Future.value();
  }

  ///修改选中的value
  Future commitEditingValue(String value) async {
    //check type
    return _commitValue(_editingItem?.key, value, _editingItem?.valueType);
  }

  ///提交key value
  Future _commitValue(String key, String value, String valueType) async {
    var params = {
      'key': key ?? '',
      'value': value ?? '',
      'valueType': valueType?.toString() ?? '',
    };
    Uri uri = Uri.http(getHost(), '$PATH/commit');
    var response = await httpPost(uri, body: params);
    return Future.value();
  }

  @override
  void dispose() {}
}
