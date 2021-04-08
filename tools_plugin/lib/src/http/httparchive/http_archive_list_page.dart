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
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_debug_tools/src/http/httphook/http_hook_controller.dart';
import 'package:k_debug_tools/src/http/httphook/http_throttle_controller.dart';
import 'package:k_debug_tools/src/widgets/toast.dart';
import 'package:k_debug_tools/src/widgets/transparent_route.dart';

import '../http_models.dart';
import 'http_archive_detail_page.dart';

///网络请求日志列表
class HttpArchiveListPage extends StatefulWidget {
  @override
  _HttpArchiveListPageState createState() => _HttpArchiveListPageState();
}

///过滤
String _methodFilter = '';
String _urlFilter = '';

class _HttpArchiveListPageState extends State<HttpArchiveListPage> {
  TextEditingController _filterEditingController;

  @override
  void initState() {
    _filterEditingController = TextEditingController();
    _filterEditingController.text = _urlFilter;
    _filterEditingController.addListener(() {
      _urlFilter = _filterEditingController.text;
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var _archives = HttpHookController.instance.httpArchives.reversed;
    int hookConfigCount = HttpHookController.instance.hookConfigs.length;
    var summary = '$hookConfigCount 配置 / ${_archives.length} 请求记录';
    var filteredArchives = _archives.where((element) {
      var urlFilter = _urlFilter.toLowerCase();
      var methodFilter = _methodFilter?.toLowerCase() ?? '';
      var method = element.method.toLowerCase();
      bool urlF =
          urlFilter.isEmpty || element.url.toLowerCase().contains(urlFilter);
      bool methodF = methodFilter.isEmpty ||
          method == methodFilter ||
          (methodFilter == 'other' && method != 'post' && method != 'get');
      return urlF && methodF;
    }).toList();
    var widgets = <Widget>[];
    //bar
    widgets.add(Container(
      height: 36,
      padding: EdgeInsets.only(left: 4, right: 4),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HttpHookController.instance
                  .setEnable(!HttpHookController.instance.enableHook.value);
            },
            child: ValueListenableBuilder(
              valueListenable: HttpHookController.instance.enableHook,
              builder: (ctx, value, _) {
                return SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    value ? Icons.stop : Icons.play_arrow,
                    color: value ? Color(0xffba5b54) : Color(0xff5f995c),
                  ),
                );
              },
            ),
          ),
          SizedBox(width: 4),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HttpHookController.instance.clearArchive();
              HttpThrottleController.instance.resetStatistics();
              setState(() {});
            },
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(Icons.delete),
            ),
          ),
          SizedBox(width: 4),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {});
            },
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(Icons.refresh),
            ),
          ),
          SizedBox(width: 4),
          Expanded(
              child:
                  Align(alignment: Alignment.centerRight, child: Text(summary)))
        ],
      ),
    ));
    widgets.add(Divider(height: 2));
    //filter
    widgets.add(Container(
      height: 36,
      padding: EdgeInsets.only(left: 12, right: 12),
      child: Row(
        children: [
          Text('UrlFilter:'),
          Expanded(
              child: Container(
            alignment: Alignment.center,
            color: Colors.black12,
            margin: EdgeInsets.fromLTRB(4, 0, 4, 0),
            padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
            height: 30,
            child: TextField(
              autofocus: false,
              focusNode: FocusNode(),
              maxLines: 1,
              textAlign: TextAlign.start,
              showCursor: true,
              style: TextStyle(fontSize: 12),
              decoration: null,
              controller: _filterEditingController,
            ),
          )),
          _buildMethodWidget('Get'),
          _buildMethodWidget('Post'),
          _buildMethodWidget('Other'),
        ],
      ),
    ));
    widgets.add(Divider(height: 2));
    //list
    widgets.add(Expanded(
      child: MediaQuery.removePadding(
        removeTop: true,
        context: context,
        child: ListView.separated(
          itemCount: filteredArchives.length,
          itemBuilder: (BuildContext context, int index) {
            return _buildItem(filteredArchives.elementAt(index));
          },
          separatorBuilder: (BuildContext context, int index) {
            return Divider(height: 1, color: Colors.black);
          },
        ),
      ),
    ));
    return Column(
      children: widgets,
    );
  }

  Widget _buildMethodWidget(String method) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _methodFilter = method;
        setState(() {});
      },
      child: Container(
        alignment: Alignment.center,
        width: 40,
        height: 24,
        color: _methodFilter == method
            ? Colors.blue.withOpacity(0.5)
            : Colors.white,
        child: Text(method),
      ),
    );
  }

  Widget _buildItem(HttpArchive item) {
    ///格式化请求时间
    var requestTime =
        getTimeStr(DateTime.fromMillisecondsSinceEpoch(item.start));
    var duration = (item.end ?? 0) - (item.start ?? 0);
    duration = max(duration, 0);
    //todo 被修改的、错误的使用不同颜色区分
    Color textColor = Colors.black;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.push(context,
            TransparentCupertinoPageRoute(builder: (context) {
          return HttpArchiveDetailPage(item);
        }));
      },
      child: Container(
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${item.statusCode} / ${item.method.toUpperCase()} / $requestTime / ${duration}ms / ${((item.responseLength ?? 0) / 1024).toStringAsFixed(3)}KB',
              style: TextStyle(
                color: textColor,
              ),
            ),
            Divider(height: 2),
            Text(
              '${item.url}',
              style: TextStyle(
                color: textColor,
              ),
            )
          ],
        ),
      ),
    );
  }
}

String getTimeStr(DateTime dateTime) {
  return "${twoNum(dateTime.hour)}:${twoNum(dateTime.minute)}:${twoNum(dateTime.second)}.${dateTime.millisecond}";
}

///转成两位数
String twoNum(int num) {
  return num > 9 ? num.toString() : "0$num";
}

String getDateTimeStr(DateTime dateTime) {
  return "${twoNum(dateTime.year)}.${twoNum(dateTime.month)}.${twoNum(dateTime.day)}-"
      "${twoNum(dateTime.hour)}:${twoNum(dateTime.minute)}:${twoNum(dateTime.second)}.${dateTime.millisecond}";
}

copyClipboard(BuildContext context, String value) {
  Toast.showToast('copy success');
  Clipboard.setData(ClipboardData(text: value));
}

toJson(dynamic data) {
  var je = JsonEncoder.withIndent('  ');
  var json = je.convert(data);
  return json;
}

bool isJsonStr(String data) {
  try {
    jsonDecode(data);
    return true;
  } catch (e) {
    return false;
  }
}

Map<String, dynamic> stripValue(Map<String, List<String>> map) {
  return map?.map((key, value) {
    return MapEntry(
        key, value.isEmpty ? null : (value.length == 1 ? value.first : value));
  });
}
