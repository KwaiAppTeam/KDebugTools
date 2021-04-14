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

import 'package:path/path.dart';
import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';

import 'config_models.dart';

class ConfigProvider {
  static const String _DEFAULT_DB = 'KDebugTools_http_hook.db';
  static const int dbVersion = 1;

  ///表
  static const String _DEFAULT_TABLE = 'config';

  ///字段
  static const String dbFieldId = 'id';
  static const String dbFieldData = 'data';

  String dbName = _DEFAULT_DB;
  String? dbTableName = _DEFAULT_TABLE;

  ///多实例共享连接
  static Database? _db;

  ConfigProvider({this.dbTableName});

  Future _ensureOpened() async {
    if (_db == null || !_db!.isOpen) {
      var databasesPath = await getDatabasesPath();
      String dbPath = join(databasesPath, dbName);
      debugPrint('open db: $dbPath');
      _db = await openDatabase(dbPath, version: dbVersion,
          onCreate: (Database db, int version) async {
        debugPrint('create table $dbTableName');
        await db.execute('''
              create table $dbTableName ( 
                $dbFieldId integer primary key autoincrement, 
                $dbFieldData text not null,
                UNIQUE($dbFieldId)
                )
              ''');
      });
    }
  }

  ///添加
  Future<int> add(String data) async {
    await _ensureOpened();
    int id = await _db!.rawInsert('''
        INSERT  INTO $dbTableName($dbFieldData)
    VALUES('$data');
        ''');
    return id;
  }

  ///更新
  Future<int> update(int? id, String data) async {
    await _ensureOpened();
    //根据id更新
    int updateCount = await _db!.rawUpdate(
        'UPDATE $dbTableName SET $dbFieldData = ? WHERE $dbFieldId = ?',
        [data, id]);
    debugPrint('$updateCount rows updated');

    return updateCount;
  }

  ///删除
  Future<int> delete(int? id) async {
    await _ensureOpened();
    return _db!.delete(dbTableName!, where: "$dbFieldId = ?", whereArgs: [id]);
  }

  ///所有记录
  Future<List<ConfigRecord>> getAllRecord() async {
    await _ensureOpened();
    List<Map> dataSet =
        await _db!.query(dbTableName!, columns: null, whereArgs: []);
    if (dataSet.length > 0) {
      return dataSet.map((e) => ConfigRecord.fromMap(e)).toList();
    }
    return <ConfigRecord>[];
  }

  Future<ConfigRecord?> getRecord(int id) async {
    await _ensureOpened();
    List<Map> dataSet = await _db!.query(dbTableName!, where: 'id = $id');
    if (dataSet.length > 0) {
      return ConfigRecord.fromMap(dataSet.first);
    }
    return null;
  }

  Future? close() async {
    return _db?.close();
  }
}
