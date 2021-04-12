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
import 'package:intl/intl.dart';
import 'package:k_debug_tools_web/src/app/fileexplorer/file_explorer_bloc.dart';
import 'package:k_debug_tools_web/src/app/fileexplorer/file_explorer_models.dart';
import 'package:k_debug_tools_web/src/theme.dart';
import 'package:k_debug_tools_web/src/web_bloc.dart';
import 'package:k_debug_tools_web/src/widgets/common_widgets.dart';
import 'package:k_debug_tools_web/src/widgets/item_picker.dart';
import 'package:k_debug_tools_web/src/widgets/paginated_data_table.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../app_window_bloc.dart';
import '../../../bloc_provider.dart';

///默认一页数量
const int DEFAULT_PAGE_SIZE = 100;

///列表
class FileListWidget extends StatefulWidget {
  FileListWidget();

  @override
  _FileListWidgetState createState() => _FileListWidgetState();
}

class _FileListWidgetState extends State<FileListWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  WebBloc _webBloc;
  FileExplorerBloc _fileBloc;
  AppWindowBloc _windowBloc;
  ItemPicker _itemPicker;
  FileListDataSource _dataSource;

  FileModel get lastSelect => _itemPicker.selectedCount > 0
      ? _fileBloc.showingDir.subFiles.elementAt(_itemPicker.lastSelectItem)
      : null;

  List<FileModel> get selectedFiles => _itemPicker.selectedItem
      .map((e) => _fileBloc.showingDir.subFiles.elementAt(e))
      .toList(growable: false);

  @override
  void initState() {
    _webBloc = BlocProvider.of<WebBloc>(context).first;
    _windowBloc = BlocProvider.of<AppWindowBloc>(context).first;
    _fileBloc = BlocProvider.of<FileExplorerBloc>(context).first;
    _itemPicker = IndexedItemPicker(context);
    _dataSource = FileListDataSource(_fileBloc, _itemPicker, DEFAULT_PAGE_SIZE,
        onCellTap: _onCellTap,
        onCellDoubleTap: _onCellDoubleTap, onError: (e, s) {
      _windowBloc.toast('DataSource error: $e');
    });
    _dataSource.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    AppLocalizations l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildActionWidget(),
        Expanded(
          child: Scrollbar(
            child: CustomPaginatedDataTable(
              headingRowHeight: 32,
              dataRowHeight: 32,
              rowsPerPage: _dataSource.rowsPerPage,
              showCheckboxColumn: false,
              onPageChanged: (int) {
                _itemPicker.clear();
              },
              onRowsPerPageChanged: (size) {
                _dataSource.rowsPerPage = size;
                setState(() {});
              },
              columns: [
                DataColumn(label: Text(l10n.fileName)),
                DataColumn(label: Text(l10n.fileSize)),
                DataColumn(label: Text(l10n.fileModifyTime)),
              ],
              source: _dataSource,
            ),
          ),
        )
      ],
    );
  }

  void _onCellTap(row, col) {
    _itemPicker.onItemTap(row);
  }

  void _onCellDoubleTap(row, col) {
    _itemPicker.onItemTap(row);
    FileModel fileModel = _dataSource.getData(row);
    if (fileModel.isDir) {
      _fileBloc.showDir(fileModel);
    } else {
      //open with xxx
      _fileBloc.openFile(fileModel);
    }
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
            Icons.arrow_back,
            tooltip: l10n.back,
            enable: _fileBloc.canGoBack,
            onTap: () {
              _fileBloc.goBack();
            },
          ),
          ActionIcon(
            Icons.refresh,
            tooltip: l10n.refresh,
            onTap: () {
              _dataSource.refresh();
            },
          ),
          ActionIcon(
            Icons.file_download,
            tooltip: l10n.download,
            enable: _itemPicker.selectedCount > 0,
            onTap: () {
              _fileBloc.download(selectedFiles);
            },
          ),
          ActionIcon(
            Icons.file_upload,
            tooltip: l10n.upload,
            enable: _fileBloc.canUpload,
            onTap: _actionUpload,
          ),
          ActionIcon(
            Icons.edit,
            tooltip: l10n.rename,
            //选中一个时可以重命名
            enable: _itemPicker.selectedCount == 1 && !lastSelect.readOnly,
            onTap: () {
              _startRenameSelected();
            },
          ),
          ActionIcon(
            Icons.delete_forever,
            tooltip: l10n.delete,
            enable: _canDeleteSelected(),
            onTap: _actionDeleteSelected,
          ),
        ],
      ),
    );
  }

  bool _canDeleteSelected() {
    bool ret = _itemPicker.selectedCount > 0;
    _itemPicker.selectedItem.forEach((element) {
      if (_fileBloc.showingDir.subFiles.elementAt(element).readOnly) {
        ret = false;
        return;
      }
    });
    return ret;
  }

  ///开始重命名
  void _startRenameSelected() {
    if (_itemPicker.selectedCount != 1) {
      return;
    }
    _dataSource.setRenaming(_itemPicker.selectedItem.last);
  }

  ///删除选中文件
  void _actionDeleteSelected() {
    AppLocalizations l10n = AppLocalizations.of(context);
    _windowBloc.showDialog(msg: l10n.deleteSelectedFiles, actions: [
      DialogAction(
          text: l10n.confirm,
          handler: (ctrl) {
            ctrl.dismiss();
            var files = selectedFiles;
            _fileBloc.delete(_fileBloc.showingDir, files).then((value) {
              _windowBloc.toast(l10n.deleteSuccess);
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
        _fileBloc.uploadFile(_fileBloc.showingDir, v).then((value) {
          _windowBloc.toast(l10n.success);
          _fileBloc.reloadShowingDir().then((value) {
            setState(() {});
          });
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
      ..accept = '*';
    input.onChange.listen((e) {
      final List<html.File> files = input.files;
      debugPrint('${files?.length} files picked.');
      completer.complete(files);
    });
    input.click();
    return completer.future;
  }
}

typedef onCellTap = void Function(int row, int col);

///数据源
class FileListDataSource extends DataTableSource {
  final FileExplorerBloc fileBloc;
  final Function onError;
  final onCellTap;
  final onCellDoubleTap;
  final IndexedItemPicker itemPicker;
  int rowsPerPage;
  bool _fetching = false;
  int _renamingRow = -1;
  StreamSubscription subs;
  Function listener;

  FileModel get parentModel => fileBloc.showingDir;

  FileListDataSource(this.fileBloc, this.itemPicker, this.rowsPerPage,
      {this.onError, this.onCellTap, this.onCellDoubleTap}) {
    itemPicker.addListener(listener = () {
      _renamingRow = -1;
      notifyListeners();
    });
    subs = fileBloc.fileStream.listen((event) {
      itemPicker.clear();
      _renamingRow = -1;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    itemPicker.removeListener(listener);
    subs?.cancel();
    super.dispose();
  }

  @override
  DataRow getRow(int index) {
    if (index < (parentModel?.subFiles?.length ?? 0)) {
      return DataRow.byIndex(
          index: index,
          selected: itemPicker.isSelected(index),
          color: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected))
              return selectedRowBackground;
            return null;
          }),
          cells: _createRowCells(index));
    } else if (!_fetching &&
        parentModel != null &&
        parentModel.subFiles == null) {
      _fetching = true;
      fileBloc.loadDir(parentModel).then((list) {
        _fetching = false;
        notifyListeners();
      }).catchError((e, s) {
        debugPrint('fetch sub files error: $e $s');
        _fetching = false;
        if (onError != null) {
          onError(e, s);
        }
      });
    }
    return null;
  }

  //目前不支持onDoubleTap 自己简单实现下
  Map<String, int> _cellTapTime = Map<String, int>();

  _onTap(int row, int col) {
    return () {
      int t = _cellTapTime['$row/$col'] ?? 0;
      if (DateTime.now().millisecondsSinceEpoch - t < 500 &&
          onCellDoubleTap != null) {
        onCellDoubleTap(row, col);
      } else if (onCellTap != null) {
        onCellTap(row, col);
      }
      _cellTapTime['$row/$col'] = DateTime.now().millisecondsSinceEpoch;
    };
  }

  List<DataCell> _createRowCells(int row) {
    FileModel fileModel = parentModel.subFiles.elementAt(row);
    String lastTime = fileModel.lastModified > 0
        ? DateFormat('yyyy-MM-dd HH:mm:ss')
            .format(DateTime.fromMillisecondsSinceEpoch(fileModel.lastModified))
        : '';
    List<DataCell> cells = <DataCell>[];
    cells.add(
      DataCell(
          Row(
            children: [
              Icon(
                fileModel.isDir ? Icons.folder : Icons.insert_drive_file,
                size: defaultIconSize,
              ),
              SizedBox(width: densePadding),
              Expanded(
                child: Container(
                  child: _renamingRow == row
                      ? _buildRenameInput(row)
                      : Text(fileModel.name ?? ''),
                ),
              )
            ],
          ),
          onTap: _onTap(row, 0)),
    );
    cells.add(
      DataCell(Text(fileModel.sizeStr), onTap: _onTap(row, 1)),
    );
    cells.add(
      DataCell(Text(lastTime), onTap: _onTap(row, 2)),
    );
    return cells;
  }

  bool isRenaming(int row) {
    return _renamingRow == row;
  }

  void setRenaming(int row) {
    _renamingRow = row;
    notifyListeners();
  }

  Widget _buildRenameInput(int row) {
    FileModel model = parentModel.subFiles.elementAt(row);
    return ListValueInputWidget(
        TextEditingController.fromValue(
            TextEditingValue(text: '${model.name}')), (newValue) {
      if (newValue != '${model.name}' && newValue.isNotEmpty) {
        //value changed, update
        fileBloc.rename(model, newValue).catchError((e) {
          onError(e);
        });
      } else {
        //cancel
        _renamingRow = -1;
        notifyListeners();
      }
    }, () {
      //cancel
      _renamingRow = -1;
      notifyListeners();
    });
  }

  @override
  int get selectedRowCount {
    return itemPicker.selectedCount;
  }

  @override
  bool get isRowCountApproximate {
    return parentModel?.subFiles == null;
  }

  @override
  int get rowCount {
    return parentModel?.subFiles?.length ?? 0;
  }

  FileModel getData(int row) {
    return parentModel?.subFiles?.elementAt(row);
  }

  void refresh() {
    parentModel?.subFiles = null;
    itemPicker.clear();
    notifyListeners();
  }
}
