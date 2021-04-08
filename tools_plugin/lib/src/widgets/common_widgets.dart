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
import 'package:k_debug_tools/src/widgets/transparent_route.dart';

typedef ActionCallback = Future Function();

///构建tool落地页
typedef ToolPageBuilder = Widget Function(BuildContext context);
typedef ItemBuilder = Widget Function(BuildContext context);

///一组相同类别的tools
class ToolsGroup {
  String title;
  List<ItemBuilder> toolWidgetBuilder;

  ToolsGroup({this.title, this.toolWidgetBuilder});
}

class ToolPageRoute {
  String name;
  ToolPageBuilder pageBuilder;

  ToolPageRoute({this.name, this.pageBuilder});
}

///显示工具页面
void showToolPage(BuildContext ctx, String name, ToolPageBuilder pageBuilder) {
  Widget pageWrapper = SafeArea(
    top: false,
    child: DefaultTextStyle(
      style: TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      child: Container(
        color: Colors.white,
        child: Column(
          children: <Widget>[
            NavBar(
              title: name,
              onBack: () {
                Navigator.pop(ctx);
              },
            ),
            Expanded(child: pageBuilder(ctx)),
          ],
        ),
      ),
    ),
  );

  Navigator.push(ctx, TransparentCupertinoPageRoute(
    builder: (ctx) {
      return pageWrapper;
    },
  ));
}

abstract class ToolItemWidget extends StatefulWidget {
  final IconData icon;
  final Widget iconWidget;
  final String name;
  final String summary;
  final ActionCallback clickAction;
  final ToolPageBuilder pageBuilder;

  ToolItemWidget(
      {this.icon,
      this.iconWidget,
      @required this.name,
      this.summary,
      this.clickAction,
      this.pageBuilder});

  Widget _buildIcon() {
    return iconWidget != null
        ? iconWidget
        : Icon(
            icon ?? Icons.block,
            size: 36,
            color: Colors.black,
          );
  }

  void _showToolPage(BuildContext ctx) {
    if (pageBuilder != null) {
      showToolPage(ctx, name, pageBuilder);
    }
  }
}

///点击后执行action或者跳转到页面的item
class SimpleToolItemWidget extends ToolItemWidget {
  SimpleToolItemWidget(
      {IconData icon,
      Widget iconWidget,
      @required String name,
      String summary,
      ActionCallback clickAction,
      ToolPageBuilder pageBuilder})
      : super(
            icon: icon,
            iconWidget: iconWidget,
            name: name,
            summary: summary,
            clickAction: clickAction,
            pageBuilder: pageBuilder);

  @override
  State<StatefulWidget> createState() => _SimpleToolItemWidgetState();
}

class _SimpleToolItemWidgetState extends State<SimpleToolItemWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.clickAction != null) {
          widget.clickAction().then((v) {
            setState(() {});
          });
        } else if (widget.pageBuilder != null) {
          widget._showToolPage(context);
        } else {
          //todo
//          KIToast.showKToast('未实现...');
        }
      },
      child: Container(
        color: Color(0xffffffff),
        padding: EdgeInsets.all(4),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            widget._buildIcon(),
            SizedBox(
              height: 6,
            ),
            Text(
              widget.name,
            ),
            Text(
              widget.summary ?? '',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class ToggleToolItemWidget extends ToolItemWidget {
  final ValueNotifier<bool> value;
  final ValueChanged<bool> onChanged;

  ToggleToolItemWidget(
      {IconData icon,
      Widget iconWidget,
      @required String name,
      String summary,
      ActionCallback clickAction,
      ToolPageBuilder pageBuilder,
      this.value,
      this.onChanged})
      : super(
            icon: icon,
            iconWidget: iconWidget,
            name: name,
            summary: summary,
            clickAction: clickAction,
            pageBuilder: pageBuilder);

  @override
  State<StatefulWidget> createState() => _ToggleToolItemWidgetState();
}

///点击下面开关部分后执行 开关状态切换；上半部分执行action 或者 进入落地页(若有) 或者 开关状态切换
class _ToggleToolItemWidgetState extends State<ToggleToolItemWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTap: () {
        if (widget.clickAction != null) {
          widget.clickAction();
        } else if (widget.pageBuilder != null) {
          widget._showToolPage(context);
        } else {
          widget.onChanged(!widget.value.value);
        }
      },
      child: Container(
        color: Color(0xFFFFFFFF),
        padding: EdgeInsets.all(4),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            widget._buildIcon(),
            SizedBox(
              height: 6,
            ),
            Text(
              widget.name,
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                widget.onChanged(!widget.value.value);
              },
              child: Container(
                alignment: Alignment.topCenter,
                width: double.infinity,
                height: 18,
                child: Transform.scale(
                  scale: 0.5,
                  child: ValueListenableBuilder(
                    valueListenable: widget.value,
                    builder: (_, value, child) {
                      return Switch(
                        value: value,
                        onChanged: widget.onChanged,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavBar extends StatelessWidget {
  final String title;
  final Function onBack;

  const NavBar({Key key, this.title, this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(width: 1, color: Colors.black12))),
      height: 48,
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () {
                if (onBack != null) {
                  onBack();
                }
              },
              child: Container(
                height: 48,
                width: 48,
                child: Center(
                  child: Icon(
                    Icons.arrow_back_ios,
                    size: 24,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Text(title ?? ''),
          )
        ],
      ),
    );
  }
}
