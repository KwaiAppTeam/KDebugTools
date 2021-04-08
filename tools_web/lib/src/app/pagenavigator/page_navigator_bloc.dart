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
import 'package:rxdart/rxdart.dart';
import 'package:k_debug_tools_web/src/app/pagenavigator/page_navigator_models.dart';
import 'package:k_debug_tools_web/src/app/uicheck/uicheck_models.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/web_http.dart';
import '../model.dart';

class PageNavigatorBloc extends AppBlocBase {
  static const String PATH = 'api/navigator';
  static const String UI_PATH = 'api/uicheck';

  Object _selectedNodeData;

  Object get selectedNodeData => _selectedNodeData;

  BehaviorSubject<Object> _selectNodeSub = BehaviorSubject<Object>();

  Sink<Object> get _selectNodeSink => _selectNodeSub.sink;

  Stream<Object> get selectNodeStream => _selectNodeSub.stream;

  FlutterCapture _flutterCapture;

  FlutterCapture get flutterCapture => _flutterCapture;

  NavigatorInfo _root;

  NavigatorInfo get root => _root;

  Uri get screenUri => Uri.parse(
      '${getHostWithSchema()}/$UI_PATH/${_flutterCapture?.screenshot}');

  PageNavigatorBloc(context) : super(context);

  ///拉数据
  Future fetchInfo() async {
    _root = null;
    _flutterCapture = null;
    _selectedNodeData = null;

    //获取路由信息
    Uri uri = Uri.http(getHost(), '$PATH/state');
    var response = await httpGet(uri);
    Map<String, Object> jsonResponse = jsonDecode(response.body);
    if (response.statusCode == 200) {
      _root = NavigatorInfo.fromJson((jsonResponse['data'] as Map));
    } else {
      return Future.error(
          ErrorResult.create('fetch data failed', jsonResponse));
    }

    //获取UI信息
    var uiResponse = await httpPost(Uri.http(getHost(), '$UI_PATH/capture'));
    if (uiResponse.statusCode == 200) {
      Map<String, Object> jsonResponse = jsonDecode(uiResponse.body);
      var data = (jsonResponse['data'] as Map);
      _flutterCapture = FlutterCapture.fromJson(data);
    } else {
      return Future.error(
          ErrorResult.create('Error', jsonDecode(uiResponse.body)));
    }

    return Future.value();
  }

  void setSelectNodeData(Object object) {
    _selectedNodeData = object;
    _selectNodeSink.add(object);
  }

  @override
  void dispose() {
    _selectNodeSub.close();
  }

  Future popRoute(RouteInfo info) async {
    var params = {
      'name': info.name,
    };
    Uri uri = Uri.http(getHost(), '$PATH/pop');
    var response = await httpPost(uri, body: params);
    if (response.statusCode == 200) {
      return Future.value();
    } else {
      return Future.error(
          ErrorResult.create('Error', jsonDecode(response.body)));
    }
  }

  Future pushRoute(String url, String navigatorName) async {
    var params = {'url': url, 'navigator': navigatorName};
    Uri uri = Uri.http(getHost(), '$PATH/push');
    var response = await httpPost(uri, body: params);
    if (response.statusCode == 200) {
      return Future.value();
    } else {
      return Future.error(
          ErrorResult.create('Error', jsonDecode(response.body)));
    }
  }
}
