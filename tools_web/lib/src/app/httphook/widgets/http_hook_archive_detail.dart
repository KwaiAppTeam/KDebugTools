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
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:k_debug_tools_web/src/app/httphook/http_hook_bloc.dart';
import 'package:k_debug_tools_web/src/app/httphook/http_models.dart';
import 'package:k_debug_tools_web/src/app/httphookconfig/hook_config_models.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/theme.dart';

///请求详情
class ArchiveDetailWidget extends StatefulWidget {
  final HttpArchive archive;

  const ArchiveDetailWidget({Key key, this.archive}) : super(key: key);

  @override
  _ArchiveDetailWidgetState createState() => _ArchiveDetailWidgetState();
}

class _ArchiveDetailWidgetState extends State<ArchiveDetailWidget> {
  HttpHookBloc _httpHookBloc;

  List<String> _tabs = ['Overview', 'Request', 'Response', 'HookConfig'];

  PageController _pageController;
  int _pageIndex = 0;

  HttpArchive get archive => widget.archive;

  @override
  void initState() {
    _pageController =
        PageController(initialPage: this._pageIndex, keepPage: false);
    _httpHookBloc = BlocProvider.of<HttpHookBloc>(context).first;
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_httpHookBloc.showSelectedDetail || archive == null) {
      return Container();
    } else {
      ThemeData theme = Theme.of(context);
      return Column(
        children: <Widget>[
          Container(
              height: 30,
              color: titleSolidBackgroundColor(theme),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildTabWidget(),
              )),
          Expanded(
            child: DefaultTextStyle(
              style: theme.textTheme.bodyText2,
              child: PageView(
                physics: NeverScrollableScrollPhysics(),
                controller: _pageController,
                children: _buildTabViewWidget(),
              ),
            ),
          )
        ],
      );
    }
  }

  ///构建tab
  List<Widget> _buildTabWidget() {
    ThemeData theme = Theme.of(context);
    List<Widget> r = <Widget>[];
    for (int i = 0; i < _tabs.length; i++) {
      r.add(GestureDetector(
        onTap: () {
          setState(() {
            _pageIndex = i;
            _pageController.jumpToPage(_pageIndex);
          });
        },
        child: Container(
            padding: EdgeInsets.only(left: densePadding, right: densePadding),
            child: Stack(children: [
              Center(
                child: Text(_tabs[i]),
              ),
              Positioned(
                  height: 2,
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: i == _pageIndex ? theme.indicatorColor : null,
                  ))
            ])),
      ));
    }
    return r;
  }

  ///构建tab view
  List<Widget> _buildTabViewWidget() {
    return [
      _buildOverviewWidget(),
      _buildRequestWidget(),
      _buildResponseWidget(),
      _buildReadOnlyTextField(_formatHookConfig(archive.hookConfig)),
    ].toList(growable: false);
  }

  ///总览
  Widget _buildOverviewWidget() {
    StringBuffer str = StringBuffer();
    str.write(archive.method);
    str.write(' ');
    str.write(archive.url);
    str.writeln('\n\nRequest Header');
    archive.requestHeaders?.forEach((key, value) {
      value?.forEach((element) {
        str.write('\n$key:$element');
      });
    });

    str.writeln('\n\nResponse Header');
    archive.responseHeaders?.forEach((key, value) {
      value?.forEach((element) {
        str.write('\n$key:$element');
      });
    });
    return _buildReadOnlyTextField(str.toString());
  }

  ///请求
  Widget _buildRequestWidget() {
    return _buildReadOnlyTextField(archive.requestBodyString);
  }

  ///响应
  Widget _buildResponseWidget() {
    ContentType contentType = ContentType.parse(archive.responseContentType);
    if (contentType.primaryType == ContentType.text.primaryType ||
        contentType.subType == ContentType.json.subType) {
      //text
      return _buildReadOnlyTextField(archive.responseBodyString);
    } else if (contentType.primaryType?.toLowerCase() == 'image' &&
        archive.responseBody != null) {
      //image
      return Image.memory(archive.responseBody);
    } else {
      return _buildReadOnlyTextField('preview not support');
    }
  }

  Widget _buildReadOnlyTextField(String text) {
    String str = text;
    try {
      //试试转json
      str = JsonEncoder.withIndent('  ').convert(jsonDecode(text));
    } catch (e) {
      str = text;
    }
    return Scrollbar(
      child: SelectableText(
        str ?? '',
      ),
    );
  }

  String _formatHookConfig(HookConfig config) {
    StringBuffer buffer = StringBuffer();
    if (config != null) {
      buffer.write('ConfigId: ${config.id}\n');
      buffer.write('UriPattern: ${config.uriPattern}\n');

      //目前才只支持这两个
      if (config.mapRemote) {
        buffer.write('mapRemote: true\n');
        buffer.write('mapRemoteUrl:\n\n${config.mapRemoteUrl}\n');
      }
      if (config.mapLocal) {
        buffer.write('mapLocal: true\n');
        buffer.write('mapLocalBody:\n\n${config.mapLocalBody}\n');
      }
    }
    return buffer.toString();
  }
}
