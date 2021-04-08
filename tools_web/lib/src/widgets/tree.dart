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

import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:k_debug_tools_web/src/theme.dart';
import 'package:k_debug_tools_web/src/ui/theme.dart';
import 'common_widgets.dart';

extension TreeColorScheme on ColorScheme {
  Color get selectedRowBackgroundColor => isLight
      ? const Color.fromARGB(255, 202, 191, 69)
      : const Color.fromARGB(255, 99, 101, 103);
}

class Node<T> {
  ///唯一id
  String key;
  String label;
  IconData icon;
  bool expandable = false;
  bool expanded = false;
  bool selected = false;
  List<Node> subs;
  T data;
}

class _Item {
  int dep;
  Node node;

  _Item(this.dep, this.node);
}

class TreeView extends StatelessWidget {
  final Node root;
  final List<_Item> items = <_Item>[];
  final Function(Node) onExpand;
  final Function(Node) onTap;
  final Function(Node) onDoubleTap;
  final bool showRoot;

  TreeView(
      {Key key,
      @required this.root,
      this.onExpand,
      this.onTap,
      this.onDoubleTap,
      this.showRoot = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    items.clear();
    _buildList(root, 0, !showRoot);

    List<Widget> rows = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      rows.add(_buildListWidgetItem(theme, i, items[i]));
    }
    //实现上下、左右的滚动
    return LayoutBuilder(builder: (_, constraints) {
      return Container(
        alignment: Alignment.topLeft,
        child: Scrollbar(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: rows,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildListWidgetItem(ThemeData theme, int index, _Item item) {
    bool isSelected = item.node.selected ?? false;

    return DefaultTextStyle(
      style: theme.textTheme.bodyText2,
      child: ListRow(
        childPadding: EdgeInsets.only(right: 8),
        children: <Widget>[
          Container(
            color: Colors.white,
            child: SizedBox(
              width: 20.0 * item.dep,
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              debugPrint(
                  'onExpand key:${item.node.key}, expanded:${item.node.expanded}');
              if (item.node.expandable && onExpand != null) {
                onExpand(item.node);
              }
            },
            child: item.node.expandable
                ? Container(
                    child: item.node.expanded
                        ? Icon(
                            Icons.expand_more,
                            size: defaultIconSize,
                          )
                        : RotatedBox(
                            quarterTurns: 3,
                            child: Icon(
                              Icons.expand_more,
                              size: defaultIconSize,
                            ),
                          ),
                  )
                : SizedBox(width: defaultIconSize),
          ),
          GestureDetector(
              onTap: () {
                debugPrint('onTap key:${item.node.key}');
                if (onTap != null) {
                  onTap(item.node);
                }
              },
              onDoubleTap: () {
                debugPrint('onDoubleTap key:${item.node.key}');
                if (onDoubleTap != null) {
                  onDoubleTap(item.node);
                }
              },
              child: Container(
                  constraints: BoxConstraints(minHeight: 25),
                  padding:
                      EdgeInsets.only(left: densePadding, right: densePadding),
                  color: isSelected
                      ? theme.colorScheme.selectedRowBackgroundColor
                      : Colors.transparent,
                  child: Row(
                    children: [
                      Visibility(
                        visible: item.node.icon != null,
                        child: Icon(item.node.icon, size: defaultIconSize),
                      ),
                      Padding(
                          padding: EdgeInsets.only(left: densePadding),
                          child: Text(item.node.label))
                    ],
                  ))),
        ],
      ),
    );
  }

  ///将树转为列表
  void _buildList(Node n, int dep, bool ignoreThis) {
    if (n == null) {
      return null;
    }
    if (!ignoreThis) {
      items.add(_Item(dep, n));
    }
    if (n.expanded || ignoreThis) {
      n.subs?.forEach((element) {
        _buildList(element, ignoreThis ? dep : dep + 1, false);
      });
    }
  }
}
