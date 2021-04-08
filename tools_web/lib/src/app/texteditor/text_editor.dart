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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';

import 'package:k_debug_tools_web/src/widgets/common_widgets.dart';

import '../../app_window_bloc.dart';
import '../../theme.dart';
import 'text_editor_bloc.dart';

class TextEditorWindow extends StatefulWidget {
  final String filePath;

  TextEditorWindow({Key key, this.filePath}) : super(key: key);

  @override
  _TextEditorWindowState createState() => _TextEditorWindowState();
}

class _TextEditorWindowState extends State<TextEditorWindow> {
  TextEditorBloc _bloc;

  @override
  void dispose() {
    _bloc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _bloc ??= TextEditorBloc(context, widget.filePath);
    return BlocProvider(
      child: TextEditor(),
      blocs: [_bloc],
    );
  }
}

class TextEditor extends StatefulWidget {
  @override
  _TextEditorState createState() => _TextEditorState();
}

class _TextEditorState extends State<TextEditor> {
  AppWindowBloc _windowBloc;
  TextEditorBloc _editorBloc;
  TextEditingController _editingController;

  @override
  void initState() {
    _windowBloc = BlocProvider.of<AppWindowBloc>(context).first;
    _editorBloc = BlocProvider.of<TextEditorBloc>(context).first;
    _editingController = TextEditingController();
    if (_editorBloc.hasFilePath) {
      _editorBloc.read().then((value) {
        _editingController = TextEditingController(text: value);
        setState(() {});
      }).catchError((e) {
        _windowBloc.toast('load file error: $e');
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(densePadding),
      child: Column(
        children: <Widget>[
          //顶部菜单 action
          _buildActionWidget(),
          SizedBox(
            height: denseSpacing,
          ),
          Expanded(
              child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).focusColor)),
                  child: _buildContentWidget())),
        ],
      ),
    );
  }

  ///日志内容区域
  Widget _buildContentWidget() {
    return Scrollbar(
      child: Padding(
        padding: EdgeInsets.all(4),
        child: TextField(
          expands: true,
          textAlign: TextAlign.start,
          showCursor: true,
          keyboardType: TextInputType.multiline,
          maxLines: null,
          style: TextStyle(fontSize: 14),
          decoration: null,
          controller: _editingController,
        ),
      ),
    );
  }

  ///action区域
  Widget _buildActionWidget() {
    return Container(
      child: Row(
        children: <Widget>[
          ActionOutlinedButton(
            'Save',
            icon: Icons.save,
            enable: _editorBloc.hasFilePath,
            onTap: () {
              _editorBloc.save(_editingController.text).then((value) {
                _windowBloc.toast('保存成功');
              }).catchError((e) {
                _windowBloc.toast('保存失败 $e');
              });
            },
          ),
          SizedBox(
            width: densePadding,
          ),
          ActionOutlinedButton(
            'FormatJson',
            enable: true,
            onTap: _formatJson,
          ),
          SizedBox(
            width: densePadding,
          ),
          ActionOutlinedButton(
            'UrlEncode',
            enable: true,
            onTap: _urlEncode,
          ),
          SizedBox(
            width: densePadding,
          ),
          ActionOutlinedButton(
            'UrlDecode',
            enable: true,
            onTap: _urlDecode,
          ),
        ],
      ),
    );
  }

  void _formatJson() {
    String str = _editingController.text;
    try {
      //试试转json
      str = JsonEncoder.withIndent('  ').convert(jsonDecode(str));
      _editingController.text = str;
      setState(() {});
    } on FormatException catch (e) {
      _windowBloc.toast('Error: $e');
    }
  }

  void _urlEncode() {
    String str = _editingController.text;
    try {
      str = Uri.encodeFull(str);
      _editingController.text = str;
      setState(() {});
    } on FormatException catch (e) {
      _windowBloc.toast('Error: $e');
    }
  }

  void _urlDecode() {
    String str = _editingController.text;
    try {
      str = Uri.decodeFull(str);
      _editingController.text = str;
      setState(() {});
    } on FormatException catch (e) {
      _windowBloc.toast('Error: $e');
    }
  }
}
