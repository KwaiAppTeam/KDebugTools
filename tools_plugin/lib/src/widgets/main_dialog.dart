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
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:k_debug_tools/k_debug_tools.dart';
import 'package:k_debug_tools/src/webserver/web_server.dart';
import 'package:oktoast/oktoast.dart';
import '../register.dart';
import 'common_widgets.dart';

final RouteObserver<PageRoute> debuggerRouteObserver =
    RouteObserver<PageRoute<dynamic>>();

///主页面
class DebugWindow extends StatefulWidget {
  final String? initialRoute;

  const DebugWindow({Key? key, this.initialRoute}) : super(key: key);

  @override
  _DebugWindowState createState() => _DebugWindowState();
}

class _DebugWindowState extends State<DebugWindow> {
  BuildContext? subContext;

  @override
  void initState() {
    SchedulerBinding.instance!.addPostFrameCallback((_) {
      if (widget.initialRoute?.isNotEmpty ?? false) {
        ToolPageRoute? route =
            DebuggerRegister.instance.getPageRoute(widget.initialRoute);
        if (route != null) {
          showToolPage(subContext!, route.name, route.pageBuilder!);
        }
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        if (subContext == null) {
          return Future.value(true);
        }
        //先弹出子页面 然后弹走主页面
        if (Navigator.of(subContext!).canPop()) {
          Navigator.of(subContext!).pop();
          return Future.value(false);
        } else {
          return Future.value(true);
        }
      },
      child: SafeArea(
        bottom: false,
        child: Material(
          color: Colors.white,
          child: OKToast(
            child: DefaultTextStyle(
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w400),
              child: MaterialApp(
                //用MaterialApp对主页面进行包围 子页面不进入业务路由
                navigatorObservers: [debuggerRouteObserver],
                home: LayoutBuilder(
                  builder: (ctx, _) {
                    subContext = ctx;
                    return DebugDialogWidget();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DebugDialogWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _DebugDialogState();
  }
}

///hide pin
bool _hidePin = false;

class _DebugDialogState extends State<DebugDialogWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  @override
  void initState() {
    WidgetsBinding.instance!.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    debuggerRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    debuggerRouteObserver.subscribe(this, ModalRoute.of(context) as PageRoute<dynamic>);
    super.didChangeDependencies();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        setState(() {});
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: TextStyle(
          color: Colors.black, fontSize: 14, fontWeight: FontWeight.w400),
      child: Column(
        children: <Widget>[
          NavBar(
            title: Debugger.instance.title,
            onBack: () {
              Navigator.of(context, rootNavigator: true).pop();
            },
          ),
          Container(
            height: 50,
            padding: EdgeInsets.only(left: 16, right: 16),
            child: ValueListenableBuilder(
              valueListenable: WebServer.instance.started,
              builder: (_, dynamic started, child) {
                return Row(
                  children: [
                    Icon(Icons.laptop_rounded, size: 40),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(localizationOptions.webServer, style: TextStyle(fontSize: 16)),
                              SizedBox(width: 8),
                              Visibility(
                                  visible: started,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _hidePin = !_hidePin;
                                      });
                                    },
                                    child: Row(
                                      children: [
                                        Text(
                                            'PIN:${_hidePin ? '****' : WebServer.instance.pin}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54)),
                                        Icon(
                                          Icons.remove_red_eye_rounded,
                                          color: Colors.black54,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ))
                            ],
                          ),
                          SizedBox(height: 2),
                          Text(
                              started ? '${WebServer.instance.url}' : 'Stopped',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                    Switch(
                      value: started,
                      onChanged: (v) {
                        if (v) {
                          WebServer.instance.start();
                        } else {
                          WebServer.instance.stop();
                        }
                      },
                    )
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: _createWidgetSlivers(),
            ),
          )
        ],
      ),
    );
  }

  List<Widget> _createWidgetSlivers() {
    List<Widget> pSlivers = <Widget>[];
    DebuggerRegister.instance.groups.forEach((group) {
      if (group.toolWidgetBuilder!.isNotEmpty) {
        pSlivers.add(_createGroupTitle(group));
        pSlivers.add(_createGroupContent(group));
      }
    });
    return pSlivers;
  }

  Widget _createGroupTitle(ToolsGroup group) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.only(left: 8),
        color: Colors.black26,
        height: 30,
        alignment: Alignment.centerLeft,
        child: Text(group.title!),
      ),
    );
  }

  Widget _createGroupContent(ToolsGroup group) {
    return SliverGrid(
      gridDelegate: mySliverGridDelegate(1),
      delegate: SliverChildBuilderDelegate((context, index) {
        return group.toolWidgetBuilder![index](context);
      }, childCount: group.toolWidgetBuilder!.length),
    );
  }

  SliverGridDelegate mySliverGridDelegate(double aspectRatio) {
    return SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        childAspectRatio: aspectRatio);
  }
}
