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
import 'package:k_debug_tools_web/src/app/dbview/db_events.dart';
import 'package:k_debug_tools_web/src/app_window_bloc.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/event_bus.dart';
import 'package:k_debug_tools_web/src/theme.dart';
import 'package:k_debug_tools_web/src/widgets/common_widgets.dart';
import 'package:k_debug_tools_web/src/widgets/split.dart';

import 'db_view_bloc.dart';
import 'widgets/db_sub_windows.dart';
import 'widgets/db_tree.dart';

class DbViewWindow extends StatefulWidget {
  @override
  _DbViewWindowState createState() => _DbViewWindowState();
}

class _DbViewWindowState extends State<DbViewWindow> {
  DbViewBloc _bloc;

  @override
  void dispose() {
    _bloc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _bloc ??= DbViewBloc(context);
    return BlocProvider(
      child: DbView(),
      blocs: [_bloc],
    );
  }
}

class DbView extends StatefulWidget {
  @override
  _DbViewState createState() => _DbViewState();
}

class _DbViewState extends State<DbView> {
  DbViewBloc _dbViewBloc;
  AppWindowBloc _windowBloc;

  @override
  void initState() {
    _dbViewBloc = BlocProvider.of<DbViewBloc>(context).first;
    _dbViewBloc.listFile(true);
    _windowBloc = BlocProvider.of<AppWindowBloc>(context).first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _dbViewBloc.stateStream,
      builder: (ctx, _) {
        return Padding(
          padding: EdgeInsets.all(densePadding),
          child: Split(
            axis: Axis.horizontal,
            initialFractions: const [0.33, 0.67],
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildActionsWidget(),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: densePadding),
                      child: Container(
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: Theme.of(context).focusColor)),
                          child: DbTreeWidget()),
                    ),
                  ),
                ],
              ),
              _buildRightWidget(),
            ],
          ),
        );
      },
    );
  }

  ///右边区域
  Widget _buildRightWidget() {
    return Column(
      children: <Widget>[
        Expanded(child: DbViewSubWindows()),
      ],
    );
  }

  ///actions
  Widget _buildActionsWidget() {
    return Row(
      children: <Widget>[
        //刷新
        ActionOutlinedButton(
          'Refresh',
          icon: Icons.refresh,
          enable: true,
          onTap: () {
            _dbViewBloc.listFile(true);
          },
        ),
        SizedBox(width: denseSpacing),
        //新查询
        ActionOutlinedButton(
          'New Query',
          icon: Icons.queue,
          enable: _dbViewBloc.currentDbFile != null,
          onTap: () {
            eventBus.fire(NewQueryClick(_dbViewBloc.currentDbFile));
          },
        ),
      ],
    );
  }
}
