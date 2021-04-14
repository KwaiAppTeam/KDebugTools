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
import 'package:flutter/services.dart';
import 'package:k_debug_tools/src/widgets/toast.dart';

class JsonView extends StatefulWidget {
  ///要展示的json数据
  final dynamic json;

  ///是否展开全部json
  final bool? isShowAll;

  final double fontSize;
  JsonView({
    this.json,
    this.isShowAll = false,
    this.fontSize = 14,
  });

  @override
  _JsonViewState createState() => _JsonViewState();
}

class _JsonViewState extends State<JsonView> {
  Map<String, bool?> showMap = Map();

  ///当前节点编号
  int currentIndex = 0;

  @override
  void didUpdateWidget(JsonView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isShowAll != widget.isShowAll) {
      _flexAll(widget.isShowAll);
    }
  }

  @override
  Widget build(BuildContext context) {
    currentIndex = 0;
    Widget w;
    JsonType type = getType(widget.json);
    if (type == JsonType.object) {
      w = _buildObject(widget.json);
    } else if (type == JsonType.array) {
      List? list = widget.json as List?;
      w = _buildArray(list, '');
    } else {
      var je = JsonEncoder.withIndent('  ');
      var json = je.convert(widget.json);
      return _getDefText(json);
    }
    return w;
  }

  ///构建object节点的展示
  Widget _buildObject(Map<String, dynamic>? json, {String? key}) {
    List<Widget> listW = [];

    ///增加一个节点
    currentIndex++;

    ///object节点
    Widget keyW;
    if (_isShow(currentIndex)) {
      keyW = _getDefText('${key == null ? '{' : '$key:{'}');
    } else {
      keyW = _getDefText('${key == null ? '{...}' : '$key:{...}'}');
    }
    listW.add(_wrapFlex(currentIndex, keyW));

    ///object展示内容
    if (_isShow(currentIndex)) {
      List<Widget> listObj = [];
      json!.forEach((k, v) {
        Widget w;
        JsonType type = getType(v);
        if (type == JsonType.object) {
          w = _buildObject(v, key: k);
        } else if (type == JsonType.array) {
          List list = v as List;
          w = _buildArray(list, k);
        } else {
          w = _buildKeyValue(v, k: k);
        }
        listObj.add(w);
      });

      listObj.add(_getDefText('},'));

      ///添加缩进
      listW.add(
        Padding(
          padding: EdgeInsets.only(left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: listObj,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: listW,
    );
  }

  ///构建array节点的展示
  Widget _buildArray(List? listJ, String key) {
    List<Widget> listW = [];

    ///增加一个节点
    currentIndex++;

    ///添加key的展示
    Widget keyW;
    if (key.isEmpty) {
      keyW = _getDefText('[');
    } else if (_isShow(currentIndex)) {
      keyW = _getDefText('$key:[');
    } else {
      keyW = _getDefText('$key:[...]');
    }

    ///添加key的点击事件
    ///添加key的展示
    listW.add(_wrapFlex(currentIndex, keyW));

    if (_isShow(currentIndex)) {
      List<Widget> listArr = [];
      listJ!.forEach((val) {
        var type = getType(val);
        Widget w;
        if (type == JsonType.object) {
          w = _buildObject(val);
        } else {
          w = _buildKeyValue(val);
        }
        listArr.add(w);
      });
      listArr.add(_getDefText(']'));

      ///添加缩进
      listW.add(
        Padding(
          padding: EdgeInsets.only(left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: listArr,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: listW,
    );
  }

  ///包裹展开按钮
  Widget _wrapFlex(int key, Widget keyW) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (key == 0) {
          _flexAll(!_isShow(key));
          setState(() {});
        }
        _flexSwitch(key.toString());
      },
      child: Row(
        children: <Widget>[
          Transform.rotate(
            angle: _isShow(key) ? 0 : 3.14 * 1.5,
            child: Icon(
              Icons.expand_more,
              size: 12,
            ),
          ),
          keyW,
        ],
      ),
    );
  }

  ///构建子节点的展示
  Widget _buildKeyValue(v, {k}) {
    Widget w = _getDefText(
        '${k ?? ''}:${v is String ? '"$v"' : v?.toString() ?? null},');
    if (k != null) {
      w = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: () {
          _copy(v);
        },
        child: w,
      );
    }
    return w;
  }

  ///json节点是否展示
  bool _isShow(int key) {
    ///说明是根节点
    if (key == 1) return true;
    if (widget.isShowAll!) {
      return showMap[key.toString()] ?? true;
    } else {
      return showMap[key.toString()] ?? false;
    }
  }

  ///展开合上的切换
  _flexSwitch(String key) {
    showMap.putIfAbsent(key, () => false);
    showMap[key] = !showMap[key]!;
    setState(() {});
  }

  ///展开合上所有
  _flexAll(bool? flex) {
    showMap.forEach((k, v) {
      showMap[k] = flex;
    });
  }

  ///判断value值的类型
  JsonType getType(dynamic json) {
    if (json is List) {
      return JsonType.array;
    } else if (json is Map<String, dynamic>) {
      return JsonType.object;
    } else {
      return JsonType.str;
    }
  }

  ///默认的文本大小
  Text _getDefText(String str) {
    return Text(
      str,
      style: TextStyle(fontSize: widget.fontSize),
    );
  }

  _copy(value) {
    Toast.showToast('copy success');
    Clipboard.setData(ClipboardData(text: value?.toString()));
  }
}

enum JsonType {
  object,
  array,
  str,
}
