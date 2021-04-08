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
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/web_http.dart';

import '../model.dart';

class VideoPlayerBloc extends AppBlocBase {
  //路径和文件api一样
  static const String PATH = 'api/file';

  //文本文件路径
  final String filePath;

  bool _deleted = false;

  String get networkPath =>
      '${getHostWithSchema()}/$PATH/read$filePath?Token=${getToken()}';

  bool get canDownload => !_deleted && filePath != null;

  VideoPlayerBloc(context, this.filePath) : super(context);

  @override
  void dispose() {}

  bool get hasFilePath => filePath?.isNotEmpty == true;

  ///下载
  Future download() {
    var queryParameters = {
      'path': Uri.encodeFull(filePath),
    };
    Uri uri = Uri.http(getHost(), '$PATH/download', queryParameters);
    html.AnchorElement anchorElement =
        new html.AnchorElement(href: uri.toString());
    anchorElement.download = uri.toString();
    anchorElement.click();
    return Future.value();
  }

  ///删除
  Future delete() async {
    Uri uri = Uri.http(getHost(), '$PATH/delete');
    var response = await httpPost(uri, body: {
      'path': filePath,
    });
    if (response.statusCode == 200) {
      _deleted = true;
      return Future.value();
    } else {
      return Future.error(
          ErrorResult.create('Error', jsonDecode(response.body)));
    }
  }
}
