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

import 'package:flutter/material.dart';

import '../http_models.dart';
import 'http_archive_list_page.dart';

class RequestWidget extends StatefulWidget {
  final HttpArchive httpArchive;

  RequestWidget(this.httpArchive);

  @override
  _RequestWidgetState createState() => _RequestWidgetState();
}

class _RequestWidgetState extends State<RequestWidget>
    with AutomaticKeepAliveClientMixin {
  HttpArchive get httpArchive => widget.httpArchive;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    int end = httpArchive.end;
    var requestTime =
        getDateTimeStr(DateTime.fromMillisecondsSinceEpoch(httpArchive.start));
    var responseTime = end != null
        ? getDateTimeStr(DateTime.fromMillisecondsSinceEpoch(end))
        : '';
    var duration = end != null ? (end - httpArchive.start) : 0;
    var body = HttpArchive.decodeBody(httpArchive.requestBody);
    var content = StringBuffer();
    content.write('url: ${httpArchive.url}\n');
    content.write('method: ${httpArchive.method.toUpperCase()}\n');
    content.write('requestTime: $requestTime\n');
    content.write('responseTime: $responseTime\n');
    content.write(
        'remoteAddress: ${httpArchive.requestConnectInfo?.remoteAddress ?? ''}:${httpArchive.requestConnectInfo?.remotePort ?? ''}\n');
    content.write('duration: ${duration}ms\n\n');
    content.write('headers: \n');
    content.write('${toJson(stripValue(httpArchive.requestHeaders))}\n\n');
    content.write('params: \n');
    content
        .write('${toJson(stripValue(httpArchive.uri.queryParametersAll))}\n\n');
    content.write('body: \n');
    if (isJsonStr(body)) {
      content.write(toJson(jsonDecode(body)));
    } else {
      content.write(body ?? '');
    }
    content.write('\n');

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          RaisedButton(
            onPressed: () {
              copyClipboard(context, content.toString());
            },
            child: Text('copy all'),
          ),
          Expanded(
            child: Scrollbar(
              child: SelectableText(content.toString()),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
