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
import 'package:flutter/rendering.dart';
import 'package:k_debug_tools_web/src/app/app_register.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/common_widgets.dart';
import 'package:k_debug_tools_web/src/web_bloc.dart';

import '../theme.dart';

const double ROOT_NAVI_HEIGHT = kToolbarHeight;

class RootNaviBar extends StatefulWidget {
  RootNaviBar();

  @override
  _RootNaviBarState createState() => _RootNaviBarState();
}

class _RootNaviBarState extends State<RootNaviBar> {
  WebBloc _webBloc;

  @override
  void initState() {
    _webBloc = BlocProvider.of<WebBloc>(context).first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ROOT_NAVI_HEIGHT,
      width: double.infinity,
      child: Row(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildNaviBarItem(),
              ),
            ),
          ),
          Row(
            children: _buildQuickMenuItem(context),
          )
        ],
      ),
    );
  }

  ///导航栏appItem
  List<Widget> _buildNaviBarItem() {
    List<Widget> result = <Widget>[];
    ThemeData theme = Theme.of(context);
    _webBloc.openedApps.forEach((appItem, bloc) {
      final focused = _webBloc.focusedItem == appItem;
      final Color color = focused ? Colors.white : devtoolsGrey[50];
      if (appItem.showInNavigationBar) {
        Widget w = IconTheme(
          data: IconThemeData(color: color, size: defaultIconSize),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: color),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    padding: EdgeInsets.only(left: 10, right: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(appItem.icon),
                        Padding(
                          padding: const EdgeInsets.only(left: denseSpacing),
                          child: Text(appItem.name),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: densePadding),
                          child: Tooltip(
                            message: 'close',
                            child: TextButton(
                                onPressed: () {
                                  bloc.close();
                                },
                                child: Icon(Icons.close, color: color)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                    height: 2,
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color:
                          focused ? theme.indicatorColor : Colors.transparent,
                    ))
              ],
            ),
          ),
        );
        w = TextButton(
          onPressed: () {
            bloc.setFocus();
          },
          child: w,
        );
        result.add(w);
      }
    });
    return result;
  }

  ///右上方快捷菜单item
  List<Widget> _buildQuickMenuItem(BuildContext ctx) {
    List<Widget> result = <Widget>[];
    AppRegister.instance.quickMenuItems.forEach((app) {
      Widget item = app.quickMenuItemBuilder(ctx);
      //处理打开后的背景效果和border
      Widget w = Container(
        padding: EdgeInsets.only(left: 4, right: 4),
        decoration: BoxDecoration(
          color: _webBloc.isAppOpened(app)
              ? Colors.white.withOpacity(0.3)
              : Colors.transparent,
        ),
        child: item,
      );
      w = DevToolsTooltip(
        tooltip: app.name,
        child: TextButton(
          onPressed: () {
            //点击后打开或者关闭
            _webBloc.openOrClose(app);
          },
          child: w,
        ),
      );
      result.add(w);
    });
    return result;
  }
}
