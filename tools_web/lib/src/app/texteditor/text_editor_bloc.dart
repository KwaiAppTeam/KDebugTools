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
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/web_http.dart';

import '../model.dart';

class TextEditorBloc extends AppBlocBase {
  //路径和文件api一样
  static const String PATH = 'api/file';

  //文本文件路径
  final String filePath;

  TextEditorBloc(context, this.filePath) : super(context);

  @override
  void dispose() {}

  bool get hasFilePath => filePath?.isNotEmpty == true;

  ///读取文件
  Future<String> read() async {
    if (!hasFilePath) {
      return Future.error('no file path specified');
    } else {
      Uri uri = Uri.http(getHost(), '$PATH/read$filePath');
      var response = await httpGet(uri);
      if (response.statusCode == 200) {
        return Future.value(response.body);
      } else {
        return Future.error(
            ErrorResult.create('Error', jsonDecode(response.body)));
      }
    }
  }

  ///保存
  Future save(String text) async {
    var queryParameters = {
      'path': Uri.encodeFull(filePath),
    };
    Uri uri = Uri.http(getHost(), '$PATH/save', queryParameters);
    var response = await httpPost(uri, body: text);
    if (response.statusCode == 200) {
      return Future.value();
    } else {
      return Future.error(
          ErrorResult.create('Error', jsonDecode(response.body)));
    }
  }
}
