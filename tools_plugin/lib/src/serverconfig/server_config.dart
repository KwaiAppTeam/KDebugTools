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

import 'package:k_debug_tools/src/serverconfig/server_config_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../k_debug_tools.dart';
import '../widgets/list_widgets.dart';

class ServerEnv {
  ServerEnv._privateConstructor();

  static final ServerEnv instance = ServerEnv._privateConstructor();

  static const String KEY_SERVER_INDEX = "KEY_SERVER_INDEX";
  static const String KEY_SERVER_ENV = "KEY_SERVER_ENV";

  List<String> _allEnvKeys;
  List<ServerEnvConfig> _allConfigs;

  SharedPreferences _spf;

  ServerEnvConfig get config => _config;
  ServerEnvConfig _config;

  String get envName => config.name ?? localizationOptions.unconfigured;

  int get envIndex => config?.index ?? 0;

  ///设置当前选中的index
  set envIndex(int v) {
    _spf.setInt(KEY_SERVER_INDEX, v);
    _config = _loadConfig(v);
  }

  Future<void> init(
      List<String> allEnvKeys, List<ServerEnvConfig> allConfigs) async {
    _allEnvKeys = allEnvKeys;
    _allConfigs = allConfigs;
    _spf = await SharedPreferences.getInstance();
    int index = _spf.getInt(KEY_SERVER_INDEX) ?? 0;
    _config = _loadConfig(index);
    return Future.value();
  }

  bool hasConfig() {
    return _allEnvKeys?.isNotEmpty == true && _allConfigs?.isNotEmpty == true;
  }

  ///映射线上域名到配置的域名
  String mapHost(String standardHost) {
    String result = standardHost;
    if (_allConfigs != null && _allConfigs.isNotEmpty) {
      //第一个作为标准
      ServerEnvConfig standard = _allConfigs[0];
      standard.envs.forEach((key, value) {
        if (standardHost == value) {
          result = config.envs[key];
          return;
        }
      });
    }
    return result;
  }

  ///取值
  String getEnvValue(String key) {
    return _config?.envs[key];
  }

  ///设置到当前选中的配置中
  void setEnv(String k, String v) {
    if (!config.canEdit) {
      return;
    }
    config.envs[k] = v;
    //save to sp
    _spf.setString('$KEY_SERVER_ENV-${config.index}', json.encode(config.envs));
  }

  ///读取配置 会从preferences尝试读取自定义的内容
  ServerEnvConfig _loadConfig(int index) {
    if (_allConfigs == null || _allConfigs.length < index || index < 0) {
      return null;
    }
    ServerEnvConfig config = _allConfigs[index];
    if (config.canEdit) {
      //load from preferences
      String str = _spf.getString('$KEY_SERVER_ENV-$index') ?? '';
      if (str.isNotEmpty) {
        Map map = json.decode(str) as Map;
        map.forEach((key, value) {
          config.envs[key.toString()] = value.toString();
        });
      }
    }
    return config;
  }
}

class ServerEnvConfigPage extends StatefulWidget {
  @override
  _ServerEnvConfigPageState createState() => _ServerEnvConfigPageState();
}

class _ServerEnvConfigPageState extends State<ServerEnvConfigPage> {
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
    List<String> names = List<String>();
    ServerEnv.instance._allConfigs?.forEach((e) {
      names.add(e.name);
    });
    result.add(SimpleListSelectWidget(
      label: localizationOptions.config,
      valueGetter: () {
        return ServerEnv.instance.envIndex;
      },
      valueSetter: (v) {
        setState(() {
          debugPrint('set envIndex: $v');
          ServerEnv.instance.envIndex = v;
          setState(() {});
        });
      },
      itemValues: names,
    ));
    //列出所有可配置项
    ServerEnv.instance._allEnvKeys?.forEach((key) {
      result.add(SimpleListInputWidget(
        label: key,
        keyboardType: TextInputType.url,
        enable: ServerEnv.instance.config.canEdit,
        valueGetter: () {
          return ServerEnv.instance.config.envs[key] ?? '';
        },
        valueSetter: (v) {
          debugPrint('set Env: $key >>> $v');
          ServerEnv.instance.setEnv(key, v);
          setState(() {});
        },
      ));
    });
    return result;
  }
}
