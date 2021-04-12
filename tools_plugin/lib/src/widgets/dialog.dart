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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../k_debug_tools.dart';

///显示菜单对话框 类似右键菜单, Future返回选中的第x项, null没选中
Future<int> showContextMenuDialog(
  BuildContext ctx,
  List<String> options, {
  String title,
}) {
  List<Widget> _optionWidget(BuildContext context) {
    List<Widget> result = List<Widget>();
    for (int i = 0; i < options.length; i++) {
      String str = options[i];
      result.add(GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.pop(context, options.indexOf(str));
        },
        child: Container(
          height: 50,
          padding: EdgeInsets.only(left: 8, right: 8),
          child: Text(
            str,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ));
    }
    return result;
  }

  return showDialog<int>(
      context: ctx,
      barrierDismissible: true,
      builder: (BuildContext context) => SimpleDialog(
            title: title == null
                ? null
                : Container(
                    padding: EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                            bottom:
                                BorderSide(width: 1, color: Colors.black26))),
                    child: Text(title)),
            children: _optionWidget(context),
            titlePadding: EdgeInsets.all(10),
            contentPadding: EdgeInsets.all(2),
          ));
}

///显示输入框对话框
Future<String> showInputDialog(BuildContext ctx,
    {String title = '',
    String initValue = '',
    TextInputType inputType = TextInputType.text}) {
  TextEditingController _editingController =
      TextEditingController.fromValue(TextEditingValue(text: initValue));
  return showDialog<String>(
      context: ctx,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
            title: Text(title),
            content: Container(
              child: TextField(
                keyboardType: inputType,
                controller: _editingController,
              ),
            ),
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  Navigator.pop(context, _editingController.text);
                },
                child: Text(localizationOptions.dialogConfirm),
              ),
              FlatButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(localizationOptions.dialogCancel),
              ),
            ],
          ));
}
