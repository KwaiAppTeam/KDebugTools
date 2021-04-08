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
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:k_debug_tools_web/src/app/httphookconfig/widgets/map_local_edit.dart';
import 'package:k_debug_tools_web/src/app/httphookconfig/widgets/map_remote_edit.dart';
import 'package:k_debug_tools_web/src/theme.dart';
import 'package:k_debug_tools_web/src/web_bloc.dart';
import 'package:k_debug_tools_web/src/widgets/common_widgets.dart';

import '../../../app_window_bloc.dart';
import '../../../bloc_provider.dart';
import '../../app_register.dart';
import '../http_hook_bloc.dart';
import '../http_models.dart';

///列表
class ArchiveListWidget extends StatefulWidget {
  ArchiveListWidget();

  @override
  _ArchiveListWidgetState createState() => _ArchiveListWidgetState();
}

class _ArchiveListWidgetState extends State<ArchiveListWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  WebBloc _webBloc;
  HttpHookBloc _hookBloc;
  AppWindowBloc _windowBloc;
  ScrollController _scrollController = ScrollController();
  bool _needAutoScroll = true;
  int dataLength = 0;
  bool _dataChanged = false;

  @override
  void initState() {
    _webBloc = BlocProvider.of<WebBloc>(context).first;
    _windowBloc = BlocProvider.of<AppWindowBloc>(context).first;
    _hookBloc = BlocProvider.of<HttpHookBloc>(context).first;

    WidgetsBinding.instance.addPersistentFrameCallback((timeStamp) {
      if (_needAutoScroll && _dataChanged) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        _dataChanged = false;
      }
    });
    _scrollController.addListener(() {
      //手动滑了之后不自动滚了 但手动再次滑倒底部后再开启自动滚
      _needAutoScroll = (_scrollController.offset ==
          _scrollController.position.maxScrollExtent);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ThemeData theme = Theme.of(context);
    List<HttpArchive> list = _hookBloc.filteredHttpArchiveList;
    if (dataLength != list.length) {
      dataLength = list.length;
      _dataChanged = true;
    }
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
                child: ValueListenableBuilder(
                  valueListenable: _hookBloc.selectedHttpArchive,
                  builder: (ctx, value, child) {
                    return DataTable(
                      columnSpacing: 4,
                      headingRowHeight: 24,
                      dataRowHeight: 26,
                      showCheckboxColumn: false,
                      headingTextStyle:theme.textTheme.subtitle2.copyWith(fontSize: 12),
                      dataTextStyle:
                      theme.textTheme.subtitle2.copyWith(fontSize: 12),
                      columns: [
                        DataColumn(label: Text('')),
                        DataColumn(label: Text('')),
                        DataColumn(label: Text('Code')),
                        DataColumn(label: Text('Method')),
                        DataColumn(label: Text('Url')),
                        DataColumn(label: Text('Start')),
                        DataColumn(label: Text('Duration')),
                        DataColumn(label: Text('Size')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: _buildRow(),
                    );
                  },
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
    List<HttpArchive> list = _hookBloc.filteredHttpArchiveList;
    for (int i = 0; i < list.length; i++) {
      HttpArchive archive = list.elementAt(i);
      rows.add(DataRow.byIndex(
          index: i,
          selected: _hookBloc.itemPicker.isSelected(archive),
          onSelectChanged: (select) {
            debugPrint('onSelectChanged: $i $select');
            _hookBloc.showSelectedDetail = select;
            _hookBloc.itemPicker.onItemTap(archive);
          },
          color: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected))
              return selectedRowBackground;
            return null;
          }),
          cells: _createRowCells(i, archive)));
    }

    return rows;
  }

  List<DataCell> _createRowCells(int row, HttpArchive archive) {
    List<DataCell> cells = List<DataCell>();
    cells.add(DataCell.empty);
    GlobalKey key = GlobalKey();
    cells.add(
      DataCell(
        GestureDetector(
          onTap: () {
            _onSettingIconTap(key, archive);
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
      DataCell(Text('${archive.statusCode ?? ''}')),
    );
    cells.add(
      DataCell(Text(archive.method)),
    );
    cells.add(
      DataCell(
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: Text(
            archive.url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
    String startTime = DateFormat('HH:mm:ss')
        .format(DateTime.fromMillisecondsSinceEpoch(archive.start));
    cells.add(
      DataCell(Text(startTime)),
    );
    if (archive.end != null) {
      int duration = archive.end - archive.start;
      cells.add(
        DataCell(Text('${(duration).toStringAsFixed(0)}ms')),
      );
    } else {
      cells.add(DataCell.empty);
    }
    cells.add(
      DataCell(Text(
          '${((archive.responseLength ?? 0) / 1024).toStringAsFixed(2)}KB')),
    );
    cells.add(
      DataCell(Text('${archive.status}')),
    );
    return cells;
  }

  void _onSettingIconTap(GlobalKey iconKey, HttpArchive archive) {
    _hookBloc.itemPicker.onItemTap(archive);
    showActionMenu(context: context, iconKey: iconKey, items: [
      Text('Copy URL'),
      Text('Copy cURL Request'),
      Text('Map Local...'),
      Text('Map Remote...'),
    ]).then((value) {
      debugPrint('menu $value clicked');
      switch (value) {
        case 0:
          _actionCopyUrl(archive);
          break;
        case 1:
          _actionCopyCUrlRequest(archive);
          break;
        case 2:
          _actionShowNewMapLocal(archive);
          break;
        case 3:
          _actionShowNewMapRemote(archive);
          break;
      }
    });
  }

  ///复制url
  void _actionCopyUrl(HttpArchive archive) {
    Clipboard.setData(ClipboardData(text: '${archive.url}'));
  }

  ///复制curl请求
  void _actionCopyCUrlRequest(HttpArchive archive) {
    StringBuffer curl = StringBuffer();
    curl.write("curl");
    // append URL
    curl.write(" '${archive.url}'");
    curl.write(" --compressed");
    // append method if different from GET
    if ("GET" != archive.method) {
      curl.write(" -X ${archive.method}");
    }
    // append headers
    archive.requestHeaders?.forEach((key, values) {
      values?.forEach((v) {
        if ("host" != key.toLowerCase()) {
          curl.write(" -H '$key: $v'");
        } else {
          //使用原始host 非映射后的host
          curl.write(" -H '$key: ${archive.uri.host}:${archive.uri.port}'");
        }
      });
    });
    String requestBody = HttpArchive.decodeBody(archive.requestBody);
    if (requestBody != null && requestBody.isNotEmpty) {
      curl.write(" --data-binary '${requestBody.replaceAll("'", r"\'")}'");
    }

    Clipboard.setData(ClipboardData(text: '${curl.toString()}'));
  }

  void _actionShowNewMapLocal(HttpArchive archive) {
    _webBloc.openNewApp(AppItem(
        name: '新建规则',
        subTitle: 'Map Local',
        canFullScreen: false,
        icon: Icons.add_rounded,
        defaultSize: Size(400, 500),
        contentBuilder: (ctx) {
          return BlocProvider(
              blocs: [_hookBloc.hookConfigBloc],
              child: HookConfigMapLocal(
                httpArchive: archive,
              ));
        }));
  }

  void _actionShowNewMapRemote(HttpArchive archive) {
    _webBloc.openNewApp(AppItem(
        name: '新建规则',
        subTitle: 'Map Remote',
        canFullScreen: false,
        icon: Icons.add_rounded,
        defaultSize: Size(400, 300),
        contentBuilder: (ctx) {
          return BlocProvider(
              blocs: [_hookBloc.hookConfigBloc],
              child: HookConfigMapRemote(
                httpArchive: archive,
              ));
        }));
  }
}
