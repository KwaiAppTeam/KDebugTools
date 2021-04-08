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
import 'package:k_debug_tools_web/src/app/pagenavigator/page_navigator_models.dart';
import 'package:k_debug_tools_web/src/widgets/tree.dart';

import '../../../bloc_provider.dart';
import '../page_navigator_bloc.dart';

///树形结构
class PageNavigatorTreeWidget extends StatefulWidget {
  @override
  _PageNavigatorTreeWidgetState createState() =>
      _PageNavigatorTreeWidgetState();
}

class _PageNavigatorTreeWidgetState extends State<PageNavigatorTreeWidget> {
  PageNavigatorBloc _navigatorBloc;
  NavigatorInfo _root;
  Node _rootNode;
  Node _selectedNode;

  @override
  void initState() {
    _navigatorBloc = BlocProvider.of<PageNavigatorBloc>(context).first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: _navigatorBloc.selectNodeStream,
        builder: (_, __) {
          if (_root != _navigatorBloc.root) {
            _root = _navigatorBloc.root;
            _rootNode = _buildRootNode();
          }
          return TreeView(
            root: _rootNode,
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
    _selectedNode?.selected = false;
    _selectedNode = n;
    n.selected = true;
    _navigatorBloc.setSelectNodeData(n.data);
  }

  Node _buildRootNode() {
    NavigatorInfo root = _navigatorBloc.root;
    debugPrint('build root');
    _rootNode = Node<NavigatorInfo>();
    _rootNode.key = 'root';
    _rootNode.label = root.name;
    _rootNode.icon = Icons.pages;
    _rootNode.expandable = true;
    _rootNode.expanded = true;
    _rootNode.subs = List<Node>();

    _rootNode.data = root;
    _rootNode.expandable = root?.routes?.isNotEmpty ?? false;

    //递归创建
    root?.routes?.forEach((element) {
      _buildRouteNode(_rootNode, element);
    });
    return _rootNode;
  }

  void _buildRouteNode(Node parent, RouteInfo route) {
    String key = route.name;
    debugPrint('build node $key');
    Node node = Node<RouteInfo>();
    node.key = key;
    node.icon = Icons.panorama_rounded;
    node.label = '${route.name}(${route.settings})';
    node.subs = List<Node>();
    node.data = route;
    node.expandable = route.childNavigators?.isNotEmpty ?? false;
    node.expanded = node.expandable;
    parent.subs.add(node);

    // build sub Navigators
    route?.childNavigators?.forEach((element) {
      _buildNavigatorNode(node, element);
    });
  }

  void _buildNavigatorNode(Node parent, NavigatorInfo info) {
    String key = info.name;
    debugPrint('build node $key');
    Node node = Node<NavigatorInfo>();
    node.key = key;
    node.icon = Icons.pages;
    node.label = info.name;
    node.subs = List<Node>();
    node.data = info;
    node.expandable = info.routes?.isNotEmpty ?? false;
    node.expanded = node.expandable;
    parent.subs.add(node);

    info?.routes?.forEach((element) {
      _buildRouteNode(node, element);
    });
  }
}
