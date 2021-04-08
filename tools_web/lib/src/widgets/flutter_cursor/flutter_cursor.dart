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

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'dart:html' as html;
import 'cursors.dart';

/// Custom hover cursor on web.
/// Wrap your child with this widget, and when the cursor enters/lease the widget, it will change the browser cursor.
class HoverCursor extends StatefulWidget {
  final Widget child;

  /// Cursor to show when entering hover zone.
  final Cursor cursor;

  /// Custom custom that is applied when entering hover zone. Overrides [cursor] when set.
  /// Can be any CSS `cursor` value, included a URL with x/y.
  final String customCursor;

  /// Custom to set when exiting hover zone. Setting to empty/`null` will reset.
  final String exitCursor;

  /// Whether to show exit cursor when disposing this widget.
  final bool exitOnDispose;

  const HoverCursor({
    Key key,
    this.child,
    this.cursor,
    this.customCursor,
    this.exitCursor,
    this.exitOnDispose = true,
  }) : super(key: key);

  @override
  _HoverCursorState createState() => _HoverCursorState();
}

class _HoverCursorState extends State<HoverCursor> {
  @override
  Widget build(BuildContext context) {
    return _HoverCursor(
      child: widget.child,
      cursor: widget.cursor,
      customCursor: widget.customCursor,
      exitCursor: widget.exitCursor,
    );
  }

  @override
  void dispose() {
    super.dispose();

    if (widget.exitOnDispose) {
      _HoverCursor.body.style.cursor = widget.exitCursor;
    }
  }
}

class _HoverCursor extends MouseRegion {
  //add id to body and set cursor of that doesn't work.
  // Because flt-glass-pane is replacing the cursor.
  // So the solution is that set cursor directly to flt-glass-pane.
//  static final body =
//      html.window.document.getElementsByTagName('body')[0] as html.Element;
  static final body =
      html.window.document.querySelectorAll('flt-glass-pane')[0];

  _HoverCursor({
    Widget child,
    Cursor cursor,
    String customCursor,
    String exitCursor,
  }) : super(
          onHover: (PointerHoverEvent evt) {
            body.style.cursor = customCursor ?? CursorValues[cursor];
          },
          onExit: (PointerExitEvent evt) {
            body.style.cursor = exitCursor;
          },
          child: child,
        );
}
