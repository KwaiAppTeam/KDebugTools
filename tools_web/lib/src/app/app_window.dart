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

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:oktoast/oktoast.dart';
import 'package:k_debug_tools_web/src/app_window_bloc.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/widgets/app_navi_bar.dart';
import 'package:k_debug_tools_web/src/widgets/flutter_cursor/cursors.dart';
import 'package:k_debug_tools_web/src/widgets/flutter_cursor/flutter_cursor.dart';

class AppWindowWidget extends StatefulWidget {
  final String title;
  final String subTitle;
  final Widget child;

  AppWindowWidget({
    Key key,
    this.title,
    this.subTitle,
    this.child,
  }) : super(key: key);

  @override
  _AppWindowWidgetState createState() => _AppWindowWidgetState();
}

class _AppWindowWidgetState extends State<AppWindowWidget> {
  AppWindowBloc _appWindowBloc;

  @override
  void initState() {
    _appWindowBloc = BlocProvider.of<AppWindowBloc>(context).first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String title = '${widget.title}';
    if (widget.subTitle != null) {
      title += ' - ${widget.subTitle}';
    }
    return Listener(
      onPointerDown: (d) {
        _appWindowBloc.setFocus();
      },
      child: ResizeableWidget(
        defaultSize: _appWindowBloc.defaultSize,
        defaultAlignment: _appWindowBloc.windowAlignment,
        fullScreen: _appWindowBloc.isFullScreen,
        canResize: _appWindowBloc.canResize,
        canMove: _appWindowBloc.canMove,
        child: Material(
          elevation: 50,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).focusColor),
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    AppNaviBar(
                      title: title,
                      icon: _appWindowBloc.appItem.icon,
                    ),
                    Expanded(
                        child: Container(
                      color: Theme.of(context).colorScheme.background,
                      child: widget.child,
                    ))
                  ],
                ),
                OKToast(
                  child: Overlay(
                    key: _appWindowBloc.appWindowOverlayKey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ResizeableWidget extends StatefulWidget {
  final Size defaultSize;
  final Alignment defaultAlignment;
  final BoxConstraints constraints;
  final bool fullScreen;
  final bool canResize;
  final bool canMove;

  ResizeableWidget({
    this.child,
    this.fullScreen = false,
    this.canResize = true,
    this.canMove = true,
    this.defaultAlignment = Alignment.center,
    this.defaultSize = const Size(640, 480),
    this.constraints = const BoxConstraints(minHeight: 160, minWidth: 160),
  });

  final Widget child;

  @override
  _ResizeableWidgetState createState() => _ResizeableWidgetState();
}

///四边的控制器高度或宽度
const barThickness = 8.0;

///四个角的控制器半径
const ballRadius = 10.0;

///调试
const _debug = false;

class _ResizeableWidgetState extends State<ResizeableWidget> {
  double height;
  double width;

  double top = 0;
  double left = 0;

  Size _overlaySize;

  bool _applyDefaultAlignment = false;

  @override
  void initState() {
    height = widget.defaultSize.height;
    width = widget.defaultSize.width;
    super.initState();
  }

  void _applyLimit() {
    double screenWidth = _overlaySize.width;
    double screenHeight = _overlaySize.height;

    ///大小限制
    width = max(width, widget.constraints.minWidth);
    width = min(width, screenWidth);

    height = max(height, widget.constraints.minHeight);
    height = min(height, screenHeight);

    //应用对齐方式一次
    if (!_applyDefaultAlignment) {
      _applyDefaultAlignment = true;
      if (widget.defaultAlignment == Alignment.center) {
        //居中
        top = (screenHeight - height) / 2;
        left = (screenWidth - width) / 2;
      } else if (widget.defaultAlignment == Alignment.topRight) {
        left = screenWidth - width;
        top = 0;
      } //todo 其他未实现
    }

    ///计算偏移量限制
    if (left > screenWidth - width) {
      left = screenWidth - width;
    }
    if (left < 0) {
      left = 0;
    }
    if (top > screenHeight - height) {
      top = screenHeight - height;
    }
    if (top < 0) {
      top = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_debug) {
      debugPrint('left: $left top: $top width: $width height: $height');
    }

    final RenderBox overlay = Overlay.of(context).context.findRenderObject();
    _overlaySize = overlay.size;

    _applyLimit();

    //全屏
    if (widget.fullScreen) {
      double width = _overlaySize.width;
      double height = _overlaySize.height;
      return Stack(
        children: <Widget>[
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              height: height,
              width: width,
              child: widget.child,
            ),
          )
        ],
      );
    }

    bool canResize = widget.canResize;
    return Stack(
      children: <Widget>[
        Positioned(
          top: top,
          left: left,
          child: Container(
            height: height,
            width: width,
            child: widget.child,
          ),
        ),
        // top left
        Positioned(
          top: top - ballRadius,
          left: left - ballRadius,
          child: HoverCursor(
            cursor: canResize ? Cursor.nwseResize : null,
            child: _Manipulating(
              enable: canResize,
              shape: BoxShape.circle,
              ballRadius: ballRadius,
              onDrag: (dx, dy) {
                var newHeight = height - dy;
                var newWidth = width - dx;
                setState(() {
                  height = newHeight > 0 ? newHeight : 0;
                  width = newWidth > 0 ? newWidth : 0;
                  top = top + dy;
                  left = left + dx;
                });
              },
            ),
          ),
        ),
        // top middle
        Positioned(
          top: top - barThickness / 2,
          left: left + ballRadius,
          child: HoverCursor(
            cursor: canResize ? Cursor.nsResize : null,
            child: _Manipulating(
              enable: canResize,
              shape: BoxShape.rectangle,
              width: width - 2 * ballRadius,
              height: barThickness,
              onDrag: (dx, dy) {
                var newHeight = height - dy;

                setState(() {
                  height = newHeight > 0 ? newHeight : 0;
                  top = top + dy;
                });
              },
            ),
          ),
        ),
        // top right
        Positioned(
          top: top - ballRadius,
          left: left + width - ballRadius,
          child: HoverCursor(
            cursor: canResize ? Cursor.neswResize : null,
            child: _Manipulating(
              enable: canResize,
              shape: BoxShape.circle,
              ballRadius: ballRadius,
              onDrag: (dx, dy) {
                var newHeight = height - dy;
                var newWidth = width + dx;

                setState(() {
                  height = newHeight > 0 ? newHeight : 0;
                  width = newWidth > 0 ? newWidth : 0;
                  top = top + dy;
                });
              },
            ),
          ),
        ),
        // center right
        Positioned(
          top: top + ballRadius,
          left: left + width - barThickness / 2,
          child: HoverCursor(
            cursor: canResize ? Cursor.ewResize : null,
            child: _Manipulating(
              enable: canResize,
              shape: BoxShape.rectangle,
              width: barThickness,
              height: height - 2 * barThickness,
              onDrag: (dx, dy) {
                var newWidth = width + dx;

                setState(() {
                  width = newWidth > 0 ? newWidth : 0;
                });
              },
            ),
          ),
        ),
        // bottom right
        Positioned(
          top: top + height - ballRadius,
          left: left + width - ballRadius,
          child: HoverCursor(
            cursor: canResize ? Cursor.nwseResize : null,
            child: _Manipulating(
              enable: canResize,
              shape: BoxShape.circle,
              ballRadius: ballRadius,
              onDrag: (dx, dy) {
                var newHeight = height + dy;
                var newWidth = width + dx;
                setState(() {
                  height = newHeight > 0 ? newHeight : 0;
                  width = newWidth > 0 ? newWidth : 0;
                });
              },
            ),
          ),
        ),
        // bottom center
        Positioned(
          top: top + height - barThickness / 2,
          left: left - ballRadius,
          child: HoverCursor(
            cursor: canResize ? Cursor.nsResize : null,
            child: _Manipulating(
              enable: canResize,
              shape: BoxShape.rectangle,
              width: width,
              height: barThickness,
              onDrag: (dx, dy) {
                var newHeight = height + dy;
                setState(() {
                  height = newHeight > 0 ? newHeight : 0;
                });
              },
            ),
          ),
        ),
        // bottom left
        Positioned(
          top: top + height - ballRadius,
          left: left - ballRadius,
          child: HoverCursor(
            cursor: canResize ? Cursor.neswResize : null,
            child: _Manipulating(
              enable: canResize,
              shape: BoxShape.circle,
              ballRadius: ballRadius,
              onDrag: (dx, dy) {
                var newHeight = height + dy;
                var newWidth = width - dx;

                setState(() {
                  height = newHeight > 0 ? newHeight : 0;
                  width = newWidth > 0 ? newWidth : 0;
                  left = left + dx;
                });
              },
            ),
          ),
        ),
        //left center
        Positioned(
          top: top + ballRadius,
          left: left - barThickness / 2,
          child: HoverCursor(
            cursor: canResize ? Cursor.ewResize : null,
            child: _Manipulating(
              enable: canResize,
              shape: BoxShape.rectangle,
              width: barThickness,
              height: height - 2 * barThickness,
              onDrag: (dx, dy) {
                var newWidth = width - dx;

                setState(() {
                  width = newWidth > 0 ? newWidth : 0;
                  left = left + dx;
                });
              },
            ),
          ),
        ),
        // center center
//        Positioned(
//          top: top + height / 2 - ballRadius,
//          left: left + width / 2 - ballRadius,
//          child: ManipulatingBall(
//            onDrag: (dx, dy) {
//              setState(() {
//                top = top + dy;
//                left = left + dx;
//              });
//            },
//          ),
//        ),
        //app navi bar
        Positioned(
          top: top + barThickness / 2,
          left: left + ballRadius,
          child: _Manipulating(
            enable: widget.canMove,
            shape: BoxShape.rectangle,
            width: width - 2 * ballRadius - 80,
            //减去右边按钮的宽度
            height: APP_NAVI_HEIGHT - barThickness / 2,
            onDrag: (dx, dy) {
              setState(() {
                top = top + dy;
                left = left + dx;
              });
            },
          ),
        ),
      ],
    );
  }
}

///拖动的东西
class _Manipulating extends StatefulWidget {
  final double ballRadius;
  final double width;
  final double height;
  final BoxShape shape;
  final bool enable;

