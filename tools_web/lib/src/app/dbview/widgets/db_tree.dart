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

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:k_debug_tools_web/src/widgets/tree.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../app_window_bloc.dart';
import '../../../bloc_provider.dart';
import '../../../event_bus.dart';
import '../db_events.dart';
import '../db_view_bloc.dart';
import '../db_view_models.dart';

///数据库树形结构
class DbTreeWidget extends StatefulWidget {
  @override
  _DbTreeWidgetState createState() => _DbTreeWidgetState();
}

class _DbTreeWidgetState extends State<DbTreeWidget> {
  DbViewBloc _dbViewBloc;
  AppWindowBloc _windowBloc;
  Map<String, Node> _allNodes = Map<String, Node>();
  Node _root;
  Node _selectedNode;

  @override
  void initState() {
    _windowBloc = BlocProvider.of<AppWindowBloc>(context).first;
    _dbViewBloc = BlocProvider.of<DbViewBloc>(context).first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: _dbViewBloc.stateStream,
        builder: (ctx, _) {
          return TreeView(
            root: _buildRoot(),
            showRoot: false,
            onTap: (n) {
              _setSelect(n);
            },
            onDoubleTap: (n) {
              _setSelect(n);
              eventBus.fire(DbTreeNodeDoubleClick(n));
            },
            onExpand: (n) {
              //fetch tables
              if (n.key.endsWith('schemes')) {
                _dbViewBloc.fetchDbInfo('${n.data}').then((value) {
                  n.expanded = !n.expanded;
                  setState(() {});
                }).catchError((e) {
                  _windowBloc.toast(AppLocalizations.of(context).requestError(e));
                });
              } else {
                n.expanded = !n.expanded;
                setState(() {});
              }
            },
          );
        });
  }

  ///设置选中
  void _setSelect(Node n) {
    if (_selectedNode != n) {
      _selectedNode?.selected = false;
      _selectedNode = n;
      n.selected = true;
      String id = n.key.split('/')[1];
      _dbViewBloc.setCurrentDb(id);
      setState(() {});
    }
  }

  ///数据库文件 key为 'db/${dbFile.id}'
  void _buildDbNode(Node parent, DbFile dbFile) {
    String key = 'db/${dbFile.id}';
    Node dbNode = _allNodes[key];
    if (dbNode == null) {
      debugPrint('build dbNode ${dbFile.id}');
      dbNode = Node();
      dbNode.key = key;
      dbNode.icon = Icons.insert_drive_file;
      dbNode.label = dbFile.alias;
      dbNode.expandable = true;
      dbNode.subs = <Node>[];

      _allNodes[key] = dbNode;
      parent.subs.add(dbNode);
    }
    _buildSchemesNode(dbNode, dbFile);
  }

  ///总的表节点 key为 'db/${dbFile.id}/schemes'
  void _buildSchemesNode(Node parent, DbFile dbFile) {
    String key = 'db/${dbFile.id}/schemes';
    Node schemesNode = _allNodes[key];
    if (schemesNode == null) {
      debugPrint('build schemesNode ${dbFile.id}');
      schemesNode = Node();
      schemesNode.key = key;
      schemesNode.icon = Icons.storage;
      schemesNode.label = 'Schemes';
      schemesNode.data = dbFile.id;
      schemesNode.expandable = true;
      schemesNode.subs = List<Node>();

      _allNodes[key] = schemesNode;
      parent.subs.add(schemesNode);
    }
    _buildSchemeNodes(schemesNode, dbFile);
  }

  ///每个表节点 key为 'db/${dbFile.id}/schemes/${table}'
  void _buildSchemeNodes(Node parent, DbFile dbFile) {
    DbInfo dbInfo = _dbViewBloc.dbInfo['${dbFile.id}'];
    if (dbInfo != null) {
      dbInfo.tables.forEach((tbn) {
        String key = 'db/${dbFile.id}/schemes/$tbn';
        Node sNode = _allNodes[key];
        if (sNode == null) {
          debugPrint('build schemeNode $tbn');
          sNode = Node();
          sNode.key = key;
          sNode.icon = Icons.table_chart_sharp;
          sNode.label = tbn;
          sNode.data = tbn;
          sNode.expandable = false;
          sNode.subs = <Node>[];
          _allNodes[key] = sNode;
          parent.subs.add(sNode);
        }
      });
    }
  }

  Node _buildRoot() {
    if (_root == null) {
      debugPrint('build root');
      _root = Node();
      _root.key = 'root';
      _root.label = 'Database';
      _root.expandable = true;
      _root.expanded = true;
      _root.subs = <Node>[];
    }
    Map<String, DbFile> dbFiles = _dbViewBloc.dbFiles;
    if (dbFiles.isEmpty) {
      //清空旧数据
      debugPrint('clear nodes');
      _root.subs = <Node>[];
      _root.expanded = true;
      _allNodes.clear();
    } else {
      dbFiles.forEach((key, value) {
        //build db node
        _buildDbNode(_root, value);
      });
    }
    return _root;
  }
}
