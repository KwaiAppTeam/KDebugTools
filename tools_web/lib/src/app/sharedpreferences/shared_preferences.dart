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
import 'package:k_debug_tools_web/src/app_window_bloc.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/theme.dart';
import 'package:k_debug_tools_web/src/widgets/common_widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'shared_preferences_bloc.dart';
import 'shared_preferences_models.dart';

class SharedPreferencesWindow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      child: SharedPreferencesWidget(),
      blocs: [SharedPreferencesBloc(context)],
    );
  }
}

class SharedPreferencesWidget extends StatefulWidget {
  @override
  _SharedPreferencesWidgetState createState() =>
      _SharedPreferencesWidgetState();
}

class _SharedPreferencesWidgetState extends State<SharedPreferencesWidget> {
  SharedPreferencesBloc _spBloc;
  AppWindowBloc _windowBloc;

  @override
  void initState() {
    _spBloc = BlocProvider.of<SharedPreferencesBloc>(context).first;
    _windowBloc = BlocProvider.of<AppWindowBloc>(context).first;
    _spBloc.initData().then((v) {
      setState(() {});
    });
    super.initState();
  }

  ///开始编辑
  void _startEdit(SpModel model) {
    _editingController =
        TextEditingController.fromValue(TextEditingValue(text: model.value));
    _spBloc.markEditing(model);
    setState(() {});
  }

  ///开始添加 todo
  void _startAdd() {}

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[_buildTreeWidget(), Expanded(child: _buildList())],
      ),
    );
  }

  ///树形目录结构 //todo 为多文件留扩展
  Widget _buildTreeWidget() {
    return Container();
  }

  Widget _buildList() {
    return Container(
        child: Column(
      children: <Widget>[
        _buildActionBar(),
        Expanded(child: _buildRightListWidget()),
      ],
    ));
  }

  ///右边action区域
  Widget _buildActionBar() {
    return Container(
      height: 30,
      color: actionBarBackgroundColor(Theme.of(context)),
      child: Row(
        children: <Widget>[
          ActionIcon(
            Icons.refresh,
            tooltip: AppLocalizations.of(context).refresh,
            onTap: () {
              _spBloc.reload().then((v) {
                _windowBloc.toast(AppLocalizations.of(context).success);
                setState(() {});
              }).catchError((e) {
                _windowBloc.toast(AppLocalizations.of(context).requestError(e));
              });
            },
          ),
          ActionIcon(
            Icons.add,
            tooltip: 'Add',
            enable: false, //todo
            onTap: () {
              _startAdd();
            },
          ),
          ActionIcon(
            Icons.edit,
            tooltip: 'Edit',
            enable: _spBloc.hasFocused,
            onTap: () {
              _startEdit(_spBloc.focusItem);
            },
          ),
          ActionIcon(
            Icons.delete,
            tooltip: 'Delete',
            enable: _spBloc.hasFocused,
            onTap: _actionDeleteFocused,
          ),
        ],
      ),
    );
  }

  ///删除选中
  void _actionDeleteFocused() {
    _windowBloc.showDialog(msg: AppLocalizations.of(context).deleteSelectedItems, actions: [
      DialogAction(
          text: AppLocalizations.of(context).confirm,
          handler: (ctrl) {
            ctrl.dismiss();
            _spBloc.deleteFocused().then((value) {
              _windowBloc.toast(AppLocalizations.of(context).success);
              _spBloc.reload().then((value) {
                setState(() {});
              });
            }).catchError((e) {
              _windowBloc.toast(AppLocalizations.of(context).requestError(e));
            });
          },
          isPositive: true),
      DialogAction(
          text: AppLocalizations.of(context).cancel,
          handler: (ctrl) {
            ctrl.dismiss();
          },
          isPositive: false)
    ]);
  }

  ///右边列表内容
  Widget _buildRightListWidget() {
    ThemeData theme = Theme.of(context);
    List<SpModel> items = _spBloc.items;
    return ListView.separated(
      controller: ScrollController(),
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        return _buildListWidgetItem(theme, index, items[index]);
      },
      separatorBuilder: (BuildContext context, int index) {
        return Divider(height: 1, color: Colors.transparent);
      },
    );
  }

  Widget _buildListWidgetItem(ThemeData theme, int index, SpModel model) {
    bool isFocused = _spBloc.isFocused(model);
    return Container(
      constraints: BoxConstraints(minHeight: 30),
      color: isFocused ? theme.colorScheme.selectedListRowBackgroundColor : Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!isFocused) {
            _spBloc.markFocused(model);
            _spBloc.markEditing(null);
            setState(() {});
          }
        },
        child: ListRow(
          separatorBuilder: (ctx, i) {
            return Container(width: 1, height: 30, color: theme.focusColor);
          },
          childPadding: EdgeInsets.only(left: 8, right: 8),
          children: <Widget>[
            Icon(
              Icons.label,
              size: defaultIconSize,
            ),
            Expanded(
              flex: 3,
              child: Text(
                model.key ?? '',
              ),
            ),
            Container(
              width: 60,
              child: Text(
                model.valueType ?? '',
              ),
            ),
            Expanded(
              flex: 3,
              child: _spBloc.isEditing(model)
                  ? _buildValueInput(model)
                  : Text(
                      model.value ?? '',
                    ),
            )
          ],
        ),
      ),
    );
  }

  TextEditingController _editingController;

  ///value输入
  Widget _buildValueInput(SpModel model) {
    if (_editingController == null) {
      _editingController =
          TextEditingController.fromValue(TextEditingValue(text: model.value));
    }

    void finishEdit() {
      _spBloc.markEditing(null);
      _editingController = null;
      _spBloc.reload().then((value) {
        setState(() {});
      });
    }

    return ListValueInputWidget(_editingController, (text) {
      _spBloc.commitEditingValue(text).then((v) {
        finishEdit();
      });
    }, () {
      //cancel
      finishEdit();
    });
  }
}
