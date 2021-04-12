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
import 'package:flutter/material.dart';
import 'package:k_debug_tools_web/src/app/httphook/http_hook_bloc.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/widgets/tree.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

///请求域名树
class DomainTreeWidget extends StatefulWidget {
  @override
  _DomainTreeWidgetState createState() =>
      _DomainTreeWidgetState();
}

class _DomainTreeWidgetState
    extends State<DomainTreeWidget> {
  HttpHookBloc _httpHookBloc;
  Map<String, Node> _allNodes = Map<String, Node>();
  Node _root;
  Node _selectedNode;

  @override
  void initState() {
    _httpHookBloc = BlocProvider.of<HttpHookBloc>(context).first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TreeView(
      root: _buildRoot(),
      onTap: (n) {
        if (_selectedNode != n) {
          _selectedNode?.selected = false;
          _selectedNode = n;
          n.selected = true;
          _httpHookBloc.applyUriFilter(n.key);
          setState(() {});
        }
      },
      onExpand: (n) {
        n.expanded = !n.expanded;
        setState(() {});
      },
    );
  }

  Node _buildRoot() {
    if (_root == null) {
      _root = Node();
      _root.key = '';
      _root.label = AppLocalizations.of(context).allHost;
      _root.expandable = true;
      _root.subs = <Node>[];
    }
    if (_httpHookBloc.httpArchiveList.isEmpty) {
      //清空旧数据
      _root.subs = <Node>[];
      _root.expanded = true;
      _allNodes.clear();
    } else {
      _httpHookBloc.httpArchiveList.forEach((element) {
        List<String> sep = element.uri.toString().split('/');
        String domain = sep.length > 3 ? sep.sublist(0, 3).join('/') : '';
        String path = element.uri.path;
        String domainPath = domain + path;
        //加上一级节点 域名
        if (_allNodes[domain] == null) {
          Node domainNode = Node();
          _allNodes[domain] = domainNode;
          _root.subs.add(domainNode);

          domainNode.key = domain;
          domainNode.label = domain;
          domainNode.expandable = true;
          domainNode.subs = List<Node>();
        }
        //加上二级节点 path
        if (_allNodes[domainPath] == null) {
          Node pathNode = Node();
          _allNodes[domainPath] = pathNode;
          _allNodes[domain].subs.add(pathNode);

          pathNode.key = domainPath;
          pathNode.label = path;
          pathNode.expandable = false;
        }
      });
    }
    return _root;
  }
}
