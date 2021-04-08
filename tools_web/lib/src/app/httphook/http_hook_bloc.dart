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
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/widgets.dart';
import 'package:k_debug_tools_web/src/app/httphookconfig/hook_config_bloc.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/web_http.dart';
import 'package:k_debug_tools_web/src/websocket/web_socket_bloc.dart';
import 'package:k_debug_tools_web/src/widgets/item_picker.dart';
import 'http_models.dart';

class HttpHookBloc extends AppBlocBase {
  static const String PATH = 'api/httphook';
  BuildContext context;

  WebSocketBloc _webSocketBloc;
  HookConfigBloc _hookConfigBloc;

  HookConfigBloc get hookConfigBloc => _hookConfigBloc;

  bool _hookEnable = false;

  ///是否启用拦截
  bool get isHookEnable => _hookEnable;

  OnSocketData _onData;

  int _st = 0;
  BehaviorSubject<int> _stateSub = BehaviorSubject<int>();

  Sink<int> get _stateSink => _stateSub.sink;

  Stream<int> get stateStream => _stateSub.stream;
  ValueNotifier<HttpArchive> _selectedHttpArchive =
      ValueNotifier<HttpArchive>(null);

  ValueNotifier<HttpArchive> get selectedHttpArchive => _selectedHttpArchive;

  final LinkedHashMap<String, HttpArchive> _httpArchives =
      LinkedHashMap<String, HttpArchive>();

  List<HttpArchive> get httpArchiveList =>
      _httpArchives.values.toList(growable: false);

  List<HttpArchive> get filteredHttpArchiveList {
    List<HttpArchive> list = <HttpArchive>[];
    httpArchiveList.forEach((element) {
      bool filtered = false; //被过滤
      if (_uriFilter != null &&
          _uriFilter.length > 0 &&
          !element.url.startsWith(_uriFilter)) {
        filtered = true;
      }
      if (_keywordFilter != null &&
          _keywordFilter.length > 0 &&
          !element.url.contains(_keywordFilter)) {
        filtered = true;
      }
      if (!filtered) {
        list.add(element);
      }
    });
    return list;
  }

  ///显示详情
  bool _showSelectedDetail = false;

  String _uriFilter;

  String get uriFilter => _uriFilter;

  String _keywordFilter;

  String get keywordFilter => _keywordFilter;

  ItemPicker<HttpArchive> _itemPicker;

  ItemPicker get itemPicker => _itemPicker;

  ///显示详情
  set showSelectedDetail(bool show) {
    _showSelectedDetail = show;
  }

  ///显示详情
  bool get showSelectedDetail =>
      _showSelectedDetail && _itemPicker.selectedCount > 0;

  HttpHookBloc(this.context) : super(context) {
    _hookConfigBloc = HookConfigBloc(context);
    _itemPicker = SingleItemPicker<HttpArchive>(context, tapToDeselect: false);
    _itemPicker.addListener(() {
      _selectedHttpArchive.value = _itemPicker.lastSelectItem;
    });
    //start hook
    setHookState(true);
    _loadHistory();
    //start listen
    debugPrint('create HttpHookBloc...');
    _webSocketBloc = BlocProvider.of<WebSocketBloc>(context).first;
    _onData = (msg) {
      try {
        HttpArchive archive = HttpArchive.fromJson(
            jsonDecode(utf8.decode(msg.data)) as Map<String, dynamic>);
        _httpArchives[archive.uuid] = archive;
        setState();
      } catch (e) {
        debugPrint(e);
      }
    };
    _webSocketBloc.registerSub('httphook', _onData);
  }

  @override
  void dispose() {
    debugPrint('dispose HttpHookBloc...');
    _stateSub.close();
    _hookConfigBloc.dispose();
    //stop listen
    _webSocketBloc?.unregisterSub('httphook', _onData);
  }

  ///设置拦截状态
  Future setHookState(bool enable) async {
    Uri uri = Uri.http(getHost(), '$PATH/toggle');
    var response = await httpPost(uri, body: {
      'enable': enable,
    });
    debugPrint('toggle HttpHook to $enable, response: ${response.body}');
    _reloadState();
    return Future.value();
  }

  ///加载历史记录
  Future _loadHistory() async {
    Uri uri = Uri.http(getHost(), '$PATH/history');
    var response = await httpGet(uri);
    Map<String, Object> jsonResponse = jsonDecode(response.body);
    List list = (jsonResponse['data'] as Map)['list'] as List;
    list.forEach((element) {
      HttpArchive archive = HttpArchive.fromJson(element);
      _httpArchives[archive.uuid] = archive;
    });
    setState();
    return Future.value();
  }

  ///重新加载状态
  Future _reloadState() async {
    Uri uri = Uri.http(getHost(), '$PATH/state');
    var response = await httpGet(uri);
    Map<String, Object> jsonResponse = jsonDecode(response.body);
    _hookEnable = (jsonResponse['data'] as Map)['enable'] as bool;
    setState();
    return Future.value();
  }

  ///url过滤
  void applyUriFilter(String uri) {
    if (_uriFilter != uri) {
      _uriFilter = uri;
      setState();
    }
    _checkFilter();
  }

  ///关键字过滤
  void applyKeywordFilter(String text) {
    if (_keywordFilter != text) {
      _keywordFilter = text;
      setState();
    }
    _checkFilter();
  }

  //如果选中的被过滤 则取消选中
  void _checkFilter() {
    if (_itemPicker.selectedCount > 0 &&
        !filteredHttpArchiveList.contains(_itemPicker.lastSelectItem)) {
      _itemPicker.clear();
    }
  }

  void setState([var f]) {
    _stateSink.add(++_st);
  }

  ///清除记录
  void clear() async {
    _itemPicker.clear();
    _httpArchives.clear();
    _showSelectedDetail = false;
    setState();

    //clear remote
    Uri uri = Uri.http(getHost(), '$PATH/clear');
    await httpPost(uri);
  }
}
