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

///数据库文件
class DbFile {
  ///用path的hashcode作为id 后面操作需要使用
  int id;
  String alias;
  String path;

  DbFile({this.id, this.alias, this.path});

  DbFile.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    alias = json['alias'];
    path = json['path'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['alias'] = this.alias;
    data['path'] = this.path;
    return data;
  }
}

///数据库信息
class DbInfo {
  int id;
  List<String> tables;

  DbInfo({this.id, this.tables});

  DbInfo.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    tables = json['tables'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['tables'] = this.tables;
    return data;
  }
}

///列信息
class TableColumn {
  TableColumn({
    this.cid,
    this.name,
    this.type,
    this.notnull,
    this.pk,
  });

  int cid;
  String name;
  String type;
  int notnull;
  int pk;

  factory TableColumn.fromJson(Map<String, dynamic> json) => TableColumn(
        cid: json["cid"],
        name: json["name"],
        type: json["type"],
        notnull: json["notnull"],
        pk: json["pk"],
      );

  Map<String, dynamic> toJson() => {
        "cid": cid,
        "name": name,
        "type": type,
        "notnull": notnull,
        "pk": pk,
      };
}

///表信息
class TableInfo {
  TableInfo({
    this.name,
    this.dbId,
    this.columns,
    this.count,
  });

  String name;
  String dbId;
  List<TableColumn> columns;
  int count;

  factory TableInfo.fromJson(Map<String, dynamic> json) => TableInfo(
    name: json["name"],
    dbId: json["dbId"],
    columns: List<TableColumn>.from(json["columns"].map((x) => TableColumn.fromJson(x))),
    count: json["count"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "dbId": dbId,
    "columns": List<dynamic>.from(columns.map((x) => x.toJson())),
    "count": count,
  };
}

///sql执行结果
class ExecResult {
  ExecResult({
    this.sqlResult,
    this.dataResult,
  });

  List<SqlMessage> sqlResult;
  List<List<Map>> dataResult;

  factory ExecResult.fromJson(Map<String, dynamic> json) => ExecResult(
    sqlResult: List<SqlMessage>.from(
        json["sqlResult"].map((x) => SqlMessage.fromJson(x))),
    dataResult: List<List<Map>>.from(
        json["dataResult"].map((x) => List<Map>.from(x))),
  );

  Map<String, dynamic> toJson() => {
    "sqlResult": List<dynamic>.from(sqlResult.map((x) => x.toJson())),
    "dataResult": List<dynamic>.from(
        dataResult.map((x) => List<dynamic>.from(x.map((x) => x)))),
  };
}

///sql执行信息
class SqlMessage {
  SqlMessage({
    this.sql,
    this.message,
  });

  String sql;
  String message;

  factory SqlMessage.fromJson(Map<String, dynamic> json) => SqlMessage(
    sql: json["sql"],
    message: json["message"],
  );

  Map<String, dynamic> toJson() => {
    "sql": sql,
    "message": message,
  };
}
