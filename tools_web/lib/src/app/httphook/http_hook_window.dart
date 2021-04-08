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
import 'package:k_debug_tools_web/src/app/httphookconfig/throttle_config_window.dart';
import 'package:k_debug_tools_web/src/app/httphookconfig/widgets/config_window.dart';
import 'package:k_debug_tools_web/src/app_window_bloc.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/custom_color.dart';
import 'package:k_debug_tools_web/src/theme.dart';
import 'package:k_debug_tools_web/src/widgets/common_widgets.dart';
import 'package:k_debug_tools_web/src/widgets/split.dart';

import '../../web_bloc.dart';
import '../app_register.dart';
import 'http_hook_bloc.dart';
import 'widgets/http_hook_archive_detail.dart';
import 'widgets/http_hook_archive_list.dart';
import 'widgets/http_hook_domain_tree.dart';

class HttpHookWindow extends StatefulWidget {
  @override
  _HttpHookWindowState createState() => _HttpHookWindowState();
}

class _HttpHookWindowState extends State<HttpHookWindow> {
  HttpHookBloc _bloc;

  @override
  void dispose() {
    _bloc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _bloc ??= HttpHookBloc(context);
    return BlocProvider(
      child: HttpHook(),
      blocs: [_bloc],
    );
  }
}

class HttpHook extends StatefulWidget {
  @override
  _HttpHookState createState() => _HttpHookState();
}

class _HttpHookState extends State<HttpHook> {
  final GlobalKey _settingIconKey = GlobalKey();
  AppItem _throtteApp;
  AppItem _mapLocalApp;
  AppItem _mapRemoteApp;
  HttpHookBloc _httpHookBloc;
  AppWindowBloc _windowBloc;
  WebBloc _webBloc;
  TextEditingController _filterEditingController;

  @override
  void initState() {
    _webBloc = BlocProvider.of<WebBloc>(context).first;
    _httpHookBloc = BlocProvider.of<HttpHookBloc>(context).first;
    _windowBloc = BlocProvider.of<AppWindowBloc>(context).first;
    _filterEditingController = TextEditingController();
    _filterEditingController.addListener(() {
      _httpHookBloc.applyKeywordFilter(_filterEditingController.value?.text);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final splitAxis = Split.axisFor(context, 0.85);
    return StreamBuilder(
      stream: _httpHookBloc.stateStream,
      builder: (ctx, _) {
        return Container(
          width: double.infinity,
          child: Column(
            children: <Widget>[
              //顶部菜单 action
              _buildActionWidget(),
              Expanded(
                  child: Padding(
                padding: EdgeInsets.all(densePadding),
                child: Split(
                  axis: splitAxis,
                  initialFractions: const [0.33, 0.67],
                  children: [
                    Container(
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: Theme.of(context).focusColor)),
                        child: DomainTreeWidget()),
                    Container(
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: Theme.of(context).focusColor)),
                        child: _buildRightWidget()),
                  ],
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  ///右边区域
  Widget _buildRightWidget() {
    return ValueListenableBuilder(
      valueListenable: _httpHookBloc.selectedHttpArchive,
      builder: (ctx, value, child) {
        bool showDetail = _httpHookBloc.showSelectedDetail && value != null;
        if (showDetail) {
          return Split(
            axis: Axis.vertical,
            initialFractions: const [0.5, 0.5],
            children: [
              ArchiveListWidget(),
              ArchiveDetailWidget(
                archive: value,
              )
            ],
          );
        } else {
          return ArchiveListWidget();
        }
      },
    );
  }

  ///action区域
  Widget _buildActionWidget() {
    return Container(
      height: 30,
      width: double.infinity,
      color: actionBarBackgroundColor(Theme.of(context)),
      child: Row(
        children: <Widget>[
          ActionIcon(
            _httpHookBloc.isHookEnable ? Icons.stop : Icons.play_arrow,
            tooltip: _httpHookBloc.isHookEnable ? 'Stop' : 'Start',
            enable: true,
            customColor: _httpHookBloc.isHookEnable
                ? CustomColor.iconActionRed
                : CustomColor.iconActionGreen,
            onTap: () {
              _httpHookBloc.setHookState(!_httpHookBloc.isHookEnable);
            },
          ),
          ActionIcon(
            Icons.settings,
            tooltip: 'Settings',
            key: _settingIconKey,
            enable: true,
            onTap: _showSettingMenu,
          ),
          ActionIcon(
            Icons.delete,
            tooltip: 'Clear',
            enable: true,
            onTap: () {
              _httpHookBloc.clear();
            },
          ),
          //filter
          Expanded(child: _filterActionWidget()),
        ],
      ),
    );
  }

  ///设置菜单
  void _showSettingMenu() {
    showActionMenu(context: context, iconKey: _settingIconKey, items: [
      Text('Throttling...'),
      Text('Map Local...'),
      Text('Map Remote...'),
    ]).then((value) {
      debugPrint('menu $value clicked');
      switch (value) {
        case 0:
          _actionOpenThrottling();
          break;
        case 1:
          _actionOpenMapLocal();
          break;
        case 2:
          _actionOpenMapRemote();
          break;
      }
    });
  }

  void _actionOpenThrottling() {
    _throtteApp ??= AppItem(
        name: '限速配置',
        canFullScreen: false,
        icon: Icons.settings,
        canResize: false,
        defaultSize: Size(300, 100),
        contentBuilder: (ctx) {
          return BlocProvider(
              blocs: [_httpHookBloc.hookConfigBloc],
              child: ThrottleConfigWindow());
        });
    _webBloc.openOrBringFront(_throtteApp);
  }

  void _actionOpenMapLocal() {
    _mapLocalApp ??= AppItem(
        name: 'Hook配置',
        subTitle: 'Map Local',
        canFullScreen: false,
        icon: Icons.add_rounded,
        defaultSize: Size(600, 400),
        contentBuilder: (ctx) {
          return BlocProvider(
              blocs: [_httpHookBloc.hookConfigBloc],
              child: HookConfigListWindow(
                configType: ConfigType.mapLocal,
              ));
        });
    _webBloc.openOrBringFront(_mapLocalApp);
  }

  void _actionOpenMapRemote() {
    _mapRemoteApp ??= AppItem(
        name: 'Hook配置',
        subTitle: 'Map Remote',
        canFullScreen: false,
        icon: Icons.add_rounded,
        defaultSize: Size(600, 400),
        contentBuilder: (ctx) {
          return BlocProvider(
              blocs: [_httpHookBloc.hookConfigBloc],
              child: HookConfigListWindow(
                configType: ConfigType.mapRemote,
              ));
        });
    _webBloc.openOrBringFront(_mapRemoteApp);
  }

  Widget _filterActionWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('过滤:'),
        Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              border: Border.all(color: Theme.of(context).focusColor)),
          margin: EdgeInsets.fromLTRB(4, 0, 4, 0),
          padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
          width: 150,
          height: 25,
          child: TextField(
            textAlign: TextAlign.start,
            showCursor: true,
            style: TextStyle(fontSize: 14),
            decoration: null,
            controller: _filterEditingController,
          ),
        )
      ],
    );
  }
}
