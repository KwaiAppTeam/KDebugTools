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
import 'package:k_debug_tools/k_debug_tools.dart';

import 'httphook/http_throttle_controller.dart';

OverlayEntry _itemEntry;

showHttpFloatBtn() async {
  if (_itemEntry == null) {
    OverlayState rootOverlay;
    OverlayState findOverlay(BuildContext ctx) {
      OverlayState ret = Overlay.of(ctx, rootOverlay: true);
      if (ret == null) {
        ctx.visitChildElements((element) {
          if (ret == null) {
            ret = findOverlay(element);
          }
        });
      }
      return ret;
    }

    rootOverlay = findOverlay(await Debugger.instance.appContext.future);
    if (rootOverlay != null) {
      _itemEntry =
          OverlayEntry(builder: (BuildContext context) => HttpButtonWidget());
      rootOverlay.insert(_itemEntry);
    }
  }
}

dismissHttpFloatBtn() {
  _itemEntry?.remove();
  _itemEntry = null;
}

class HttpButtonWidget extends StatefulWidget {
  @override
  _HttpButtonWidgetState createState() => _HttpButtonWidgetState();
}

double _left;

double _top;

class _HttpButtonWidgetState extends State<HttpButtonWidget> {
  double screenWidth;
  double screenHeight;
  double width = 70;
  double height = 30;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    _left ??= screenWidth;
    _top ??= MediaQuery.of(context).padding.top + 20;

    Widget w;
    w = GestureDetector(
      onTap: () {
        Debugger.instance
            .showDebuggerDialog(context, initialRoute: 'http_hook');
      },
      onPanUpdate: _dragUpdate,
      child: SizedBox(
        width: width,
        height: height,
        child: Material(
          type: MaterialType.transparency,
          child: DefaultTextStyle(
            style: TextStyle(fontSize: 12),
            child: Container(
              color: Colors.green.withOpacity(0.8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.arrow_upward_rounded,
                        size: 12,
                      ),
                      ValueListenableBuilder(
                          valueListenable:
                              HttpThrottleController.instance.totalUp,
                          builder: (ctx, up, _) {
                            return Text(
                                '${(up / 1024 / 1024).toStringAsFixed(3)}MB');
                          })
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.arrow_downward_rounded,
                        size: 12,
                      ),
                      ValueListenableBuilder(
                          valueListenable:
                              HttpThrottleController.instance.totalDown,
                          builder: (ctx, down, _) {
                            return Text(
                                '${(down / 1024 / 1024).toStringAsFixed(3)}MB');
                          })
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (_left < 1) {
      _left = 1;
    }
    if (_left > screenWidth - width) {
      _left = screenWidth - width;
    }
    if (_top < 1) {
      _top = 1;
    }
    if (_top > screenHeight - height) {
      _top = screenHeight - height;
    }
    w = Container(
      alignment: Alignment.topLeft,
      margin: EdgeInsets.only(left: _left, top: _top),
      child: w,
    );
    return w;
  }

  _dragUpdate(DragUpdateDetails detail) {
    Offset offset = detail.delta;
    _left = _left + offset.dx;
    _top = _top + offset.dy;
    setState(() {});
  }
}
