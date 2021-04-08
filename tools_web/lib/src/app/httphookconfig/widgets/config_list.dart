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

import 'package:flutter/material.dart';
import 'package:k_debug_tools_web/src/app/httphookconfig/hook_config_bloc.dart';
import 'package:k_debug_tools_web/src/app/httphookconfig/hook_config_models.dart';

import 'package:k_debug_tools_web/src/web_bloc.dart';
import 'package:k_debug_tools_web/src/widgets/common_widgets.dart';

import '../../../app_window_bloc.dart';
import '../../../bloc_provider.dart';
import '../../app_register.dart';
import 'config_window.dart';
import 'map_local_edit.dart';
import 'map_remote_edit.dart';

///列表
class ConfigListWidget extends StatefulWidget {
  final ConfigType configType;

  const ConfigListWidget({Key key, @required this.configType})
      : super(key: key);

  @override
  _ConfigListWidgetState createState() => _ConfigListWidgetState();
}

class _ConfigListWidgetState extends State<ConfigListWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  WebBloc _webBloc;
  HookConfigBloc _configBloc;
  AppWindowBloc _windowBloc;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    _webBloc = BlocProvider.of<WebBloc>(context).first;
    _windowBloc = BlocProvider.of<AppWindowBloc>(context).first;
    _configBloc = BlocProvider.of<HookConfigBloc>(context).first;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ThemeData theme = Theme.of(context);
    return LayoutBuilder(
      builder: (_, constraints) {
        return Scrollbar(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                    minHeight: constraints.maxHeight),
                child: DataTable(
                  columnSpacing: 4,
                  headingRowHeight: 30,
                  dataRowHeight: 32,
                  showCheckboxColumn: false,
                  headingTextStyle:
                      theme.textTheme.subtitle2.copyWith(fontSize: 12),
                  dataTextStyle:
                      theme.textTheme.subtitle2.copyWith(fontSize: 12),
                  columns: [
                    DataColumn(label: Text('')),
                    DataColumn(label: Text('Id')),
                    DataColumn(label: Text('Enable')),
                    DataColumn(label: Text('MapUrl'))
                  ],
                  rows: _buildRow(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<DataRow> _buildRow() {
    List<DataRow> rows = <DataRow>[];
    List<HookConfig> list = _configBloc.configs;
    for (int i = 0; i < list.length; i++) {
      HookConfig config = list.elementAt(i);
      bool canAdd = false;
      if (widget.configType == ConfigType.mapLocal && config.mapLocal) {
        canAdd = true;
      }
      if (widget.configType == ConfigType.mapRemote && config.mapRemote) {
        canAdd = true;
      }
      if (canAdd) {
        rows.add(DataRow.byIndex(
            index: i,
            selected: false,
            color: null,
            cells: _createRowCells(i, config)));
      }
    }

    return rows;
  }

  List<DataCell> _createRowCells(int row, HookConfig config) {
    List<DataCell> cells = <DataCell>[];
    TextStyle style = Theme.of(context).textTheme.bodyText2;
    if (!config.enable) {
      style = style.copyWith(color: style.color.withOpacity(0.5));
    }
    GlobalKey key = GlobalKey();
    cells.add(
      DataCell(
        GestureDetector(
          onTap: () {
            _onSettingIconTap(key, config);
          },
          child: Icon(
            Icons.settings,
            key: key,
            size: 16,
          ),
        ),
      ),
    );
    cells.add(
      DataCell(Text('${config.id}', style: style)),
    );
    cells.add(
      DataCell(Text('${config.enable}', style: style)),
    );
    cells.add(
      DataCell(Text(config.uriPattern, style: style)),
    );
    return cells;
  }

  void _onSettingIconTap(GlobalKey iconKey, HookConfig config) {
    showActionMenu(context: context, iconKey: iconKey, items: [
      Text(config.enable ? 'Disable' : 'Enable'),
      Text('Edit'),
      Text('Delete'),
    ]).then((value) {
      debugPrint('menu $value clicked');
      switch (value) {
        case 0:
          _actionEnableOrDisable(config);
          break;
        case 1:
          _actionEdit(config);
          break;
        case 2:
          _actionDelete(config);
          break;
      }
    });
  }

  void _actionEnableOrDisable(HookConfig config) {
    config.enable = !config.enable;
    _configBloc.save(config).then((value) {
      _configBloc.loadConfigs().then((value) {
        setState(() {});
      });
    });
  }

  void _actionEdit(HookConfig config) {
    if (config.mapLocal) {
      _actionShowEditMapLocal(config);
    } else if (config.mapRemote) {
      _actionShowEditMapRemote(config);
    }
  }

  void _actionDelete(HookConfig config) {
    _configBloc.delete(config).then((value) {
      _windowBloc.toast('删除成功');
      _configBloc.loadConfigs().then((value) {
        setState(() {});
      });
    });
  }

  void _actionShowEditMapLocal(HookConfig config) {
    _webBloc.openNewApp(AppItem(
        name: '修改规则',
        subTitle: 'Map Local - ${config.id}',
        canFullScreen: false,
        icon: Icons.add_rounded,
        defaultSize: Size(400, 500),
        contentBuilder: (ctx) {
          return BlocProvider(
              blocs: [_configBloc],
              child: HookConfigMapLocal(
                hookConfig: config,
              ));
        }));
  }

  void _actionShowEditMapRemote(HookConfig config) {
    _webBloc.openNewApp(AppItem(
        name: '修改规则',
        subTitle: 'Map Remote - ${config.id}',
        canFullScreen: false,
        icon: Icons.add_rounded,
        defaultSize: Size(400, 300),
        contentBuilder: (ctx) {
          return BlocProvider(
              blocs: [_configBloc],
              child: HookConfigMapRemote(
                hookConfig: config,
              ));
        }));
  }
}
