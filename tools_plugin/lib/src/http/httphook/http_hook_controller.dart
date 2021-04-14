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

import 'package:flutter/cupertino.dart';
import 'package:k_debug_tools/src/webserver/handlers/ws_handler.dart';

import '../http_float_button.dart';
import '../http_models.dart';
import 'config_provider.dart';
import 'config_models.dart';
import 'http_hook_local_service.dart';

///网络拦截抓包及修改控制
class HttpHookController {
  HttpHookController._privateConstructor();

  static final HttpHookController instance =
      HttpHookController._privateConstructor();

  static final int maxArchiveCount = 200;

  ///请求历史记录
  late List<HttpArchive> _archiveList;

  ///默认不打开，不持久化 每次都需要设置开启
  final ValueNotifier<bool> enableHook = ValueNotifier(false);

  late ConfigProvider _hookConfigProvider;
  late HttpHookLocalService _localService;

  final List<HookConfig> _hookConfigs = <HookConfig>[];

  List<HookConfig> get hookConfigs => _hookConfigs.toList(growable: false);

  List<HttpArchive> get httpArchives => _archiveList.toList(growable: false);

  Future init() async {
    _hookConfigProvider = ConfigProvider(dbTableName: 'hook_config');
    _localService = HttpHookLocalService.instance;
    _archiveList = <HttpArchive>[];
  }

  ///设置
  void setEnable(bool enable) {
    enableHook.value = enable;
    if (enable) {
      _reloadConfig();
      _localService.start();
      showHttpFloatBtn();
    } else {
      _localService.stop();
      dismissHttpFloatBtn();
    }
  }

  Uri mapLocalUri(HookConfig? config) {
    return Uri.parse(_localService.mapLocalServiceUri + '?id=${config?.id}');
  }

  Future _reloadConfig() async {
    _hookConfigs.clear();
    List<ConfigRecord> records = await _hookConfigProvider.getAllRecord();
    records.forEach((element) {
      _hookConfigs.add(HookConfig.fromRecord(element)..id = element.id);
    });
  }

  Future<int> add(HookConfig? config) async {
    int id = await _hookConfigProvider.add(jsonEncode(config));
    debugPrint('HookConfig added, id: $id');
    await _reloadConfig();
    return id;
  }

  Future<int> update(HookConfig config) async {
    int rows = await _hookConfigProvider.update(config.id, jsonEncode(config));
    debugPrint('$rows hookConfig updated');
    await _reloadConfig();
    return rows;
  }

  Future<int> delete(int? id) async {
    int rows = await _hookConfigProvider.delete(id);
    debugPrint('$rows hookConfig deleted');
    await _reloadConfig();
    return rows;
  }

  void addArchive(HttpArchive archive) {
    _archiveList.add(archive);
    if (_archiveList.length > maxArchiveCount) {
      _archiveList.removeAt(0);
    }
  }

  void clearArchive() {
    _archiveList.clear();
  }

  void sendToWeb(HttpArchive archive) {
    //通过websocket发送
    WebSocketHandler.broadcastJson('httphook', 0, archive.toJson());
  }
}
