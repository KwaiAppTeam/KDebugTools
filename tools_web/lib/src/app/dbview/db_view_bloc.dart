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
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/widgets.dart';
import 'package:k_debug_tools_web/src/app/dbview/db_view_models.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/web_http.dart';

class DbViewBloc extends AppBlocBase {
  static const String PATH = 'api/dbview';

  int _st = 0;
  BehaviorSubject<int> _stateSub = BehaviorSubject<int>();

  Sink<int> get _stateSink => _stateSub.sink;

  Stream<int> get stateStream => _stateSub.stream;

  //id - DbFile
  final Map<String, DbFile> _dbFiles = Map<String, DbFile>();

  Map<String, DbFile> get dbFiles => _dbFiles;

  //id - DbInfo
  final Map<String, DbInfo> _dbInfo = Map<String, DbInfo>();

  Map<String, DbInfo> get dbInfo => _dbInfo;

  String _currentDbId;

  DbFile get currentDbFile => dbFiles[_currentDbId];

  DbViewBloc(context) : super(context);

  @override
  void dispose() {
    debugPrint('dispose DbViewBloc...');
    _clearCache();
    _stateSub.close();
  }

  ///db文件
  Future listFile(bool reScan) async {
    _dbFiles.clear();
    if (reScan) {
      _clearCache();
    }
    //更新状态
    setState();
    Uri uri = Uri.http(getHost(), reScan ? '$PATH/scan' : '$PATH/list');
    var response = await httpPost(uri);
    if (response.statusCode == 200) {
      Map<String, Object> jsonResponse = jsonDecode(response.body);
      _dbFiles.addEntries((jsonResponse['data'] as Map)
          .map((key, value) => MapEntry(key as String, DbFile.fromJson(value)))
          .entries);
      setState();
      return Future.value();
    } else {
      return Future.error('加载失败');
    }
  }

  ///清空缓存信息
  void _clearCache() {
    _dbInfo.clear();
    _currentDbId = null;
  }

  ///设置当前的数据库
  void setCurrentDb(String id) {
    if (id != _currentDbId) {
      _currentDbId = id;
      setState();
    }
  }

  void setState([var f]) {
    _stateSink.add(++_st);
  }

  ///查询数据库信息
  Future fetchDbInfo(String id) async {
    if (dbInfo[id] != null) {
      return dbInfo[id];
    }
    Uri uri = Uri.http(getHost(), '$PATH/db/$id/info');
    var response = await httpGet(uri);
    if (response.statusCode == 200) {
      Map<String, Object> jsonResponse = jsonDecode(response.body);
      dbInfo[id] = DbInfo.fromJson(jsonResponse['data'] as Map);
      return Future.value();
    } else {
      return Future.error('加载失败');
    }
  }

  ///数据表信息
  Future<TableInfo> fetchTableInfo(String dbId, String tableName) async {
    Uri uri = Uri.http(getHost(), '$PATH/db/$dbId/table/$tableName/info');
    var response = await httpGet(uri);
    if (response.statusCode == 200) {
      Map<String, Object> jsonResponse = jsonDecode(response.body);
      TableInfo info = TableInfo.fromJson(jsonResponse['data'] as Map);
      return info;
    } else {
      return Future.error('加载失败');
    }
  }

  ///数据表信息
  Future<List<Map>> fetchTableData(
      String dbId, String tableName, int offset, int limit) async {
    var p = {
      'offset': offset.toString(),
      'limit': limit.toString(),
    };
    Uri uri = Uri.http(getHost(), '$PATH/db/$dbId/table/$tableName/data', p);
    var response = await httpGet(uri);
    if (response.statusCode == 200) {
      Map<String, Object> jsonResponse = jsonDecode(response.body);
      return (jsonResponse['data'] as List)?.cast<Map>();
    } else {
      return Future.error('加载失败');
    }
  }

  ///执行sql
  Future<ExecResult> executeSql(String dbId, String sql) async {
    Uri uri = Uri.http(getHost(), '$PATH/db/$dbId/execute');
    var response = await httpPost(uri, body: {'sql': sql});
    if (response.statusCode == 200) {
      Map<String, Object> jsonResponse = jsonDecode(response.body);
      return ExecResult.fromJson(jsonResponse['data'] as Map);
    } else {
      return Future.error('操作失败');
    }
  }

  ///删除数据
  Future<ExecResult> deleteTableData(
      TableInfo tableInfo, List<Map> data) async {
    //找出pk
    String pk = '';
    tableInfo.columns.forEach((element) {
      if (element.pk == 1) {
        pk = element.name;
        return;
      }
    });
    if (pk.isEmpty) {
      return Future.error('NO PK');
    }
    List keys = [];
    data.forEach((element) {
      keys.add(element[pk]?.toString());
    });
    Uri uri = Uri.http(
        getHost(), '$PATH/db/${tableInfo.dbId}/table/${tableInfo.name}/delete');
    var response = await httpPost(uri, body: {
      'pk': pk,
      'keys': keys,
    });
    if (response.statusCode == 200) {
      Map<String, Object> jsonResponse = jsonDecode(response.body);
      return ExecResult.fromJson(jsonResponse['data'] as Map);
    } else {
      return Future.error('Failed: ${response.body}');
    }
  }

  ///更新数据
  Future<ExecResult> updateTableData(TableInfo tableInfo, Map originalRow,
      String columnName, String newValue) async {
    //找出pk
    String pk = '';
    String pkValue = '';
    tableInfo.columns.forEach((element) {
      if (element.pk == 1) {
        pk = element.name;
        pkValue = originalRow[pk].toString();
        return;
      }
    });
    if (pk.isEmpty) {
      return Future.error('NO PK');
    }
    //update value
    for (TableColumn column in tableInfo.columns) {
      if (column.name == columnName) {
        if (column.type.toUpperCase() == 'INTEGER') {
          try {
            originalRow[columnName] = int.parse(newValue);
          } catch (e) {
            debugPrint('update value error, $e');
            return Future.error('update value error: $newValue not INTEGER');
          }
        } else {
          originalRow[columnName] = newValue;
        }
        break;
      }
    }
    Uri uri = Uri.http(
        getHost(), '$PATH/db/${tableInfo.dbId}/table/${tableInfo.name}/update');
    var response = await httpPost(uri, body: {
      'pk': pk,
      'pkValue': pkValue,
      'newValues': originalRow,
    });
    if (response.statusCode == 200) {
      Map<String, Object> jsonResponse = jsonDecode(response.body);
      return ExecResult.fromJson(jsonResponse['data'] as Map);
    } else {
      return Future.error('Failed: ${response.body}');
    }
  }
}
