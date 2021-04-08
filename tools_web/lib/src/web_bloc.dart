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

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';
import 'package:k_debug_tools_web/main.dart';

import 'app/app_register.dart';
import 'app/app_window.dart';
import 'app_window_bloc.dart';
import 'bloc_provider.dart';

class WebBloc extends BlocBase {
  Map<AppItem, OverlayEntry> _appWindows = Map<AppItem, OverlayEntry>();
  Map<AppItem, AppWindowBloc> _appBlocs = Map<AppItem, AppWindowBloc>();

  //root nav下方的应用区域
  final GlobalKey<OverlayState> appAreaOverlay = GlobalKey<OverlayState>();

  AppItem _focusedApp;
  final BuildContext context;

  AppItem get focusedItem => _focusedApp;

  Map<AppItem, AppWindowBloc> get openedApps => _appBlocs;

  int _st = 0;
  BehaviorSubject<int> _stateSub = BehaviorSubject<int>();

  Sink<int> get _stateSink => _stateSub.sink;

  Stream<int> get stateStream => _stateSub.stream;

  WebBloc(this.context);

  bool isKeyPressed(LogicalKeyboardKey key) =>
      RawKeyboard.instance.keysPressed.contains(key);

  bool get isShiftPressed {
    return isKeyPressed(LogicalKeyboardKey.shiftLeft) ||
        isKeyPressed(LogicalKeyboardKey.shiftRight);
  }

  ///mac上的command键
  bool get isMetaPressed {
    return isKeyPressed(LogicalKeyboardKey.metaLeft) ||
        isKeyPressed(LogicalKeyboardKey.metaRight);
  }

  void handleOnKey(RawKeyEvent k) {
//    debugPrint('isShiftPressed $isShiftPressed $k');
  }

  ///app是否已经打开
  bool isAppOpened(AppItem app) {
    return _appWindows[app] != null;
  }

  ///打开一个新的app
  void openNewApp(AppItem app) {
    analytics.logEvent(name: 'openNewApp', parameters: {'AppName': app?.name});
    _createNewAndInsert(context, app);
  }

  ///打开或关闭ap
  void openOrClose(AppItem app) {
    if (isAppOpened(app)) {
      _closeAppWindow(app);
    } else {
      openNewApp(app);
    }
  }

  ///显示一个已经打开的app
  void showOpenedApp(AppItem app) {
    debugPrint('showOpenedApp: ${app.name}');
    analytics
        .logEvent(name: 'showOpenedApp', parameters: {'AppName': app?.name});
    _appBlocs[app].isMinimize = false;
    _applyFocusedState(app);
    _appWindows[app].markNeedsBuild();
  }

  ///打开新的或者显示到前面
  void openOrBringFront(AppItem app) {
    if (isAppOpened(app)) {
      showOpenedApp(app);
    } else {
      openNewApp(app);
    }
  }

  ///创建新的overlay并加入页面
  void _createNewAndInsert(BuildContext ctx, AppItem appItem) {
    //create bloc
    AppWindowBloc appWindowBloc = AppWindowBloc(
      appItem: appItem,
      onClose: () {
        _closeAppWindow(appItem);
      },
      onFocus: () {
        _applyFocusedState(appItem);
      },
      onFullScreen: (full) {
        _appWindows[appItem].markNeedsBuild();
      },
      onMinimize: (min) {
        _appWindows[appItem].markNeedsBuild();
        setState(() {});
      },
    );
    _appBlocs[appItem] = appWindowBloc;
    //create overlay
    OverlayEntry _overlayEntry = new OverlayEntry(
      builder: (context) {
        return BlocProvider(
          blocs: [_appBlocs[appItem]],
          child: BlocProvider(
            blocs: [this],
            child: Visibility(
              maintainState: true,
              visible: !_isMinimized(appItem),
              child: AppWindowWidget(
                key: Key('${appItem.hashCode}'),
                title: appItem.name,
                subTitle: appItem.subTitle,
                child: appItem.contentBuilder(context),
              ),
            ),
          ),
        );
      },
    );
    debugPrint('App created: ${appItem.name}');
    _focusedApp = appItem;
    analytics.setCurrentScreen(screenName: appItem.name);

    appAreaOverlay.currentState.insert(_overlayEntry);

    _appWindows[appItem] = _overlayEntry;
    setState(() {});
  }

  ///将窗口拉到最前面
  void _applyFocusedState(AppItem newItem) {
    if (newItem != _focusedApp || _appBlocs[newItem].isMinimize) {
      debugPrint('App focused: ${newItem.name}');
      _appBlocs[newItem].isMinimize = false;
      _focusedApp = newItem;
      analytics.setCurrentScreen(screenName: _focusedApp.name);

      //拉到最前面
      _appWindows[newItem].remove();
      appAreaOverlay.currentState.insert(_appWindows[newItem]);
      setState(() {});
    }
  }

  ///关闭窗口 释放资源
  void _closeAppWindow(AppItem appItem) {
    analytics
        .logEvent(name: 'closeApp', parameters: {'AppName': appItem?.name});
    _appWindows[appItem]?.remove();
    _appWindows.remove(appItem);
    _appBlocs[appItem]?.dispose();
    _appBlocs.remove(appItem);
    setState(() {});
  }

  ///释放已经打开并且最小化
  bool _isMinimized(AppItem appItem) {
    return _appBlocs[appItem]?.isMinimize == true;
  }

  void setState(var f) {
    _stateSink.add(++_st);
  }

  @override
  void dispose() {
    _stateSub.close();
  }

  static String getHost() {
    if ('localhost' == Uri.base.host) {
      //web开发中时使用
      return '172.31.84.79:9000';
    } else {
      return Uri.base.host + ':' + Uri.base.port.toString();
    }
  }

  static String getHostWithSchema() {
    return 'http://' + getHost();
  }
}
