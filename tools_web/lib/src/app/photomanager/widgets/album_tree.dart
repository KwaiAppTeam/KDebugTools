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
import 'package:k_debug_tools_web/src/app/photomanager/photo_models.dart';
import 'package:k_debug_tools_web/src/widgets/tree.dart';

import '../../../app_window_bloc.dart';
import '../../../bloc_provider.dart';
import '../photo_manager_bloc.dart';

///文件夹树形结构
class AlbumTreeWidget extends StatefulWidget {
  @override
  _AlbumTreeWidgetState createState() => _AlbumTreeWidgetState();
}

class _AlbumTreeWidgetState extends State<AlbumTreeWidget> {
  PhotoManagerBloc _photoBloc;
  Node _root;
  Node _selectedNode;

  @override
  void initState() {
    _photoBloc = BlocProvider.of<PhotoManagerBloc>(context).first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: _photoBloc.photoStream,
        builder: (ctx, _) {
          _buildRootNode();
          return TreeView(
            root: _root,
            showRoot: true,
            onTap: (n) {
              _setSelect(n);
            },
            onDoubleTap: (n) {
              _setSelect(n);
            },
            onExpand: (n) {
              n.expanded = !n.expanded;
              setState(() {});
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
      //显示相册
      _photoBloc.showAlbum(n.data);
      setState(() {});
    }
  }

  Node _buildRootNode() {
    if (_root == null) {
      _root = Node<Album>();
      _root.key = 'root';
      _root.label = 'Albums';
      _root.expandable = true;
      _root.expanded = true;
    }
    _root.expandable = _photoBloc.albums.isNotEmpty;
    //清空旧数据
    _root.subs = <Node>[];
    //创建
    _photoBloc.albums.forEach((element) {
      _buildAlbumNode(element);
    });
    return _root;
  }

  void _buildAlbumNode(Album album) {
    String key = album.id;
    Node node = Node<Album>();
    node.key = key;
    node.icon = Icons.folder;
    node.label = '[${album.assetCount}] ${album.name}';
    node.data = album;
    node.expandable = false;
    node.selected = _photoBloc.showingAlbum == album;
    _root.subs.add(node);
  }
}
