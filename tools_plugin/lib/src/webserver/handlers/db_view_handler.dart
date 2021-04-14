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
import 'package:k_debug_tools/src/dbview/db_view_controller.dart';
import 'package:k_debug_tools/src/dbview/db_view_models.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart' as shelf;

import '../handler_def.dart';

class DbViewHandler extends AbsAppHandler {
  @override
  shelf.Router get router {
    final router = shelf.Router();

    router.post('/scan', _scan);
    router.get('/list', _listFile);

    //list table/view/index
    router.get('/db/<id|[0-9]+>/info', _dbInfo);

    //execute sql
    router.post('/db/<id|[0-9]+>/execute', _dbExecute);

    //table info count/column
    router.get('/db/<id|[0-9]+>/table/<table|.*>/info', _dbTableInfo);

    //table data
    router.get('/db/<id|[0-9]+>/table/<table|.*>/data', _dbTableData);

    //delete
    router.post('/db/<id|[0-9]+>/table/<table|.*>/delete', _dbTableDelete);

    //update
    router.post('/db/<id|[0-9]+>/table/<table|.*>/update', _dbTableUpdate);

//todo
//    //insert

    router.all('/<ignored|.*>', (Request request) => notFound());

    return router;
  }

  bool _scanning = false;

  ///数据库信息查询
  Future<Response> _dbInfo(Request request, String id) async {
    DbInfo dbInfo = DbInfo();
    dbInfo.id = int.parse(id);
    dbInfo.tables = await DbViewController.instance.getDbTables(id);
    return ok(dbInfo);
  }

  ///数据库sql
  Future<Response> _dbExecute(Request request, String id) async {
    Map body = jsonDecode(await request.readAsString());
    String? sql = body['sql'];
    try {
      ExecResult? result = await DbViewController.instance.executeSql(id, sql);
      return ok(result);
    } catch (e) {
      return error(e.toString());
    }
  }

  ///扫描文件
  Future<Response> _scan(Request request) async {
    if (_scanning) {
      return error('still scanning');
    }
    _scanning = true;
    Completer<Response> completer = Completer<Response>();
    DbViewController.instance.scanDbFile().then((value) {
      _scanning = false;
      completer.complete(ok(DbViewController.instance.dbFiles));
    }).catchError((e) {
      debugPrint('$e');
      _scanning = false;
      completer.completeError(error('$e'));
    });
    return completer.future;
  }

  ///表信息查询
  Future<Response> _dbTableInfo(
      Request request, String id, String table) async {
    TableInfo? tbInfo =
        await DbViewController.instance.getDbTableInfo(id, table);
    return ok(tbInfo);
  }

  ///表数据
  Future<Response> _dbTableData(
      Request request, String id, String table) async {
    int offset = 0;
    int limit = 100;
    if (request.url.hasQuery) {
      if (request.url.queryParameters['offset']?.isNotEmpty == true) {
        offset = int.parse(request.url.queryParameters['offset']!);
      }
      if (request.url.queryParameters['limit']?.isNotEmpty == true) {
        limit = int.parse(request.url.queryParameters['limit']!);
      }
    }
    List<Map>? data = await DbViewController.instance
        .getDbTableData(id, table, offset, limit);
    return ok(data);
  }

  ///删除数据
  Future<Response> _dbTableDelete(
      Request request, String id, String table) async {
    Map body = jsonDecode(await request.readAsString());
    String? pk = body['pk'];
    List<String> keys = (body['keys'] as List).cast<String>();
    debugPrint('_dbTableDelete: delete from $table where $pk in ($keys)');
    ExecResult? result =
        await DbViewController.instance.deleteTableData(id, table, pk, keys);
    return ok(result);
  }

  ///更新数据
  Future<Response> _dbTableUpdate(
      Request request, String id, String table) async {
    Map body = jsonDecode(await request.readAsString());
    String? pk = body['pk'];
    String? pkValue = body['pkValue'];
    Map? newValues = body['newValues'];
    ExecResult? result = await DbViewController.instance
        .updateTableData(id, table, pk, pkValue, newValues);
    return ok(result);
  }

  Future<Response> _listFile(Request request) async {
    return ok(DbViewController.instance.dbFiles);
  }
}
