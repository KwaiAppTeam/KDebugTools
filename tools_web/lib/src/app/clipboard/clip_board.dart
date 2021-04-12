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
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/widgets/common_widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../app_window_bloc.dart';
import 'clip_board_bloc.dart';

class ClipBoardWindow extends StatefulWidget {
  @override
  _ClipBoardWindowState createState() => _ClipBoardWindowState();
}

class _ClipBoardWindowState extends State<ClipBoardWindow> {
  ClipBoardBloc _bloc;

  @override
  void dispose() {
    _bloc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _bloc ??= ClipBoardBloc(context);
    return BlocProvider(
      child: ClipBoard(),
      blocs: [_bloc],
    );
  }
}

class ClipBoard extends StatefulWidget {
  @override
  _ClipBoardState createState() => _ClipBoardState();
}

class _ClipBoardState extends State<ClipBoard> {
  AppWindowBloc _windowBloc;
  ClipBoardBloc _clipBoardBloc;
  TextEditingController _editingController;

  @override
  void initState() {
    _windowBloc = BlocProvider.of<AppWindowBloc>(context).first;
    _clipBoardBloc = BlocProvider.of<ClipBoardBloc>(context).first;
    _editingController = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Column(
        children: <Widget>[
          //顶部菜单 action
          _buildActionWidget(),
          Expanded(child: _buildContentWidget()),
        ],
      ),
    );
  }

  ///文本内容区域
  Widget _buildContentWidget() {
    return Container(
      padding: EdgeInsets.all(4),
      child: Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).focusColor)),
          child: TextField(
            textAlign: TextAlign.start,
            showCursor: true,
            maxLines: null,
            style: TextStyle(fontSize: 14),
            decoration: null,
            controller: _editingController,
          )),
    );
  }

  ///action区域
  Widget _buildActionWidget() {
    return Container(
      padding: EdgeInsets.all(4),
      child: Row(
        children: <Widget>[
          ActionOutlinedButton(
            AppLocalizations.of(context).readClipboard,
            enable: true,
            onTap: () {
              _clipBoardBloc
                  .readFromDevice()
                  .then((value) => setState(() {
                        _editingController.text = value;
                      }))
                  .catchError((e) {
                _windowBloc
                    .toast(AppLocalizations.of(context).requestError('$e'));
              });
            },
          ),
          SizedBox(width: 8),
          ActionOutlinedButton(
            AppLocalizations.of(context).writeClipboard,
            enable: true,
            onTap: () {
              _clipBoardBloc
                  .writeToDevice(_editingController.text)
                  .then((value) => setState(() {}))
                  .catchError((e) {
                _windowBloc
                    .toast(AppLocalizations.of(context).requestError('$e'));
              });
            },
          )
        ],
      ),
    );
  }
}
