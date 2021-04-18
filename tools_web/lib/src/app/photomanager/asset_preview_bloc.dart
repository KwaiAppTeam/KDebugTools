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
import 'dart:math';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/web_http.dart';

import '../model.dart';
import 'photo_models.dart';

class AssetPreviewBloc extends AppBlocBase {
  static const String PATH = 'api/photo';

  AssetPreviewBloc(context) : super(context);

  @override
  void dispose() {}

  String networkPath(Asset asset) {
    return '${getHostWithSchema()}/$PATH/read?assetId=${asset.id}';
  }

  String networkPathWithToken(Asset asset) {
    return '${getHostWithSchema()}/$PATH/read?assetId=${asset.id}&Token=${getToken()}';
  }

  ///下载
  Future download(Asset asset) {
    var queryParameters = {
      'assetIds': Uri.encodeFull(asset.id),
      'Token': getToken()
    };
    Uri uri = Uri.http(getHost(), '$PATH/download', queryParameters);
    html.AnchorElement anchorElement =
        new html.AnchorElement(href: uri.toString());
    anchorElement.download = uri.toString();
    anchorElement.click();
    return Future.value();
  }

  ///删除
  Future delete(Asset asset) async {
    Uri uri = Uri.http(getHost(), '$PATH/delete');
    var response = await httpPost(uri, body: {
      'assetIds': [asset.id]
    });
    if (response.statusCode == 200) {
      Map<String, Object> jsonResponse = jsonDecode(response.body);
      List list = (jsonResponse['data'] as Map)['files'] as List<String>;
      return list;
    } else {
      return Future.error(
          ErrorResult.create('Error', jsonDecode(response.body)));
    }
  }
}
