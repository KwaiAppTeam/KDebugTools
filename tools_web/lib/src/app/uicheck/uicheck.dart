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

import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:k_debug_tools_web/src/app/uicheck/uicheck_bloc.dart';
import 'package:k_debug_tools_web/src/app/uicheck/uicheck_models.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/theme.dart';
import 'package:k_debug_tools_web/src/widgets/common_widgets.dart';

import '../../app_window_bloc.dart';

class UICheckWindow extends StatefulWidget {
  @override
  _UICheckWindowState createState() => _UICheckWindowState();
}

class _UICheckWindowState extends State<UICheckWindow> {
  UiCheckBloc _bloc;

  @override
  void dispose() {
    _bloc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _bloc ??= UiCheckBloc(context);
    return BlocProvider(
      child: UiCheck(),
      blocs: [_bloc],
    );
  }
}

class UiCheck extends StatefulWidget {
  @override
  _UiCheckState createState() => _UiCheckState();
}

class _UiCheckState extends State<UiCheck> {
  AppWindowBloc _windowBloc;
  UiCheckBloc _screenBloc;
  bool _drawGird = false;
  bool _drawPadding = false;
  bool _drawAnchorMask = false;
  WidgetNode _selectNode;
  WidgetNode _hoverNode;

  @override
  void initState() {
    _windowBloc = BlocProvider.of<AppWindowBloc>(context).first;
    _screenBloc = BlocProvider.of<UiCheckBloc>(context).first;
    _screenBloc.capture().then((value) {
      setState(() {});
    }).catchError((e, s) {
      _windowBloc.toast('加载失败 $e');
      debugPrint('$e $s');
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Column(
        children: <Widget>[
          //顶部菜单 action
          _buildActionWidget(),
          Expanded(child: _buildContentWidget()),
        ],
      ),
    );
  }

  Widget _buildContentWidget() {
    StringBuffer nodeInfo = StringBuffer();
    if (_selectNode != null) {
      nodeInfo.write('${_selectNode.name}\n');
      nodeInfo.write('data: ${_selectNode.data}\n');
      nodeInfo.write('height: ${_selectNode.height.toStringAsFixed(2)}\n');
      nodeInfo.write('width: ${_selectNode.width.toStringAsFixed(2)}\n');
      _selectNode.attrs?.forEach((key, value) {
        nodeInfo.write('$key: $value\n');
      });
    }
    if (_screenBloc.hasScreenshot) {
      return ClipRect(
        child: SizedBox.expand(
          child: Stack(
            children: [
              Positioned.fill(
                //可以放大的区域
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 10,
                  child: LayoutBuilder(
                    builder: (_, constraints) {
                      double scale = min(
                          constraints.maxWidth / _screenBloc.deviceWidth,
                          constraints.maxHeight / _screenBloc.deviceHeight);
                      return OverflowBox(
                        minWidth: _screenBloc.deviceWidth,
                        minHeight: _screenBloc.deviceHeight,
                        maxWidth: _screenBloc.deviceWidth,
                        maxHeight: _screenBloc.deviceHeight,
                        alignment: Alignment.centerLeft,
                        child: Transform.scale(
                          scale: scale,
                          alignment: Alignment.centerLeft,
                          child: Stack(
                            children: [
                              CachedNetworkImage(
                                fit: BoxFit.cover,
                                width: _screenBloc.deviceWidth,
                                height: _screenBloc.deviceHeight,
                                alignment: Alignment.topLeft,
                                placeholder: (context, url) => UnconstrainedBox(
                                    child: CircularProgressIndicator()),
                                imageUrl: _screenBloc.screenshotNetPath,
                              ),
                              Stack(
                                children: _buildWidgetAnchor(_screenBloc.root),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Visibility(
                visible: _drawGird,
                child: Positioned.fill(
                  child: IgnorePointer(
                    child: GridPaper(
                      color: Colors.redAccent,
                      interval: 50,
                      divisions: 1,
                      subdivisions: 1,
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: _selectNode != null,
                child: Positioned(
                    right: 0,
                    top: 0,
                    width: 250,
                    child: Container(
                      decoration: BoxDecoration(
                          border:
                              Border.all(color: Theme.of(context).focusColor)),
                      child: Padding(
                          padding: EdgeInsets.all(densePadding),
                          child: SelectableText(nodeInfo.toString())),
                    )),
              )
            ],
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  ///锚点点击
  void _onAnchorTap(WidgetNode node) {
    _selectNode = _selectNode == node ? null : node;
    setState(() {});
  }

  ///锚点鼠标聚焦
  void _onAnchorHover(WidgetNode node) {
    if (_hoverNode != node) {
      _hoverNode = node;
      //todo 加入组件测距信息
      setState(() {});
    }
  }

  ///锚点
  List<Widget> _buildWidgetAnchor(WidgetNode root) {
    List<Widget> visitChild(WidgetNode childNode) {
      List<Widget> thisAndChild = List<Widget>();
      if (childNode?.left != null &&
          childNode.top != null &&
          childNode.width != null &&
          childNode.height != null) {
        thisAndChild.add(Positioned(
          left: childNode.left,
          top: childNode.top,
          width: childNode.width,
          height: childNode.height,
          child: MouseRegion(
            onHover: (e) {
              _onAnchorHover(childNode);
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _onAnchorTap(childNode);
              },
              child: Container(
                decoration: BoxDecoration(
                    border: _selectNode == childNode
                        ? Border.all(color: Colors.redAccent, width: 1)
                        : (_hoverNode == childNode
                            ? Border.all(
                                color: Colors.redAccent.withOpacity(0.6),
                                width: 1)
                            : null),
                    color: _drawAnchorMask
                        ? Colors.green.withOpacity(0.2)
                        : Colors.transparent),
              ),
            ),
          ),
        ));
      }
      childNode?.children?.forEach((element) {
        thisAndChild.addAll(visitChild(element));
      });
      return thisAndChild;
    }

    List<Widget> all = visitChild(root);
    //
    if (_drawPadding) {
      if (_screenBloc.paddingTop > 0) {
        all.add(Positioned(
          left: 0,
          top: 0,
          width: _screenBloc.deviceWidth,
          height: _screenBloc.paddingTop,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _windowBloc.toast('Top: ${_screenBloc.paddingTop}');
            },
            child: Container(
              color: Colors.redAccent.withOpacity(0.5),
            ),
          ),
        ));
      }
      if (_screenBloc.paddingBottom > 0) {
        all.add(Positioned(
          left: 0,
          top: _screenBloc.deviceHeight - _screenBloc.paddingBottom,
          width: _screenBloc.deviceWidth,
          height: _screenBloc.paddingBottom,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _windowBloc.toast('Bottom: ${_screenBloc.paddingBottom}');
            },
            child: Container(
              color: Colors.redAccent.withOpacity(0.5),
            ),
          ),
        ));
      }
    }
    return all;
  }

  ///刷新
  void _refresh() {
    _hoverNode = null;
    _selectNode = null;
    _screenBloc.capture().then((value) {
      setState(() {});
    }).catchError((e) {
      _windowBloc.toast('加载失败 $e');
    });
    setState(() {});
  }

  ///action区域
  Widget _buildActionWidget() {
    return Container(
      height: 30,
      color: actionBarBackgroundColor(Theme.of(context)),
      child: Row(
        children: <Widget>[
          ActionIcon(
            Icons.refresh,
            tooltip: 'Refresh',
            enable: true,
            onTap: () {
              _refresh();
            },
          ),
          ActionIcon(
            Icons.view_day,
            tooltip: 'Show Padding',
            enable: true,
            checked: _drawPadding,
            onTap: () {
              _drawPadding = !_drawPadding;
              setState(() {});
            },
          ),
          ActionIcon(
            Icons.grid_on,
            tooltip: 'Show Gird',
            checked: _drawGird,
            enable: _screenBloc.hasScreenshot,
            onTap: () {
              _drawGird = !_drawGird;
              setState(() {});
            },
          ),
          ActionIcon(
            Icons.remove_red_eye,
            tooltip: 'Show Mask',
            checked: _drawAnchorMask,
            enable: _screenBloc.hasScreenshot,
            onTap: () {
              _drawAnchorMask = !_drawAnchorMask;
              setState(() {});
            },
          ),
          ActionIcon(
            Icons.open_in_browser,
            tooltip: 'Open in browser',
            enable: _screenBloc.hasScreenshot,
            onTap: () {
              _screenBloc.openScreenshotInNewTab();
            },
          ),
          ActionIcon(
            Icons.file_download,
            tooltip: 'Download',
            enable: _screenBloc.hasScreenshot,
            onTap: () {
              _screenBloc.downloadScreenshot();
            },
          ),
        ],
      ),
    );
  }
}