  _Manipulating(
      {Key key,
      this.onDrag,
      @required this.shape,
      this.ballRadius,
      this.enable = true,
      this.width,
      this.height});

  final Function onDrag;

  @override
  _ManipulatingBallState createState() => _ManipulatingBallState();
}

class _ManipulatingBallState extends State<_Manipulating> {
  double initX;
  double initY;

  _handleDrag(details) {
    if (widget.enable) {
      setState(() {
        initX = details.globalPosition.dx;
        initY = details.globalPosition.dy;
      });
    }
  }

  _handleUpdate(details) {
    if (widget.enable) {
      var dx = details.globalPosition.dx - initX;
      var dy = details.globalPosition.dy - initY;
      initX = details.globalPosition.dx;
      initY = details.globalPosition.dy;
      widget.onDrag(dx, dy);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: _handleDrag,
      onPanUpdate: _handleUpdate,
      child: Container(
        width: widget.shape == BoxShape.circle
            ? widget.ballRadius * 2
            : widget.width,
        height: widget.shape == BoxShape.circle
            ? widget.ballRadius * 2
            : widget.height,
        decoration: BoxDecoration(
          color: _debug ? Colors.blue.withOpacity(0.5) : Colors.transparent,
          shape: widget.shape,
        ),
      ),
    );
  }
}
