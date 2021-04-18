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
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:k_debug_tools_web/src/theme.dart';
import 'package:k_debug_tools_web/src/web_bloc.dart';
import 'package:k_debug_tools_web/src/widgets/common_widgets.dart';
import 'package:k_debug_tools_web/src/widgets/item_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../app_window_bloc.dart';
import '../../../bloc_provider.dart';
import '../photo_manager_bloc.dart';
import '../photo_models.dart';
import 'asset_grid.dart';
import 'asset_list.dart';

class AssetViewWidget extends StatefulWidget {
  AssetViewWidget();

  @override
  _AssetViewWidgetState createState() => _AssetViewWidgetState();
}

class _AssetViewWidgetState extends State<AssetViewWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final GlobalKey _sortIconKey = GlobalKey();
  final GlobalKey _filterIconKey = GlobalKey();
  WebBloc _webBloc;
  PhotoManagerBloc _photoBloc;
  AppWindowBloc _windowBloc;
  ItemPicker<Asset> _itemPicker;
  bool _viewAsGird = true;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildActionWidget(),
        Expanded(
          child: _viewAsGird ? AssetGirdWidget() : AssetListWidget(),
        )
      ],
    );
  }

  ///工具栏
  Widget _buildActionWidget() {
    var l10n = AppLocalizations.of(context);
    return Container(
      height: 30,
      color: actionBarBackgroundColor(Theme.of(context)),
      child: Row(
        children: <Widget>[
          ActionIcon(
            Icons.refresh,
            tooltip: l10n.refresh,
            onTap: () {
              _refresh();
              _itemPicker.clear();
            },
          ),
          ActionIcon(
            Icons.file_download,
            tooltip: l10n.download,
            enable: _itemPicker.selectedCount > 0,
            onTap: () {
              _photoBloc.download(_itemPicker.selectedItem);
            },
          ),
          ActionIcon(
            Icons.file_upload,
            tooltip: l10n.upload,
            enable: true,
            onTap: _actionUpload,
          ),
          ActionIcon(
            Icons.delete_forever,
            tooltip: l10n.delete,
            enable: _itemPicker.selectedCount > 0,
            onTap: _actionDeleteSelected,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ActionIcon(
                  _viewAsGird
                      ? Icons.view_list_rounded
                      : Icons.view_module_rounded,
                  tooltip: l10n.switchView,
                  enable: true,
                  onTap: () {
                    _viewAsGird = !_viewAsGird;
                    setState(() {});
                  },
                ),
                ActionIcon(
                  Icons.sort_rounded,
                  tooltip: l10n.filter,
                  key: _sortIconKey,
                  enable: true,
                  onTap: _showSortMenu,
                ),
                ActionIcon(
                  Icons.filter_alt_rounded,
                  tooltip: l10n.sort,
                  key: _filterIconKey,
                  enable: true,
                  checked: _photoBloc.hasFilter(),
                  onTap: _showFilterMenu,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showSortMenu() {
    showCheckedMenu(context: context, iconKey: _sortIconKey, checkIndex: [
      _photoBloc.sortType.index
    ], items: [
      Row(
        children: [Text('CreateTime'), Icon(Icons.arrow_drop_down)],
      ),
      Row(
        children: [Text('CreateTime'), Icon(Icons.arrow_drop_up)],
      )
    ]).then((value) {
      switch (value) {
        case 0:
          _photoBloc.setSort(SortType.createDesc);
          break;
        case 1:
          _photoBloc.setSort(SortType.createAsc);
          break;
      }
    });
  }

  void _showFilterMenu() {
    showCheckedMenu(
        context: context,
        iconKey: _filterIconKey,
        checkIndex: [_photoBloc.typeFilter.index],
        items: [Text('All'), Text('Photo'), Text('Video')]).then((value) {
      if ((value ?? -1) >= 0) {
        _photoBloc.setFilterType(TypeFilter.values[value]);
      }
      debugPrint(value.toString());
    });
  }

  void _refresh() {
    _photoBloc
        .fetchAlbumAssets(album: _photoBloc.showingAlbum, ignoreCache: true)
        .then((value) {
      setState(() {});
    });
  }

  ///删除选中
  void _actionDeleteSelected() {
    AppLocalizations l10n = AppLocalizations.of(context);
    _windowBloc.showDialog(msg: l10n.deleteSelectedFiles, actions: [
      DialogAction(
          text: l10n.confirm,
          handler: (ctrl) {
            ctrl.dismiss();
            _photoBloc.delete(_itemPicker.selectedItem).then((value) {
              _windowBloc.toast(l10n.deleteSuccess);
              //refresh
              _refresh();
            }).catchError((e) {
              _windowBloc.toast(l10n.requestError(e));
            });
          },
          isPositive: true),
      DialogAction(
          text: l10n.cancel,
          handler: (ctrl) {
            ctrl.dismiss();
          },
          isPositive: false)
    ]);
  }

  ///上传
  void _actionUpload() {
    AppLocalizations l10n = AppLocalizations.of(context);
    _startPickFile().then((v) {
      if (v.isNotEmpty) {
        _photoBloc.uploadFile(v).then((value) {
          _windowBloc.toast(l10n.success);
          _refresh();
        }).catchError((e) {
          _windowBloc.toast(l10n.requestError(e));
        });
      }
    }).catchError((e) {
      _windowBloc.toast('$e');
    });
  }

  ///从电脑选择文件
  Future<List<html.File>> _startPickFile() async {
    Completer<List<html.File>> completer = Completer();
    final html.InputElement input = html.document.createElement('input');
    input
      ..type = 'file'
      ..multiple = true
      ..accept = 'audio/*,video/*,image/*';
    input.onChange.listen((e) {
      final List<html.File> files = input.files;
      debugPrint('${files?.length} files picked.');
      completer.complete(files);
    });
    input.click();
    return completer.future;
  }
}
