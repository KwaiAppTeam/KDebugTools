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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_debug_tools/src/widgets/dialog.dart';

import '../../k_debug_tools.dart';
import 'common_widgets.dart';
import 'toast.dart';

///label-value 点击后执行clickCallback 或 复制value
class SimpleListInfoWidget extends StatelessWidget {
  final String label;
  final String value;
  final bool canCopy;
  final ActionCallback clickCallback;

  SimpleListInfoWidget(
      {@required this.label,
      this.value,
      this.canCopy = true,
      this.clickCallback});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (clickCallback != null) {
          clickCallback();
        }
      },
      onDoubleTap: () {
        if (canCopy) {
          Clipboard.setData(ClipboardData(text: value)).then((v) {
            Toast.showToast('${localizationOptions.copied} \n$value');
          });
        }
      },
      child: Container(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 48),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text(label ?? ''),
              SizedBox(
                width: 20,
              ),
              Expanded(
                  child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(value ?? '')))
            ],
          ),
        ),
      ),
    );
  }
}

///文本输入
class SimpleListInputWidget extends StatelessWidget {
  final String label;
  final ValueGetter<String> valueGetter;
  final ValueSetter<String> valueSetter;
  final TextInputType keyboardType;
  final bool enable;

  SimpleListInputWidget(
      {@required this.label,
      this.valueGetter,
      this.valueSetter,
      this.keyboardType,
      this.enable = true});

  @override
  Widget build(BuildContext context) {
    String value = valueGetter != null ? valueGetter() : '';
    return DefaultTextStyle(
      style: TextStyle(color: enable ? Colors.black : Colors.grey),
      child: Container(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 48),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text(label ?? ''),
              SizedBox(
                width: 20,
              ),
              Expanded(
                  child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        value ?? '',
                      ))),
              Visibility(
                visible: enable,
                child: GestureDetector(
                  onTap: () {
                    _showDialog(context);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Icon(
                    Icons.edit,
                    size: 24,
                    color: Colors.grey,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showDialog(BuildContext ctx) {
    if (!enable) {
      return;
    }
    showInputDialog(ctx,
            title: label,
            initValue: valueGetter() ?? '',
            inputType: keyboardType)
        .then((value) {
      if (value != null) {
        valueSetter(value);
      }
    });
  }
}

///label-toggle 开关功能
class SimpleListToggleWidget extends StatelessWidget {
  final String label;
  final ValueNotifier<bool> value;
  final ValueChanged<bool> onChanged;

  SimpleListToggleWidget({@required this.label, this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 48),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Text(label ?? ''),
            SizedBox(
              width: 20,
            ),
            Expanded(
                child: Align(
                    alignment: Alignment.centerRight,
                    child: ValueListenableBuilder(
                      valueListenable: value,
                      builder: (_, value, child) {
                        return Switch(
                          value: value,
                          onChanged: onChanged,
                        );
                      },
                    )))
          ],
        ),
      ),
    );
  }
}

///label-value 点击后出现选择对话框
class SimpleListSelectWidget extends StatelessWidget {
  final String label;
  final ValueGetter<int> valueGetter;
  final ValueSetter<int> valueSetter;
  final List<String> itemValues;

  SimpleListSelectWidget(
      {@required this.label,
      @required this.valueGetter,
      @required this.valueSetter,
      @required this.itemValues});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 48),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Text(label ?? ''),
            SizedBox(
              width: 20,
            ),
            Expanded(
                child: Align(
                    alignment: Alignment.centerRight,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                          value: '${valueGetter()}',
                          items: _buildItems(),
                          onChanged: (value) {
                            valueSetter(int.parse(value));
                          }),
                    )))
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildItems() {
    List<DropdownMenuItem<String>> items = List();
    if (itemValues != null && itemValues.isNotEmpty) {
      for (int i = 0; i < itemValues.length; i++) {
        items.add(DropdownMenuItem(
          child: Text(itemValues[i]),
          value: '$i',
        ));
      }
    }
    return items;
  }
}
