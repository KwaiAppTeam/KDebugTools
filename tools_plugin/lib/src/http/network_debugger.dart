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
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:k_debug_tools/src/http/httphook/http_hook_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/list_widgets.dart';
import 'http_client_wrapper.dart';

class NetworkProxyConfig {
  bool enable = false;
  String proxyIp;
  String proxyPort;

  NetworkProxyConfig({this.enable, this.proxyIp, this.proxyPort});

  NetworkProxyConfig copyWith({
    bool enable,
    String proxyIp,
    String proxyPort,
  }) {
    return NetworkProxyConfig(
      enable: enable ?? this.enable,
      proxyIp: proxyIp ?? this.proxyIp,
      proxyPort: proxyPort ?? this.proxyPort,
    );
  }
}

class NetworkDebugger {
  NetworkDebugger._privateConstructor();

  static final NetworkDebugger instance = NetworkDebugger._privateConstructor();

  static const String KEY_PROXY_ENABLE = "KEY_PROXY_ENABLE";
  static const String KEY_PROXY_IP = "KEY_PROXY_IP";
  static const String KEY_PROXY_PORT = "KEY_PROXY_PORT";

  SharedPreferences _spf;

  final ValueNotifier<bool> enableProxy = ValueNotifier(false);

  String get proxyIp => _spf.getString(KEY_PROXY_IP);

  String get proxyPort => _spf.getString(KEY_PROXY_PORT);

  void setEnableProxy(bool v) {
    enableProxy.value = v;
    _spf.setBool(KEY_PROXY_ENABLE, v);
  }

  set proxyIp(String v) {
    _spf.setString(KEY_PROXY_IP, v);
  }

  set proxyPort(String v) {
    _spf.setString(KEY_PROXY_PORT, v);
  }

  Future<void> init() async {
    _spf = await SharedPreferences.getInstance();
    enableProxy.value = _spf.get(KEY_PROXY_ENABLE) == true;

    await HttpHookController.instance.init();
    //全局HttpOverrides
    HttpOverrides.global = MyHttpOverrides();
    return Future.value();
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    HttpClient hc = HttpClientWrapper(super.createHttpClient(context))
      ..findProxy = _findProxy
      ..badCertificateCallback =
          ((X509Certificate cert, String host, int port) =>
              NetworkDebugger.instance.enableProxy.value);
    return hc;
  }

  String _findProxy(url) {
    return NetworkDebugger.instance.enableProxy.value
        ? "PROXY ${NetworkDebugger.instance.proxyIp}:${NetworkDebugger.instance.proxyPort}"
        : 'DIRECT';
  }
}

class NetworkProxyConfigPage extends StatefulWidget {
  @override
  _NetworkProxyConfigPageState createState() => _NetworkProxyConfigPageState();
}

class _NetworkProxyConfigPageState extends State<NetworkProxyConfigPage> {
  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = _buildInfo();
    return ListView.separated(
      controller: ScrollController(),
      padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
      itemCount: widgets.length,
      itemBuilder: (BuildContext context, int index) {
        return widgets[index];
      },
      separatorBuilder: (BuildContext context, int index) {
        return Divider(height: 1, color: Color(0xff000000));
      },
    );
  }

  List<Widget> _buildInfo() {
    List<Widget> result = List<Widget>();
    result.add(SimpleListToggleWidget(
      label: 'Enable',
      value: NetworkDebugger.instance.enableProxy,
      onChanged: (v) {
        NetworkDebugger.instance.setEnableProxy(v);
        setState(() {});
      },
    ));

    result.add(SimpleListInputWidget(
      label: 'IP',
      keyboardType: TextInputType.url,
      valueGetter: () {
        return NetworkDebugger.instance.proxyIp;
      },
      valueSetter: (v) {
        NetworkDebugger.instance.proxyIp = v;
        setState(() {});
      },
    ));

    result.add(SimpleListInputWidget(
      label: 'Port',
      keyboardType: TextInputType.number,
      valueGetter: () {
        return NetworkDebugger.instance.proxyPort;
      },
      valueSetter: (v) {
        NetworkDebugger.instance.proxyPort = v;
        setState(() {});
      },
    ));

    return result;
  }
}
