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
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/widgets.dart';
import 'package:k_debug_tools_web/src/app/logwatcher/log_models.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/web_http.dart';
import 'package:k_debug_tools_web/src/websocket/web_socket_bloc.dart';

class LogWatcherBloc extends AppBlocBase {
  static const String PATH = 'api/logwatcher';
  BuildContext context;

  WebSocketBloc _webSocketBloc;

  bool _enable = false;

  ///是否启
  bool get isEnable => _enable;

  OnSocketData _onData;

  int _st = 0;
  BehaviorSubject<int> _stateSub = BehaviorSubject<int>();

  Sink<int> get _stateSink => _stateSub.sink;

  Stream<int> get stateStream => _stateSub.stream;

  final List<LogEntry> _logList = <LogEntry>[];

  List<LogEntry> get logList => _logList.toList(growable: false);

  List<LogEntry> get filteredLogList {
    List<LogEntry> list = <LogEntry>[];
    _logList.forEach((element) {
      bool filtered = false; //被过滤
      if (_keywordFilter != null &&
          _keywordFilter.length > 0 &&
          !element.msg.contains(_keywordFilter)) {
        filtered = true;
      }
      if (!filtered) {
        list.add(element);
      }
    });
    return list;
  }

  int lastSetStateTs = 0;

  ///用于延迟更新
  Timer _setStateTimer;

  String _keywordFilter;

  String get keywordFilter => _keywordFilter;

  LogWatcherBloc(this.context) : super(context) {
    //start watch
    setEnable(true);
    //start listen
    _webSocketBloc = BlocProvider.of<WebSocketBloc>(context).first;
    _onData = (msg) {
      try {
        LogEntry archive = LogEntry.fromJson(
            jsonDecode(utf8.decode(msg.data)) as Map<String, dynamic>);
        _logList.add(archive);
        _setStateDelayIfNotlimited();
      } catch (e) {
        debugPrint(e);
      }
    };
    _webSocketBloc.registerSub('logwatcher', _onData);
  }

  @override
  void dispose() {
    debugPrint('dispose LogWatcherBloc...');
    _setStateTimer?.cancel();
    _stateSub.close();
    //stop listen
    _webSocketBloc?.unregisterSub('logwatcher', _onData);
  }

  ///设置状态
  Future setEnable(bool enable) async {
    Uri uri = Uri.http(getHost(), '$PATH/toggle');
    var response = await httpPost(uri, body: {
      'enable': enable,
    });
    debugPrint('toggle LogWatcher to $enable, response: ${response.body}');
    _reloadState();
    return Future.value();
  }

  ///重新加载状态
  Future _reloadState() async {
    Uri uri = Uri.http(getHost(), '$PATH/state');
    var response = await httpGet(uri);
    Map<String, Object> jsonResponse = jsonDecode(response.body);
    _enable = (jsonResponse['data'] as Map)['enable'] as bool;
    setState();
    return Future.value();
  }

  ///关键字过滤
  void applyKeywordFilter(String text) {
    if (_keywordFilter != text) {
      _keywordFilter = text;
      _setStateDelayIfNotlimited();
    }
  }

  ///延迟更新 日志会有大量数据
  void _setStateDelayIfNotlimited() {
    _setStateTimer?.cancel();
    if (DateTime.now().millisecondsSinceEpoch - lastSetStateTs > 100) {
      setState();
    } else {
      _setStateTimer = Timer(Duration(milliseconds: 100), () {
        setState();
      });
    }
  }

  void setState([var f]) {
    lastSetStateTs = DateTime.now().millisecondsSinceEpoch;
    _stateSink.add(++_st);
  }

  ///清除记录
  void clear() {
    _logList.clear();
    setState();
  }
}
