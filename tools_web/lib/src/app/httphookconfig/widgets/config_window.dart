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
import 'package:k_debug_tools_web/src/app/app_register.dart';
import 'package:k_debug_tools_web/src/app/httphookconfig/hook_config_bloc.dart';
import 'package:k_debug_tools_web/src/app_window_bloc.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/theme.dart';
import 'package:k_debug_tools_web/src/widgets/common_widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../web_bloc.dart';
import 'config_list.dart';
import 'map_local_edit.dart';
import 'map_remote_edit.dart';

enum ConfigType { mapLocal, mapRemote }

class HookConfigListWindow extends StatefulWidget {
  final ConfigType configType;

  const HookConfigListWindow({Key key, this.configType}) : super(key: key);

  @override
  _HookConfigListWindowState createState() => _HookConfigListWindowState();
}

class _HookConfigListWindowState extends State<HookConfigListWindow> {
  HookConfigBloc _hookConfigBloc;
  AppWindowBloc _windowBloc;
  AppItem _newConfigApp;
  WebBloc _webBloc;

  @override
  void initState() {
    _webBloc = BlocProvider.of<WebBloc>(context).first;
    _hookConfigBloc = BlocProvider.of<HookConfigBloc>(context).first;
    _windowBloc = BlocProvider.of<AppWindowBloc>(context).first;
    _hookConfigBloc.loadConfigs().then((value) {
      setState(() {});
    }).catchError((e) {
      _windowBloc.toast(AppLocalizations.of(context).loadFailed(e));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Column(
        children: <Widget>[
          //顶部菜单 action
          _buildActionWidget(),
          Expanded(
            child: _buildListWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildListWidget() {
    return Container(
        child: ConfigListWidget(
          configType: widget.configType,
        ));
  }

  ///action区域
  Widget _buildActionWidget() {
    return Container(
      height: 30,
      color: actionBarBackgroundColor(Theme.of(context)),
      child: Row(
        children: <Widget>[
          ActionIcon(
            Icons.refresh,
            enable: true,
            onTap: () {
              _hookConfigBloc.loadConfigs().then((value) {
                setState(() {});
              }).catchError((e) {
                _windowBloc.toast(AppLocalizations.of(context).loadFailed(e));
              });
            },
          ),
          ActionIcon(
            Icons.add_rounded,
            enable: true,
            onTap: () {
              if (widget.configType == ConfigType.mapLocal) {
                _actionShowNewMapLocal();
              } else {
                _actionShowNewMapRemote();
              }
            },
          )
        ],
      ),
    );
  }

  void _actionShowNewMapLocal() {
    _newConfigApp ??= AppItem(
        name: AppLocalizations.of(context).addRule,
        subTitle: 'Map Local',
        canFullScreen: false,
        icon: Icons.add_rounded,
        defaultSize: Size(400, 500),
        contentBuilder: (ctx) {
          return BlocProvider(
              blocs: [_hookConfigBloc], child: HookConfigMapLocal());
        });
    _webBloc.openOrBringFront(_newConfigApp);
  }

  void _actionShowNewMapRemote() {
    _newConfigApp ??= AppItem(
        name: AppLocalizations.of(context).addRule,
        subTitle: 'Map Remote',
        canFullScreen: false,
        icon: Icons.add_rounded,
        defaultSize: Size(400, 300),
        contentBuilder: (ctx) {
          return BlocProvider(
              blocs: [_hookConfigBloc], child: HookConfigMapRemote());
        });
    _webBloc.openOrBringFront(_newConfigApp);
  }
}
