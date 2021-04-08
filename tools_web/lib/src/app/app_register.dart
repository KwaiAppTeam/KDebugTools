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
import 'package:k_debug_tools_web/src/app/appinfo/app_info.dart';
import 'package:k_debug_tools_web/src/app/clipboard/clip_board.dart';
import 'package:k_debug_tools_web/src/app/dbview/db_view.dart';
import 'package:k_debug_tools_web/src/app/fileexplorer/file_explorer.dart';
import 'package:k_debug_tools_web/src/app/httphook/http_hook_window.dart';
import 'package:k_debug_tools_web/src/app/logwatcher/log_watcher.dart';
import 'package:k_debug_tools_web/src/app/pagenavigator/page_navigator.dart';
import 'package:k_debug_tools_web/src/app/screenrecorder/screen_recorder.dart';
import 'package:k_debug_tools_web/src/app/sharedpreferences/shared_preferences.dart';
import 'package:k_debug_tools_web/src/app/uicheck/uicheck.dart';

import 'deviceinfo/device_info.dart';

typedef WidgetBuilder = Widget Function(BuildContext context);

class AppItem {
  final String name;
  final String subTitle;
  final IconData icon;
  final Alignment windowAlignment;

  ///显示在导航栏
  final bool showInNavigationBar;

  final bool canResize;

  final bool canMove;

  ///能否全屏
  final bool canFullScreen;

  final Size defaultSize;

  ///构建快捷菜单的图标item
  final WidgetBuilder quickMenuItemBuilder;

  ///构建窗口内容 不含导航
  final WidgetBuilder contentBuilder;

  AppItem(
      {this.name,
      this.subTitle,
      this.icon,
      this.quickMenuItemBuilder,
      this.contentBuilder,
      this.windowAlignment = Alignment.center,
      this.showInNavigationBar = true,
      this.canResize = true,
      this.canMove = true,
      this.defaultSize = const Size(640, 480),
      this.canFullScreen = true});
}

class AppRegister {
  static final AppRegister instance = AppRegister._privateConstructor();

  AppRegister._privateConstructor();

  List<AppItem> _deskTopItems = List<AppItem>();
  List<AppItem> _quickMenuItems = List<AppItem>();

  ///显示在桌面上的应用
  List<AppItem> get deskTopAppItems => _deskTopItems.toList();

  ///快捷菜单上的应用
  List<AppItem> get quickMenuItems => _quickMenuItems.toList();

  void registerDefault() {
    _registerItemToDesktop();
    _registerItemToQuickMenu();
  }

  ///注册到桌面
  void _registerItemToDesktop() {
    _deskTopItems.add(AppItem(
        name: '设备剪切板',
        icon: Icons.content_paste,
        contentBuilder: (ctx) {
          return ClipBoardWindow();
        }));
    _deskTopItems.add(AppItem(
        name: '文件管理',
        icon: Icons.folder,
        contentBuilder: (ctx) {
          return FileExplorerWindow();
        }));

    _deskTopItems.add(AppItem(
        name: 'SharedPreferences',
        icon: Icons.view_list,
        contentBuilder: (ctx) {
          return SharedPreferencesWindow();
        }));

    _deskTopItems.add(AppItem(
        name: '网络请求',
        icon: Icons.network_check,
        contentBuilder: (ctx) {
          return HttpHookWindow();
        }));

    _deskTopItems.add(AppItem(
        name: '日志查看',
        icon: Icons.view_headline,
        contentBuilder: (ctx) {
          return LogWatcherWindow();
        }));

    _deskTopItems.add(AppItem(
        name: 'DbView',
        icon: Icons.format_indent_increase,
        contentBuilder: (ctx) {
          return DbViewWindow();
        }));
    //TextEditor 无需注册到桌面 使用时构造AppItem进行打开
//    _deskTopItems.add(AppItem(
//        name: 'TextEditor',
//        icon: Icons.text_fields,
//        contentBuilder: (ctx) {
//          return TextEditorWindow();
//        }));

    _deskTopItems.add(AppItem(
        name: 'FlutterUI',
        icon: Icons.image,
        defaultSize: Size(960, 720),
        contentBuilder: (ctx) {
          return UICheckWindow();
        }));
    _deskTopItems.add(AppItem(
        name: '投屏录屏',
        subTitle: '目前仅支持Android',
        icon: Icons.phonelink,
        defaultSize: Size(960, 720),
        contentBuilder: (ctx) {
          return ScreenRecorderWindow();
        }));
    _deskTopItems.add(AppItem(
        name: '路由跳转',
        icon: Icons.amp_stories_outlined,
        defaultSize: Size(900, 600),
        contentBuilder: (ctx) {
          return PageNavigatorWindow();
        }));
  }

  ///注册到快捷菜单
  void _registerItemToQuickMenu() {
    _quickMenuItems.add(AppItem(
        name: '应用信息',
        icon: Icons.info_outline,
        showInNavigationBar: false,
        canFullScreen: false,
        canResize: false,
        canMove: false,
        windowAlignment: Alignment.topRight,
        defaultSize: const Size(360, 320),
        quickMenuItemBuilder: (ctx) {
          return AppInfoQuickItem();
        },
        contentBuilder: (ctx) {
          return AppInfoWindow();
        }));

    _quickMenuItems.add(AppItem(
        name: '设备信息',
        icon: Icons.phone_iphone,
        showInNavigationBar: false,
        canFullScreen: false,
        canResize: false,
        canMove: false,
        windowAlignment: Alignment.topRight,
        defaultSize: const Size(480, 600),
        quickMenuItemBuilder: (ctx) {
          return DeviceInfoQuickItem();
        },
        contentBuilder: (ctx) {
          return DeviceInfoWindow();
        }));
  }
}
