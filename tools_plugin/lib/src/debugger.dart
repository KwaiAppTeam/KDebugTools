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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:k_debug_tools/src/dbview/db_view_controller.dart';
import 'package:k_debug_tools/src/http/httphook/http_hook_controller.dart';
import 'package:k_debug_tools/src/logwatcher/log_watcher_controller.dart';
import 'package:k_debug_tools/src/webserver/web_server.dart';

import 'serverconfig/server_config_models.dart';
import 'register.dart';
import 'widgets/main_dialog.dart';
import 'http/network_debugger.dart';
import 'serverconfig/server_config.dart';
import 'widgets/common_widgets.dart';
import 'widgets/floating_button.dart';
import 'widgets/transparent_route.dart';

const double _paddingTop = 80;

typedef Future PushNamedCallback(NavigatorState navigatorState, String url);

class Debugger {
  Debugger._privateConstructor();

  static final Debugger instance = Debugger._privateConstructor();

  var _debuggerOverlay;

  String _title;

  String get title => _title;
  BuildContext _appContext;

  final Completer<BuildContext> appContext = Completer<BuildContext>();

  GlobalKey _rootRepaintBoundaryKey;

  GlobalKey get rootRepaintBoundaryKey => _rootRepaintBoundaryKey;

  ///添加到root显示的自定义文件夹name-absolute
  final Map<String, String> _customRootDirs = Map<String, String>();

  Map<String, String> get customRootDirs => _customRootDirs;

  ///自定义路由打开方式
  PushNamedCallback _customPushNamed;

  ///初始化
  Future<void> init(
      {String toolTitle = 'KDebugTools',
      bool autoStartWebServer = false,
      bool autoStartHttpHook = false,
      List<String> allServEnvKeys,
      List<ServerEnvConfig> allServConfigs}) async {
    _title = toolTitle;
    await ServerEnv.instance.init(allServEnvKeys, allServConfigs);
    await NetworkDebugger.instance.init();
    if (autoStartWebServer ?? false) {
      await WebServer.instance.start();
    }
    if (autoStartHttpHook ?? false) {
      HttpHookController.instance.setEnable(true);
    }
    DebuggerRegister.instance.registerDefault();
    return Future.value();
  }

  Future<OverlayState> findRootOverlay() async {
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

    return findOverlay(await Debugger.instance.appContext.future);
  }

  ///显示浮窗
  void showDebugger(BuildContext context) async {
    if (_appContext == null) {
      _appContext = context;
      //find root context
      context.visitAncestorElements((element) {
        if (element.depth == 1) {
          _appContext = element;
          return false;
        }
        return true;
      });
      if (!appContext.isCompleted) {
        appContext.complete(_appContext);
      }
    }

    _debuggerOverlay?.remove();
    _debuggerOverlay = new OverlayEntry(
      builder: (context) {
        return FloatingButtonWidget();
      },
    );
    OverlayState rootOverlay = await findRootOverlay();
    rootOverlay?.insert(_debuggerOverlay);
  }

  ///隐藏浮窗
  void hideDebugger() {
    if (_debuggerOverlay != null) {
      _debuggerOverlay.remove();
      _debuggerOverlay = null;
    }
  }

  ///浮窗是否显示中
  bool isFloatingDebuggerShowing() {
    return _debuggerOverlay != null;
  }

  ///显示主页面
  void showDebuggerDialog(BuildContext ctx, {String initialRoute}) {
    //只弹出一个主页面
    if (debuggerRouteObserver.navigator == null) {
      Navigator.push(ctx, TransparentCupertinoPageRoute(builder: (ctx) {
        return Padding(
            padding: EdgeInsets.only(top: _paddingTop),
            child: DebugWindow(
              initialRoute: initialRoute,
            ));
      }));
    } else {
      //隐藏主页面
      hideDebuggerDialog(ctx);
    }
  }

  ///隐藏主页面
  hideDebuggerDialog(BuildContext ctx) {
    Navigator.pop(ctx);
  }

  ///添加组件到 信息
  void registerItemToInfoGroup(ItemBuilder item) {
    DebuggerRegister.instance.registerItemToInfoGroup(item);
  }

  ///添加组件到 工具
  void registerItemToKitGroup(ItemBuilder item) {
    DebuggerRegister.instance.registerItemToKitGroup(item);
  }

  ///添加组件到 调试
  void registerItemToDebuggingGroup(ItemBuilder item) {
    DebuggerRegister.instance.registerItemToDebuggingGroup(item);
  }

  ///添加组件到 其他
  void registerItemToOtherGroup(ItemBuilder item) {
    DebuggerRegister.instance.registerItemToOtherGroup(item);
  }

  ///手动添加数据库文件
  void registerDbFile(String filePath) {
    DbViewController.instance.registerDbFile(filePath);
  }

  ///添加自定义文件夹到root显示 如 下载目录、缓存目录等
  void addCustomDirToRoot(String name, String absolute) {
    assert(name != null);
    assert(absolute != null);
    _customRootDirs[name] = absolute;
  }

  ///更新根节点key 会用于屏幕截图, 若未指定会寻找最顶部一个RenderRepaintBoundary进行截图
  void updateRootRepaintBoundary(GlobalKey key) {
    _rootRepaintBoundaryKey = key;
  }

  ///打印日志 会发送给web; 解决release包中的debugPrint无法打印问题
  void customDebugPrint(String message) {
    LogWatcherController.instance.customDebugPrint(message);
  }

  Future pushNamed(NavigatorState navigatorState, String url) {
    if (_customPushNamed != null) {
      return _customPushNamed(navigatorState, url);
    }
    return navigatorState.pushNamed(url);
  }

  ///自定义跳转方法
  void setCustomPushNamed(PushNamedCallback callback) {
    _customPushNamed = callback;
  }
}
