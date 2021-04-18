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

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import '../common_widgets.dart';

typedef ActionCallback = void Function();

const tooltipWait = Duration(milliseconds: 500);
const tooltipWaitLong = Duration(milliseconds: 1000);

///显示菜单
Future<int> showActionMenu(
    {@required BuildContext context,
    @required GlobalKey iconKey,
    @required List<Widget> items,
    bool enable = true}) {
  final RenderBox renderBox = iconKey.currentContext.findRenderObject();
  final offset = renderBox.localToGlobal(Offset.zero);
  return showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          offset.dx, offset.dy + renderBox.size.height, offset.dx, 0),
      items: items
          .map((e) => PopupMenuItem<int>(
                value: items.indexOf(e),
                enabled: enable,
                height: 30,
                textStyle: Theme.of(context)
                    .textTheme
                    .bodyText2
                    .copyWith(fontSize: 12),
                child: e,
              ))
          .toList());
}

Future<int> showCheckedMenu(
    {@required BuildContext context,
    @required GlobalKey iconKey,
    @required List<Widget> items,
    List<int> checkIndex}) {
  final RenderBox renderBox = iconKey.currentContext.findRenderObject();
  final offset = renderBox.localToGlobal(Offset.zero);
  return showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          offset.dx, offset.dy + renderBox.size.height, offset.dx, 0),
      items: items
          .map((e) => CheckedPopupMenuItem<int>(
                value: items.indexOf(e),
                checked: checkIndex?.contains(items.indexOf(e)),
                child: e,
              ))
          .toList());
}

///actions in app action bar
class ActionIcon extends StatelessWidget {
  final IconData iconData;
  final bool enable;
  final bool checked;
  final Color customColor;
  final GestureTapCallback onTap;
  final String tooltip;

  ActionIcon(this.iconData,
      {Key key,
      this.enable = true,
      this.checked = false,
      this.customColor,
      this.onTap,
      this.tooltip})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final button = SizedBox(
      height: 24,
      width: 24,
      child: TextButton(
        onPressed: (enable && onTap != null) ? onTap : null,
        style: TextButton.styleFrom(
            backgroundColor: checked ? theme.focusColor : Colors.transparent),
        child: Icon(
          iconData,
          color: customColor,
          size: defaultIconSize,
        ),
      ),
    );
    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        preferBelow: false,
        waitDuration: tooltipWait,
        child: button,
      );
    }
    return button;
  }
}

class ActionOutlinedButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool enable;
  final GestureTapCallback onTap;

  ActionOutlinedButton(this.text, {this.icon, this.enable = true, this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: (enable && onTap != null)
          ? () {
              if (enable && onTap != null) {
                onTap();
              }
            }
          : null,
      child: Row(
        children: [
          Visibility(
            visible: icon != null,
            child: Icon(
              icon,
              size: defaultIconSize,
            ),
          ),
          Text(text)
        ],
      ),
    );
  }
}

///actions in app window bar
class AppWindowActionIcon extends StatelessWidget {
  final IconData iconData;
  final GestureTapCallback onTap;

  AppWindowActionIcon(this.iconData, {Key key, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final button = TextButton(
        onPressed: onTap, child: Icon(iconData, color: Colors.white, size: 22));
    return button;
  }
}

class ListValueInputWidget extends StatelessWidget {
  final TextEditingController editingController;
  final ValueChanged<String> onValueSubmitted;
  final ActionCallback onCancel;

  ListValueInputWidget(
      this.editingController, this.onValueSubmitted, this.onCancel);

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Container(
//      width: 150,
      height: 25,
      decoration: BoxDecoration(
          border: Border.all(color: theme.focusColor),
          color: theme.canvasColor),
      padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              maxLines: 1,
              showCursor: true,
              style: TextStyle(fontSize: 14),
              decoration: null,
              controller: editingController,
              onSubmitted: (s) {
                debugPrint('onSubmit new value: $s');
                if (onValueSubmitted != null) {
                  onValueSubmitted(s);
                }
              },
            ),
          ),
          GestureDetector(
            onTap: () {
              String text = editingController.text;
              debugPrint('onAccept new value: $text');
              if (onValueSubmitted != null) {
                onValueSubmitted(text);
              }
            },
            child: Icon(
              Icons.done,
              size: 16,
            ),
          ),
          SizedBox(
            width: 4,
          ),
          GestureDetector(
            onTap: () {
              if (onCancel != null) {
                onCancel();
              }
            },
            child: Icon(
              Icons.do_not_disturb,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class ListRow extends StatelessWidget {
  final double columnSeparateWidth;
  final List<Widget> children;
  final IndexedWidgetBuilder separatorBuilder;
  final EdgeInsetsGeometry childPadding;

  ListRow(
      {this.columnSeparateWidth,
      @required this.children,
      this.separatorBuilder,
      this.childPadding});

  @override
  Widget build(BuildContext context) {
    List<Widget> childrenWrapper = List<Widget>();
    for (int i = 0; i < children.length; i++) {
      Widget child = children.elementAt(i);
      childrenWrapper.add(child);
      if (i < children.length - 1 && separatorBuilder != null) {
        childrenWrapper.add(Container(
            padding: childPadding, child: separatorBuilder(context, i)));
      }
    }
    return Container(
      padding: childPadding,
      child: Row(
        children: childrenWrapper,
      ),
    );
  }
}

bool isJsonStr(String data) {
  try {
    jsonDecode(data);
    return true;
  } catch (e) {
    return false;
  }
}

///转body为格式化字符串
String formatJson(Uint8List body) {
  String str = '';
  try {
    //转字符串
    if (body != null) {
      str = utf8.decode(body);
    }
    //试试转json
    str = JsonEncoder.withIndent('  ').convert(jsonDecode(str));
  } on FormatException catch (e) {}
  return str;
}

class FixedHeightOutlinedButton extends StatelessWidget {
  const FixedHeightOutlinedButton({
    this.buttonKey,
    @required this.onPressed,
    @required this.child,
    this.autofocus = false,
    this.style,
    this.width,
    this.tooltip,
  });

  final Key buttonKey;

  final VoidCallback onPressed;

  final Widget child;

  final bool autofocus;

  final ButtonStyle style;

  final double width;

  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      height: defaultButtonHeight,
      width: width,
      child: OutlinedButton(
        key: buttonKey,
        style: style,
        autofocus: autofocus,
        onPressed: onPressed,
        child: child,
      ),
    );
    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        preferBelow: false,
        waitDuration: tooltipWait,
        child: button,
      );
    }
    return button;
  }
}
