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
import 'package:k_debug_tools_web/main.dart';
import 'package:k_debug_tools_web/src/app/model.dart';
import 'package:k_debug_tools_web/src/app_window_bloc.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/event/PinEvent.dart';
import 'package:k_debug_tools_web/src/event_bus.dart';
import 'package:k_debug_tools_web/src/theme.dart';
import 'package:k_debug_tools_web/src/websocket/web_socket_bloc.dart';
import 'package:k_debug_tools_web/src/websocket/web_socket_models.dart';
import 'package:k_debug_tools_web/src/widgets/common_widgets.dart';
import 'package:k_debug_tools_web/src/widgets/root_navi_bar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'device_info_bloc.dart';

class DeviceInfoWindow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      child: DeviceInfoWidget(),
      blocs: [DeviceInfoBloc(context)],
    );
  }
}

class DeviceInfoWidget extends StatefulWidget {
  @override
  _DeviceInfoWidgetState createState() => _DeviceInfoWidgetState();
}

class _DeviceInfoWidgetState extends State<DeviceInfoWidget> {
  DeviceInfoBloc _deviceInfoBloc;
  AppWindowBloc _windowBloc;

  @override
  void initState() {
    _deviceInfoBloc = BlocProvider.of<DeviceInfoBloc>(context).first;
    _windowBloc = BlocProvider.of<AppWindowBloc>(context).first;
    _deviceInfoBloc.initData().then((v) {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: _buildListWidget(),
    );
  }

  ///列表内容
  Widget _buildListWidget() {
    List<BaseKeyValue> base = <BaseKeyValue>[];
    base.add(BaseKeyValue('brand', _deviceInfoBloc.data['brand']));
    base.add(BaseKeyValue('model', _deviceInfoBloc.data['model']));
    base.add(BaseKeyValue('version', _deviceInfoBloc.data['version']));

    List<BaseKeyValue> window = <BaseKeyValue>[];
    (_deviceInfoBloc.data['window'] as List)?.forEach((element) {
      window.add(BaseKeyValue.fromMap(element));
    });

    List<BaseKeyValue> extra = <BaseKeyValue>[];
    (_deviceInfoBloc.data['extra'] as List)?.forEach((element) {
      extra.add(BaseKeyValue.fromMap(element));
    });

    List<BaseKeyValue> platform = <BaseKeyValue>[];
    (_deviceInfoBloc.data['platform'] as List)?.forEach((element) {
      platform.add(BaseKeyValue.fromMap(element));
    });
    ThemeData theme = Theme.of(context);
    return CustomScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        SliverList(
            delegate: ListView.builder(
                itemCount: base.length,
                itemBuilder: (ctx, index) {
                  return _buildListWidgetItem(
                      theme, index, base.elementAt(index));
                }).childrenDelegate),
        SliverToBoxAdapter(
          child: Container(
            color: titleSolidBackgroundColor(theme),
            padding: EdgeInsets.only(left: 8, right: 8),
            child: Text(
              AppLocalizations.of(context).display,
              style: theme.textTheme.subtitle2.copyWith(fontSize: 12),
            ),
          ),
        ),
        SliverList(
            delegate: ListView.builder(
                itemCount: window.length,
                itemBuilder: (ctx, index) {
                  return _buildListWidgetItem(
                      theme, index, window.elementAt(index));
                }).childrenDelegate),
        SliverToBoxAdapter(
          child: Container(
            color: titleSolidBackgroundColor(theme),
            padding: EdgeInsets.only(left: 8, right: 8),
            child: Text(
              AppLocalizations.of(context).others,
              style: theme.textTheme.subtitle2.copyWith(fontSize: 12),
            ),
          ),
        ),
        SliverList(
            delegate: ListView.builder(
                itemCount: extra.length,
                itemBuilder: (ctx, index) {
                  return _buildListWidgetItem(
                      theme, index, extra.elementAt(index));
                }).childrenDelegate),
        SliverToBoxAdapter(
          child: Container(
            color: titleSolidBackgroundColor(theme),
            padding: EdgeInsets.only(left: 8, right: 8),
            child: Text(
              AppLocalizations.of(context).hardware,
              style: theme.textTheme.subtitle2.copyWith(fontSize: 12),
            ),
          ),
        ),
        SliverList(
            delegate: ListView.builder(
                itemCount: platform.length,
                itemBuilder: (ctx, index) {
                  return _buildListWidgetItem(
                      theme, index, platform.elementAt(index));
                }).childrenDelegate)
      ],
    );
  }

  Widget _buildListWidgetItem(ThemeData theme, int index, BaseKeyValue kv) {
    return Container(
      constraints: BoxConstraints(minHeight: 30),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        child: ListRow(
          separatorBuilder: (ctx, i) {
            return Container(width: 1, height: 30, color: theme.focusColor);
          },
          childPadding: EdgeInsets.only(left: 8, right: 8),
          children: <Widget>[
            Icon(
              Icons.label,
              size: 16,
            ),
            Expanded(
              flex: 3,
              child: Container(
                child: Text(
                  kv.key ?? '',
                  style: theme.textTheme.bodyText2,
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Container(
                child: SelectableText(
                  kv.value ?? '',
                  style: theme.textTheme.bodyText2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DeviceInfoQuickItem extends StatefulWidget {
  @override
  _DeviceInfoQuickItemState createState() => _DeviceInfoQuickItemState();
}

class _DeviceInfoQuickItemState extends State<DeviceInfoQuickItem> {
  DeviceInfoBloc _deviceInfoBloc;
  WebSocketBloc _webSocketBloc;
  StreamSubscription _ssStat;
  StreamSubscription _pinStat;

  @override
  void initState() {
    _deviceInfoBloc = DeviceInfoBloc(context);
    _deviceInfoBloc.initData().then((value) => setState(() {}));
    _webSocketBloc = BlocProvider.of<WebSocketBloc>(context).first;
    _ssStat = eventBus.on<WsStat>().listen((event) {
      setState(() {});
    });
    //init after PinVerified
    _pinStat = eventBus.on<PinVerified>().listen((event) {
      _deviceInfoBloc.initData().then((value) => setState(() {
            analytics.setUserId(_deviceInfoBloc.data['identifier'] ?? '');
            analytics.setUserProperty(
                name: 'DeviceBrand', value: _deviceInfoBloc.data['brand']);
            analytics.setUserProperty(
                name: 'DeviceModel', value: _deviceInfoBloc.data['model']);
            analytics.setUserProperty(
                name: 'DeviceVersion', value: _deviceInfoBloc.data['version']);
          }));
    });
    super.initState();
  }

  @override
  void dispose() {
    _ssStat?.cancel();
    _pinStat?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      constraints: BoxConstraints(
        minWidth: ROOT_NAVI_HEIGHT,
      ),
      height: ROOT_NAVI_HEIGHT,
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Icon(
                Icons.phone_iphone,
                size: 33,
                color: _webSocketBloc.isConnected()
                    ? Colors.greenAccent[100]
                    : Colors.redAccent[100],
              ),
              Align(
                  alignment: Alignment.center,
                  child: Text(_deviceInfoBloc.deviceName,
                      style: TextStyle(color: Colors.white)))
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Text(
              _webSocketBloc.isConnected() ? '' : AppLocalizations.of(context).disconnect,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
}
