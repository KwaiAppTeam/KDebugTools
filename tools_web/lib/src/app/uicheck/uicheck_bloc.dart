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
import 'dart:html' as html;
import 'package:k_debug_tools_web/src/app/uicheck/uicheck_models.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/web_http.dart';

import '../model.dart';

class UiCheckBloc extends AppBlocBase {
  static const String PATH = 'api/uicheck';

  FlutterCapture _flutterCapture;

  Uri get _uri =>
      Uri.parse('${getHostWithSchema()}/$PATH/${_flutterCapture?.screenshot}');

  String get screenshotNetPath => _uri.toString();

  bool get hasScreenshot => (_flutterCapture?.screenshot?.isNotEmpty == true);

  double get deviceHeight => _flutterCapture?.screenHeight ?? 0;

  double get deviceWidth => _flutterCapture?.screenWidth ?? 0;

  double get paddingTop => _flutterCapture?.paddingTop ?? 0;

  double get paddingBottom => _flutterCapture?.paddingBottom ?? 0;

  WidgetNode get root => _flutterCapture?.rootWidget;

  UiCheckBloc(context) : super(context);

  @override
  void dispose() {}

  ///抓取
  Future capture() async {
    _flutterCapture = null;
    Uri uri = Uri.http(getHost(), '$PATH/capture');
    var response = await httpPost(uri);
    if (response.statusCode == 200) {
      //记录时间
      Map<String, Object> jsonResponse = jsonDecode(response.body);
      var data = (jsonResponse['data'] as Map);
      _flutterCapture = FlutterCapture.fromJson(data);
      return Future.value();
    } else {
      return Future.error(
          ErrorResult.create('Error', jsonDecode(response.body)));
    }
  }

  ///下载图片
  Future downloadScreenshot() {
    html.AnchorElement anchorElement =
        new html.AnchorElement(href: _uri.toString());
    anchorElement.href = _uri.toString();
    anchorElement.download = '${_flutterCapture?.screenshot}';
    anchorElement.click();
    return Future.value();
  }

  Future openScreenshotInNewTab() {
    html.window.open(_uri.toString(), '${_flutterCapture?.screenshot}');
    return Future.value();
  }
}
