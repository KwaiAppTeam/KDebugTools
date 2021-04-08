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

import '../debugger.dart';

class FloatingButtonWidget extends StatefulWidget {
  final Function onTap;
  final double btnSize;
  final IconData icon;

  FloatingButtonWidget({
    this.onTap,
    this.btnSize = 66,
    this.icon = Icons.bug_report,
  });

  @override
  _FloatingButtonWidgetState createState() => _FloatingButtonWidgetState();
}

class _FloatingButtonWidgetState extends State<FloatingButtonWidget> {
  double left = 30;
  double top = 80;
  double screenWidth;
  double screenHeight;
  double _opacity = 0.5;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    ///默认点击事件
    var tap = () {
      Debugger.instance.showDebuggerDialog(context);
    };
    Widget w;
    Color primaryColor = Theme.of(context).primaryColor;
    primaryColor = primaryColor.withOpacity(0.6);
    w = GestureDetector(
      onTap: widget.onTap ?? tap,
      onDoubleTap: () {
        Debugger.instance.hideDebugger();
      },
      onPanUpdate: _dragUpdate,
      onPanEnd: (v) {
        _opacity = 0.5;
        setState(() {});
      },
      child: Container(
          child: Icon(
            widget.icon,
            size: 44,
            color: Colors.black.withOpacity(_opacity),
          ),
          color: Colors.blueGrey[300].withOpacity(_opacity)),
    );

    ///圆形
    w = ClipRRect(
      borderRadius: BorderRadius.circular(widget.btnSize / 2),
      child: w,
    );

    ///计算偏移量限制
    if (left < 1) {
      left = 1;
    }
    if (left > screenWidth - widget.btnSize) {
      left = screenWidth - widget.btnSize;
    }

    if (top < 1) {
      top = 1;
    }
    if (top > screenHeight - widget.btnSize) {
      top = screenHeight - widget.btnSize;
    }
    w = Container(
      alignment: Alignment.topLeft,
      margin: EdgeInsets.only(left: left, top: top),
      child: w,
    );
    return w;
  }

  _dragUpdate(DragUpdateDetails detail) {
    _opacity = 1;
    Offset offset = detail.delta;
    left = left + offset.dx;
    top = top + offset.dy;
    setState(() {});
  }
}
