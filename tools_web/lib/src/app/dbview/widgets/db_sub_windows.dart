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
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:k_debug_tools_web/src/app/dbview/db_events.dart';
import 'package:k_debug_tools_web/src/app/dbview/db_view_bloc.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/event_bus.dart';
import 'package:k_debug_tools_web/src/theme.dart';
import 'package:k_debug_tools_web/src/widgets/tree.dart';

import '../../../app_window_bloc.dart';

import '../db_view_models.dart';
import 'db_query.dart';
import 'db_table_data.dart';

class TabItem {
  Widget tab;
  Widget content;
}

///右边的多个tab窗口
class DbViewSubWindows extends StatefulWidget {
  @override
  _DbViewSubWindowsState createState() => _DbViewSubWindowsState();
}

class _DbViewSubWindowsState extends State<DbViewSubWindows> {
  final Map<String, TabItem> _tabs = Map<String, TabItem>();
  PageController _pageController;

  int _pageIndex = 0;
  DbViewBloc _dbViewBloc;
  AppWindowBloc _windowBloc;

  List<StreamSubscription> _subscriptions = <StreamSubscription>[];

  @override
  void initState() {
    _pageController =
        PageController(initialPage: this._pageIndex, keepPage: true);
    _dbViewBloc = BlocProvider.of<DbViewBloc>(context).first;
    _windowBloc = BlocProvider.of<AppWindowBloc>(context).first;
    _subscribe();
    super.initState();
  }

  void _subscribe() {
    _subscriptions.add(eventBus.on<DbTreeNodeDoubleClick>().listen((event) {
      Node n = event.node;
      if (n.key.contains('schemes/')) {
        //is table node
        if (_tabs[n.key] == null) {
          //fetch table info and show
          String dbId = n.key.split('/')[1];
          String tbn = n.key.split('/')[3];
          _dbViewBloc.fetchTableInfo(dbId, tbn).then((info) {
            _showTableTab(n.key, info);
          }).catchError((e) {
            _windowBloc.toast('$e');
          });
        } else {
          //show
          _showTableTab(n.key, null);
        }
      } else {
        //others
      }
    }));
    _subscriptions.add(eventBus.on<NewQueryClick>().listen((event) {
      _showQueryTab(event.dbFile);
    }));
  }

  @override
  void dispose() {
    _subscriptions.forEach((element) {
      element.cancel();
    });
    _subscriptions.clear();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTabBarWidget(),
        Expanded(
            child: Container(
          decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).focusColor)),
          child: PageView(
            physics: NeverScrollableScrollPhysics(),
            controller: _pageController,
            children:
                _tabs.values.map((e) => e.content).toList(growable: false),
          ),
        )),
      ],
    );
  }

  ///tab点击
  void _onTabClick(String key) {
    setState(() {
      _pageIndex = _tabs.keys.toList(growable: false).indexOf(key);
      _pageController.jumpToPage(_pageIndex);
    });
  }

  ///tabBar
  Widget _buildTabBarWidget() {
    ThemeData theme = Theme.of(context);
    var list = <Widget>[];
    var keys = _tabs.keys;
    for (int i = 0; i < keys.length; i++) {
      list.add(Container(
          color: actionBarBackgroundColor(theme),
          child: Stack(children: [
            _tabs[keys.elementAt(i)].tab,
            Positioned(
                height: 2,
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: i == _pageIndex ? theme.indicatorColor : null,
                ))
          ])));
    }
    return Container(
      height: 30,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: list,
        ),
      ),
    );
  }

  ///tabBar上的item
  Widget _buildTabBarItem(String key, String title, IconData icon) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _onTabClick(key);
      },
      child: Container(
        height: 30,
        padding: EdgeInsets.only(left: 4, right: 4),
        child: Row(
          children: [
            Icon(icon, size: defaultIconSize),
            SizedBox(
              width: densePadding,
            ),
            Text(title),
            TextButton(
              onPressed: () {
                setState(() {
                  _tabs.remove(key);
                  _pageIndex =
                      max(0, _tabs.keys.toList(growable: false).indexOf(key));
                  _pageController.jumpToPage(_pageIndex);
                });
              },
              child: Icon(Icons.close, size: defaultIconSize),
            ),
          ],
        ),
      ),
    );
  }

  ///显示表内容tab
  void _showTableTab(String key, TableInfo info) {
    if (_tabs[key] != null) {
      setState(() {
        _pageIndex = _tabs.keys.toList(growable: false).indexOf(key);
        _pageController.jumpToPage(_pageIndex);
      });
      return;
    }
    //create widget
    TabItem item = TabItem();
    _tabs[key] = item;
    item.tab = _buildTabBarItem(key, info.name, Icons.table_chart_sharp);
    item.content = DbTableDataWidget(
      key: Key(key),
      tableInfo: info,
    );
    setState(() {
      _pageIndex = _tabs.keys.toList(growable: false).indexOf(key);
      _pageController.jumpToPage(_pageIndex);
    });
  }

  ///显示新的sql tab
  void _showQueryTab(DbFile db) {
    TabItem item = TabItem();
    //每次用新的key
    String key = DateTime.now().millisecondsSinceEpoch.toString();
    _tabs[key] = item;
    item.tab = _buildTabBarItem(key, 'Query@${db.alias}', Icons.queue);
    item.content = DbQueryWidget(
      key: Key(key),
      dbFile: db,
    );
    setState(() {
      _pageIndex = _tabs.keys.toList(growable: false).indexOf(key);
      _pageController.jumpToPage(_pageIndex);
    });
  }
}
