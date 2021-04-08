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

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:k_debug_tools/src/dbview/db_controller.dart';
import 'package:k_debug_tools/src/dbview/db_view_models.dart';
import 'package:path_provider/path_provider.dart';

///数据库读写
class DbViewController {
  DbViewController._privateConstructor();

  static final DbViewController instance =
      DbViewController._privateConstructor();

  final Map<String, DbFile> _dbFileMap = Map<String, DbFile>();

  Map<String, DbFile> get dbFiles => _dbFileMap;

  ///手动注册db文件
  void registerDbFile(String filePath) {
    DbFile f = DbFile();
    f.path = filePath;
    f.id = filePath.hashCode;
    f.alias = filePath.substring(1 + filePath.lastIndexOf('/'));
    _dbFileMap['${f.id}'] = f;
  }

  ///自动扫描应用内的.db文件
  Future<List<String>> scanDbFile() async {
    //从应用内根目录开始找
    List<Directory> dirs = await _getAppDirs();
    List<String> files = [];
    dirs.forEach((dir) {
      debugPrint('scan dir: ${dir.path}');
      files.addAll(_scanDir(dir));
    });
    files.forEach((element) {
      if (_dbFileMap[element.hashCode] == null) {
        registerDbFile(element);
      }
    });
    return files;
  }

  ///递归查询.db文件
  List<String> _scanDir(Directory dir) {
    List<String> files = List<String>();
    dir.listSync().forEach((element) {
      if (element is File && element.path.toLowerCase().endsWith('.db')) {
        files.add(element.path);
      } else if (element is Directory) {
        files.addAll(_scanDir(element));
      }
    });
    return files;
  }

  ///应用根目录
  Future<List<Directory>> _getAppDirs() async {
    if (Platform.isAndroid) {
      final appDir = await getApplicationSupportDirectory();
      //app root dir
      return [
        Directory(appDir.path.substring(0, appDir.path.lastIndexOf('/')))
      ];
    } else {
      return [
        await getApplicationDocumentsDirectory(),
        await getApplicationSupportDirectory()
      ];
    }
  }

  ///执行sql
  Future<ExecResult> executeSql(String id, String sqlStr) async {
    if (_dbFileMap[id] == null) {
      return null;
    } else {
      ExecResult result = ExecResult();
      result.sqlResult = List<SqlMessage>();
      result.dataResult = List<List<Map>>();
      DbController dbController = DbController(_dbFileMap[id].path);
      List<String> sqls = sqlStr.split(';');
      for (String sql in sqls) {
        String formatSQL = sql.trim().toUpperCase();
        if (formatSQL.isEmpty) {
          continue;
        }
        debugPrint('execute SQL: $sql');
        String msg = '';
        int st = DateTime.now().millisecondsSinceEpoch;
        try {
          if (formatSQL.startsWith('INSERT')) {
            int rows = await dbController.executeRawInsert(sql);
            msg = 'Affected rows: $rows';
          } else if (formatSQL.startsWith('UPDATE')) {
            int rows = await dbController.executeRawUpdate(sql);
            msg = 'Affected rows: $rows';
          } else if (formatSQL.startsWith('DELETE')) {
            int rows = await dbController.executeRawDelete(sql);
            msg = 'Affected rows: $rows';
          } else if (formatSQL.startsWith('SELECT')) {
            List<Map> data = await dbController.executeRawSelect(sql);
            result.dataResult.add(data);
            msg = 'OK';
          } else {
            await dbController.execute(sql);
            msg = 'OK';
          }
        } catch (e) {
          msg = '$e';
        }
        int et = DateTime.now().millisecondsSinceEpoch;
        result.sqlResult
            .add(SqlMessage(sql: sql, message: '$msg, Time: ${et - st}ms'));
      }
      dbController.close();
      return result;
    }
  }

  ///查询数据库表名
  Future<List<String>> getDbTables(String id) async {
    if (_dbFileMap[id] == null) {
      return null;
    } else {
      DbController dbController = DbController(_dbFileMap[id].path);
      List<String> tables = await dbController.getTables();
      dbController.close();
      return tables;
    }
  }

  ///查询数据库表信息
  Future<TableInfo> getDbTableInfo(String dbId, String tableName) async {
    if (_dbFileMap[dbId] == null) {
      return null;
    } else {
      DbController dbController = DbController(_dbFileMap[dbId].path);
      int count = await dbController.getCount(tableName);
      List<TableColumn> columns = await dbController.getTableColumns(tableName);
      dbController.close();
      return TableInfo(
          dbId: dbId, name: tableName, count: count, columns: columns);
    }
  }

  ///查询数据库表数据
  Future<List<Map>> getDbTableData(
      String dbId, String tableName, int offset, int limit) async {
    if (_dbFileMap[dbId] == null) {
      return null;
    } else {
      DbController dbController = DbController(_dbFileMap[dbId].path);
      List<Map> data =
          await dbController.getTableData(tableName, offset, limit);
      dbController.close();
      return data;
    }
  }

  ///删除表数据
  Future<ExecResult> deleteTableData(
      String dbId, String tableName, String pk, List<String> keys) async {
    if (_dbFileMap[dbId] == null) {
      return null;
    } else {
      int st = DateTime.now().millisecondsSinceEpoch;
      DbController dbController = DbController(_dbFileMap[dbId].path);
      ExecResult result = ExecResult();
      result.sqlResult = List<SqlMessage>();
      result.dataResult = List<List<Map>>();
      int rows = await dbController.executeDelete(
          tableName, '$pk in (${keys.map((e) => '?').join(',')})', keys);
      String msg = 'Affected rows: $rows';
      int et = DateTime.now().millisecondsSinceEpoch;
      result.sqlResult
          .add(SqlMessage(sql: '', message: '$msg, Time: ${et - st}ms'));
      dbController.close();
      return result;
    }
  }

  ///更新表数据
  Future<ExecResult> updateTableData(String dbId, String tableName, String pk,
      String pkValue, Map values) async {
    if (_dbFileMap[dbId] == null) {
      return null;
    } else {
      int st = DateTime.now().millisecondsSinceEpoch;
      DbController dbController = DbController(_dbFileMap[dbId].path);
      ExecResult result = ExecResult();
      result.sqlResult = List<SqlMessage>();
      result.dataResult = List<List<Map>>();
      int rows = await dbController
          .executeUpdate(tableName, values, '$pk = ?', [pkValue]);
      String msg = 'Affected rows: $rows';
      int et = DateTime.now().millisecondsSinceEpoch;
      result.sqlResult
          .add(SqlMessage(sql: '', message: '$msg, Time: ${et - st}ms'));
      dbController.close();
      return result;
    }
  }
}
