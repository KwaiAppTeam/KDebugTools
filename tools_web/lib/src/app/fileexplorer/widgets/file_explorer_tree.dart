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

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:k_debug_tools_web/src/app/fileexplorer/file_explorer_bloc.dart';
import 'package:k_debug_tools_web/src/app/fileexplorer/file_explorer_models.dart';
import 'package:k_debug_tools_web/src/widgets/tree.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../app_window_bloc.dart';
import '../../../bloc_provider.dart';

///文件夹树形结构
class FileTreeWidget extends StatefulWidget {
  @override
  _FileTreeWidgetState createState() => _FileTreeWidgetState();
}

class _FileTreeWidgetState extends State<FileTreeWidget> {
  FileExplorerBloc _fileBloc;
  AppWindowBloc _windowBloc;
  Map<String, Node> _allNodes = Map<String, Node>();
  Node _root;
  Node _selectedNode;

  @override
  void initState() {
    _windowBloc = BlocProvider.of<AppWindowBloc>(context).first;
    _fileBloc = BlocProvider.of<FileExplorerBloc>(context).first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: _fileBloc.fileStream,
        builder: (ctx, _) {
          return TreeView(
            root: _buildRootDirNode(),
            showRoot: true,
            onTap: (n) {
              _setSelect(n);
            },
            onDoubleTap: (n) {
              _setSelect(n);
            },
            onExpand: (n) {
              n.expanded = !n.expanded;
              if (n.expanded) {
                _fileBloc.loadDir(n.data).then((value) {
                  setState(() {});
                }).catchError((e) {
                  _windowBloc.toast(AppLocalizations.of(context).requestError(e));
                });
              } else {
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
      //显示文件夹
      _fileBloc.showDir(n.data);
      setState(() {});
    }
  }

  Node _buildRootDirNode() {
    FileModel rootDir = _fileBloc.rootDir;
    if (_root == null) {
      debugPrint('build root');
      _root = Node<FileModel>();
      _root.key = 'root';
      _root.label = 'Directories';
      _root.expandable = true;
      _root.expanded = true;
      _root.subs = <Node>[];
    }

    _root.data = rootDir;
    _root.expandable = _canExpand(rootDir);

    if (rootDir == null ||
        rootDir.subFiles == null ||
        rootDir.subFiles.isEmpty) {
      //清空旧数据
      debugPrint('clear nodes');
      _root.subs = <Node>[];

      _allNodes.clear();
    } else {
      //递归创建
      rootDir?.subFiles?.forEach((element) {
        if (element.isDir) {
          _buildDirNode(_root, element);
        }
      });
    }
    return _root;
  }

  ///是否可展开 已经加载过 但是没有子文件夹的时候不能展开
  bool _canExpand(FileModel dir) {
    bool ret = true;
    if (dir?.subFiles != null) {
      ret = false;
      dir?.subFiles?.forEach((element) {
        if (element.isDir) {
          ret = true;
          return;
        }
      });
    }
    return ret;
  }

  void _buildDirNode(Node parent, FileModel dir) {
    String key = dir.absolute;
    Node dirNode = _allNodes[key];
    if (dirNode == null) {
      debugPrint('build node $key');
      dirNode = Node<FileModel>();
      dirNode.key = key;
      dirNode.icon = Icons.folder;
      dirNode.label = dir.name;
      dirNode.subs = List<Node>();
      _allNodes[key] = dirNode;
      parent.subs.add(dirNode);
    }

    dirNode.data = dir;
    dirNode.expandable = _canExpand(dir);

    // build sub dir
    dir?.subFiles?.forEach((element) {
      if (element.isDir) {
        _buildDirNode(dirNode, element);
      }
    });
  }
}
