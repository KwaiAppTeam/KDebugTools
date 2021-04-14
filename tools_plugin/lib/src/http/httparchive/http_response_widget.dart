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
import 'json_view.dart';

class ResponseWidget extends StatefulWidget {
  final HttpArchive httpArchive;

  ResponseWidget(this.httpArchive);

  @override
  _ResponseWidgetState createState() => _ResponseWidgetState();
}

class _ResponseWidgetState extends State<ResponseWidget>
    with AutomaticKeepAliveClientMixin {
  bool? isShowAll = false;
  double fontSize = 14;

  HttpArchive get httpArchive => widget.httpArchive;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var jsonStr =
        widget.httpArchive.responseBodyString ?? '>>>preview not support<<<';
    var isJson = isJsonStr(jsonStr);

    var content = StringBuffer();
    content.write('headers: \n');
    content.write('${toJson(stripValue(httpArchive.responseHeaders))}\n\n');
    if (!isJson) {
      content.write(jsonStr);
    }

    return SingleChildScrollView(
        child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              RaisedButton(
                onPressed: () {
                  copyClipboard(context, jsonStr);
                },
                child: Text('copy json'),
              ),
              SizedBox(width: 10),
              Text(isShowAll! ? 'shrink all' : 'expand all'),
              Checkbox(
                value: isShowAll,
                onChanged: (check) {
                  isShowAll = check;
                  setState(() {});
                },
              ),
              Expanded(
                child: Slider(
                  value: fontSize,
                  max: 30,
                  min: 1,
                  onChanged: (v) {
                    fontSize = v;
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          SelectableText(
            content.toString(),
            style: TextStyle(fontSize: fontSize),
          ),
          isJson
              ? JsonView(
                  json: jsonDecode(jsonStr),
                  isShowAll: isShowAll,
                  fontSize: fontSize,
                )
              : Container(),
        ],
      ),
    ));
  }

  @override
  bool get wantKeepAlive => true;
}
