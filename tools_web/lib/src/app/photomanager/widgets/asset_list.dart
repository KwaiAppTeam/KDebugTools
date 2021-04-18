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
import 'package:intl/intl.dart';
import 'package:k_debug_tools_web/src/web_bloc.dart';
import 'package:k_debug_tools_web/src/widgets/item_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../app_window_bloc.dart';
import '../../../bloc_provider.dart';
import '../photo_manager_bloc.dart';
import '../photo_models.dart';
import 'asset_item_thumb.dart';

///列表 //todo 性能太差
class AssetListWidget extends StatefulWidget {
  AssetListWidget();

  @override
  _AssetListWidgetState createState() => _AssetListWidgetState();
}

class _AssetListWidgetState extends State<AssetListWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  WebBloc _webBloc;
  PhotoManagerBloc _photoBloc;
  AppWindowBloc _windowBloc;
  ItemPicker _itemPicker;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    _webBloc = BlocProvider.of<WebBloc>(context).first;
    _windowBloc = BlocProvider.of<AppWindowBloc>(context).first;
    _photoBloc = BlocProvider.of<PhotoManagerBloc>(context).first;
    _itemPicker = _photoBloc.itemPicker;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    AppLocalizations l10n = AppLocalizations.of(context);
    List<DataRow> rows = _buildRow();
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
                  headingRowHeight: 32,
                  dataRowHeight: 64,
                  showCheckboxColumn: true,
                  columns: [
                    DataColumn(label: Text(l10n.preview)), //preview
                    DataColumn(label: Text(l10n.title)), //title
                    DataColumn(label: Text(l10n.wxh)), //w x h
                    DataColumn(label: Text(l10n.duration)), //duration
                    DataColumn(label: Text(l10n.createTime)), //time
                  ],
                  rows: rows,
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
    Iterable<Asset> assets = _photoBloc.getShowingAssets();
    assets?.forEach((element) {
      rows.add(DataRow(
          onSelectChanged: (selected) {
            if (selected) {
              _itemPicker.select(element);
            } else {
              _itemPicker.deselect(element);
            }
          },
          selected: _itemPicker.isSelected(element),
          cells: [
            DataCell(
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).focusColor),
                    ),
                    child: AssetItemThumbWidget(
                      asset: element,
                      thumbUrl: _photoBloc.getThumbUrl(element),
                    ),
                  ),
                ), onTap: () {
              _onTap(element);
            }),
            DataCell(Text(element.title)),
            DataCell(Text(
                element.width > 0 ? '${element.width}x${element.height}' : '')),
            DataCell(Text(element.duration > 0 ? '${element.duration}s' : '')),
            DataCell(Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(
                DateTime.fromMillisecondsSinceEpoch(element.createTs)))),
          ]));
    });
    return rows;
  }

  //目前不支持onDoubleTap 自己简单实现下
  Map<String, int> _cellTapTime = Map<String, int>();

  void _onTap(Asset asset) {
    int t = _cellTapTime[asset.id] ?? 0;
    if (DateTime.now().millisecondsSinceEpoch - t < 500) {
      //open
      _photoBloc.openFile(_photoBloc.getShowingAssets().toList(), asset);
    }
    _cellTapTime[asset.id] = DateTime.now().millisecondsSinceEpoch;
  }
}
