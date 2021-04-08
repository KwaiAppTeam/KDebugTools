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
import 'package:k_debug_tools_web/src/app_window_bloc.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';

import '../theme.dart';
import 'common_widgets.dart';

const double APP_NAVI_HEIGHT = 36;

class AppNaviBar extends StatefulWidget {
  final String title;
  final IconData icon;

  AppNaviBar({this.title, this.icon});

  @override
  _AppNaviBarState createState() => _AppNaviBarState();
}

class _AppNaviBarState extends State<AppNaviBar> {
  AppWindowBloc _appWindowBloc;

  @override
  void initState() {
    _appWindowBloc = BlocProvider.of<AppWindowBloc>(context).first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Container(
      height: APP_NAVI_HEIGHT,
      decoration: BoxDecoration(
          color: theme.primaryColor,
          border: Border(bottom: BorderSide(color: theme.focusColor))),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      widget.icon,
                      size: 14,
                      color: Colors.white,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: denseSpacing),
                      child: Text(
                        widget.title ?? '',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                )),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Visibility(
                    visible:
                        _appWindowBloc.appItem.showInNavigationBar != false,
                    child: AppWindowActionIcon(
                      Icons.minimize,
                      onTap: () {
                        _appWindowBloc.toggleMinimize();
                      },
                    ),
                  ),
                  Visibility(
                    visible: _appWindowBloc.appItem.canFullScreen != false,
                    child: AppWindowActionIcon(Icons.fullscreen, onTap: () {
                      _appWindowBloc.toggleFullScreen();
                    }),
                  ),
                  AppWindowActionIcon(
                    Icons.close,
                    onTap: () {
                      _appWindowBloc.close();
                    },
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
