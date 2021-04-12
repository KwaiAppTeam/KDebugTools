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
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:k_debug_tools_web/src/app_window_bloc.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/theme.dart';
import 'package:k_debug_tools_web/src/widgets/common_widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../web_bloc.dart';
import 'page_navigator_bloc.dart';
import 'page_navigator_models.dart';
import 'widgets/page_navigator_tree.dart';

class PageNavigatorWindow extends StatefulWidget {
  PageNavigatorWindow();

  @override
  _PageNavigatorWindowState createState() => _PageNavigatorWindowState();
}

class _PageNavigatorWindowState extends State<PageNavigatorWindow> {
  PageNavigatorBloc _bloc;

  @override
  void dispose() {
    _bloc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _bloc ??= PageNavigatorBloc(context);
    return BlocProvider(
      child: PageNavigator(),
      blocs: [_bloc],
    );
  }
}

class PageNavigator extends StatefulWidget {
  @override
  _PageNavigatorState createState() => _PageNavigatorState();
}

class _PageNavigatorState extends State<PageNavigator> {
  WebBloc _webBloc;
  PageNavigatorBloc _navigatorBloc;
  AppWindowBloc _windowBloc;
  TextEditingController _urlEditingController;

  @override
  void initState() {
    _webBloc = BlocProvider.of<WebBloc>(context).first;
    _navigatorBloc = BlocProvider.of<PageNavigatorBloc>(context).first;
    _windowBloc = BlocProvider.of<AppWindowBloc>(context).first;
    _urlEditingController = TextEditingController();
    _loadInfo();
    super.initState();
  }

  void _loadInfo() {
    _navigatorBloc.fetchInfo().then((value) {
      setState(() {});
    }).catchError((e) {
      _windowBloc.toast('$e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: _navigatorBloc.selectNodeStream,
        builder: (BuildContext context, AsyncSnapshot<Object> snapshot) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              //顶部菜单 action
              _buildTreeActionWidget(),
              Expanded(child: _buildContent()),
            ],
          );
        });
  }

  Widget _buildContent() {
    if (_navigatorBloc.root != null && _navigatorBloc.flutterCapture != null) {
      double scWidth = _navigatorBloc.flutterCapture.screenWidth;
      double scHeight = _navigatorBloc.flutterCapture.screenHeight;
      return ClipRect(
        child: SizedBox.expand(child: LayoutBuilder(builder: (_, constraints) {
          double imageScale = min(
              constraints.maxWidth / scWidth, constraints.maxHeight / scHeight);
          double treeLeft = imageScale * scWidth;
          return Stack(
            children: [
              Positioned.fill(
                child: OverflowBox(
                  minWidth: scWidth,
                  minHeight: scHeight,
                  maxWidth: scWidth,
                  maxHeight: scHeight,
                  alignment: Alignment.centerLeft,
                  child: Transform.scale(
                    scale: imageScale,
                    alignment: Alignment.centerLeft,
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          fit: BoxFit.cover,
                          width: scWidth,
                          height: scHeight,
                          alignment: Alignment.topLeft,
                          placeholder: (context, url) => UnconstrainedBox(
                              child: CircularProgressIndicator()),
                          imageUrl: _navigatorBloc.screenUri.toString(),
                        ),
                        Stack(
                          children: _buildWidgetAnchor(),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                left: treeLeft,
                child: PageNavigatorTreeWidget(),
              )
            ],
          );
        })),
      );
    } else {
      return Container();
    }
  }

  ///方框
  List<Widget> _buildWidgetAnchor() {
    Object selectNodeData = _navigatorBloc.selectedNodeData;
    NavigatorInfo root = _navigatorBloc.root;

    List<Widget> visitChild(NavigatorInfo navigator, bool show) {
      List<Widget> child = List<Widget>();
      navigator.routes?.forEach((route) {
        bool showThis =
            show || route == selectNodeData || navigator == selectNodeData;
        if (showThis) {
          if (route?.left != null &&
              route.top != null &&
              route.width != null &&
              route.height != null) {
            child.add(Positioned(
              left: route.left,
              top: route.top,
              width: route.width,
              height: route.height,
              child: Container(
                decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.redAccent.withOpacity(0.5), width: 8),
                    color: Colors.transparent),
              ),
            ));
          }
        }
        route.childNavigators?.forEach((element) {
          child.addAll(visitChild(element, showThis));
        });
      });
      return child;
    }

    List<Widget> all = visitChild(root, root == selectNodeData);
    return all;
  }

  ///树形目录结构上方action
  Widget _buildTreeActionWidget() {
    Object selectNodeData = _navigatorBloc.selectedNodeData;
    return Container(
      height: 30,
      color: actionBarBackgroundColor(Theme.of(context)),
      child: Row(
        children: <Widget>[
          ActionIcon(
            Icons.refresh,
            tooltip: AppLocalizations.of(context).refresh,
            onTap: () {
              _loadInfo();
            },
          ),
          ActionIcon(
            Icons.undo,
            tooltip: 'Pop',
            enable: selectNodeData is RouteInfo,
            onTap: _actionPopSelected,
          ),
          SizedBox(
            width: 30,
          ),
          _pushActionWidget()
        ],
      ),
    );
  }

  ///push
  Widget _pushActionWidget() {
    Object selectNodeData = _navigatorBloc.selectedNodeData;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Push:',
          style: Theme.of(context).textTheme.bodyText2,
        ),
        Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              border: Border.all(color: Theme.of(context).focusColor)),
          margin: EdgeInsets.fromLTRB(4, 0, 4, 0),
          padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
          width: 300,
          height: 25,
          child: TextField(
            textAlign: TextAlign.start,
            showCursor: true,
            style: TextStyle(fontSize: 14),
            decoration: null,
            controller: _urlEditingController,
          ),
        ),
        ActionIcon(
          Icons.redo,
          tooltip: 'Push',
          enable: selectNodeData is NavigatorInfo,
          onTap: () {
            if (_urlEditingController.text.isNotEmpty) {
              _navigatorBloc
                  .pushRoute(_urlEditingController.text,
                      (selectNodeData as NavigatorInfo).name)
                  .then((value) {
                _windowBloc.toast(AppLocalizations.of(context).success);
                Timer(Duration(seconds: 1), () {
                  _loadInfo();
                });
              }).catchError((e) {
                _windowBloc.toast(AppLocalizations.of(context).requestError(e));
              });
            }
          },
        ),
      ],
    );
  }

  void _actionPopSelected() {
    RouteInfo info = _navigatorBloc.selectedNodeData as RouteInfo;
    _windowBloc.showDialog(msg: AppLocalizations.of(context).confirmPopPage(info.name), actions: [
      DialogAction(
          text: AppLocalizations.of(context).confirm,
          handler: (ctrl) {
            ctrl.dismiss();
            _navigatorBloc.popRoute(info).then((value) {
              _windowBloc.toast(AppLocalizations.of(context).success);
              Timer(Duration(seconds: 1), () {
                _loadInfo();
              });
            }).catchError((e) {
              _windowBloc.toast(AppLocalizations.of(context).requestError(e));
            });
          },
          isPositive: true),
      DialogAction(
          text: AppLocalizations.of(context).cancel,
          handler: (ctrl) {
            ctrl.dismiss();
          },
          isPositive: false)
    ]);
  }
}
