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

import 'package:flutter/cupertino.dart';
import 'package:k_debug_tools/src/dbview/db_view_models.dart';
import 'package:sqflite/sqflite.dart';

class DbController {
  String dbPath;

  ///多实例共享连接
  static Map<String, Database> _dbs = Map<String, Database>();

  Database get _db => _dbs[dbPath];

  DbController(this.dbPath);

  Future _ensureOpened() async {
    if (_db == null || !_db.isOpen) {
      debugPrint('open db: $dbPath');
      _dbs[dbPath] = await openDatabase(dbPath);
    }
  }

  ///查询所有表名
  Future<List<String>> getTables() async {
    await _ensureOpened();
    List<String> ret = List<String>();
    List<Map> dataSet = await _db.query('sqlite_master',
        columns: ['name'], where: 'type = ?', whereArgs: ['table']);
    if (dataSet.length > 0) {
      dataSet.forEach((e) {
        ret.add(e['name']);
      });
    }
    return ret;
  }

  ///统计表数据
  Future<int> getCount(String tableName) async {
    await _ensureOpened();
    List<Map> dataSet =
        await _db.rawQuery('select count(1) as c from $tableName');
    if (dataSet.length > 0) {
      return dataSet.first['c'];
    }
    return 0;
  }

  ///表的列信息
  Future<List<TableColumn>> getTableColumns(String tableName,
      {String columnName}) async {
    await _ensureOpened();
    List<TableColumn> ret = List<TableColumn>();
    List<Map> dataSet = await _db.rawQuery('PRAGMA table_info($tableName)');
    if (dataSet.length > 0) {
      dataSet.forEach((e) {
        if (columnName == null || columnName == e["name"]) {
          ret.add(TableColumn.fromJson(e));
        }
      });
    }
    return ret;
  }

  ///表数据
  Future<List<Map>> getTableData(
      String tableName, int offset, int limit) async {
    await _ensureOpened();
    List<Map> dataSet = await _db
        .rawQuery('select * from $tableName limit ?,?', [offset, limit]);
    return dataSet;
  }

  ///执行sql
  Future<void> execute(String sql) async {
    await _ensureOpened();
    return _db.execute(sql);
  }

  ///执行sql insert
  Future<int> executeRawInsert(String insertSql) async {
    await _ensureOpened();
    return _db.rawInsert(insertSql);
  }

  ///执行sql delete
  Future<int> executeRawDelete(String deleteSql) async {
    await _ensureOpened();
    return _db.rawDelete(deleteSql);
  }

  ///执行delete
  Future<int> executeDelete(
      String table, String where, List whereArguments) async {
    await _ensureOpened();
    return _db.delete(table, where: where, whereArgs: whereArguments);
  }

  ///执行sql update
  Future<int> executeRawUpdate(String updateSql) async {
    await _ensureOpened();
    return _db.rawUpdate(updateSql);
  }

  ///执行update
  Future<int> executeUpdate(
      String table, Map values, String where, List whereArguments) async {
    await _ensureOpened();
    return _db.update(table, values, where: where, whereArgs: whereArguments);
  }

  ///执行sql select
  Future<List<Map>> executeRawSelect(String selectSql) async {
    await _ensureOpened();
    List<Map> dataSet = await _db.rawQuery(selectSql);
    return dataSet;
  }

  Future close() async {
    return _db?.close();
  }
}
