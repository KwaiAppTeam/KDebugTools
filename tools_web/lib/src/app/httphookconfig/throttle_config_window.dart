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
import 'package:k_debug_tools_web/src/app/httphookconfig/hook_config_bloc.dart';
import 'package:k_debug_tools_web/src/app/httphookconfig/hook_config_models.dart';
import 'package:k_debug_tools_web/src/app_window_bloc.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/theme.dart';
import 'package:k_debug_tools_web/src/widgets/common_widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

///限流配置
class ThrottleConfigWindow extends StatefulWidget {
  @override
  _ThrottleConfigWindowState createState() => _ThrottleConfigWindowState();
}

class _ThrottleConfigWindowState extends State<ThrottleConfigWindow> {
  HookConfigBloc _hookConfigBloc;
  AppWindowBloc _windowBloc;
  ThrottleConfig _config;
  TextEditingController _upController;
  TextEditingController _downController;

  @override
  void initState() {
    _upController = TextEditingController();
    _downController = TextEditingController();

    _hookConfigBloc = BlocProvider.of<HookConfigBloc>(context).first;
    _windowBloc = BlocProvider.of<AppWindowBloc>(context).first;
    _hookConfigBloc.loadThrottleConfig().then((value) {
      _config = value;
      _upController.text = _config.upKb?.toString() ?? '';
      _downController.text = _config.downKb?.toString() ?? '';
      setState(() {});
    }).catchError((e) {
      _windowBloc.toast(AppLocalizations.of(context).requestError(e));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_config == null) {
      return Container();
    }
    return Container(
      padding: EdgeInsets.all(densePadding),
      child: Column(
        children: <Widget>[
          //顶部菜单 action
          _buildActionWidget(),
          SizedBox(
            height: 4,
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _config.limitUp,
                      onChanged: (v) {
                        _config.limitUp = v;
                        setState(() {});
                      },
                    ),
                    SizedBox(width: 100, child: Text('Upload:')),
                    Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          border:
                              Border.all(color: Theme.of(context).focusColor)),
                      margin: EdgeInsets.fromLTRB(4, 0, 4, 0),
                      padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                      width: 60,
                      height: 25,
                      child: TextField(
                        enabled: _config.limitUp,
                        textAlign: TextAlign.start,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        showCursor: true,
                        style: TextStyle(fontSize: 14),
                        decoration: null,
                        controller: _upController,
                      ),
                    ),
                    Text('KB/s'),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _config.limitDown,
                      onChanged: (v) {
                        _config.limitDown = v;
                        setState(() {});
                      },
                    ),
                    SizedBox(width: 100, child: Text('Download:')),
                    Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          border:
                              Border.all(color: Theme.of(context).focusColor)),
                      margin: EdgeInsets.fromLTRB(4, 0, 4, 0),
                      padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                      width: 60,
                      height: 25,
                      child: TextField(
                        enabled: _config.limitDown,
                        textAlign: TextAlign.start,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        showCursor: true,
                        style: TextStyle(fontSize: 14),
                        decoration: null,
                        controller: _downController,
                      ),
                    ),
                    Text('KB/s'),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  ///action区域
  Widget _buildActionWidget() {
    return Container(
      child: Row(
        children: <Widget>[
          ActionOutlinedButton(
            AppLocalizations.of(context).save,
            icon: Icons.save_rounded,
            enable: _config != null,
            onTap: () {
              _config.upKb = int.tryParse(_upController.text) ?? 50;
              _config.downKb = int.tryParse(_downController.text) ?? 50;
              _hookConfigBloc.saveThrottleConfig(_config).then((value) {
                _windowBloc.toast(AppLocalizations.of(context).success);
              }).catchError((e) {
                _windowBloc.toast(AppLocalizations.of(context).requestError(e));
              });
            },
          )
        ],
      ),
    );
  }
}
