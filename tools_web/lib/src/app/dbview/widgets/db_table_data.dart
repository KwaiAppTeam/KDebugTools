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

import 'package:k_debug_tools_web/src/theme.dart';
import 'package:k_debug_tools_web/src/web_bloc.dart';
import 'package:k_debug_tools_web/src/widgets/common_widgets.dart';
import 'package:k_debug_tools_web/src/widgets/item_picker.dart';
import 'package:k_debug_tools_web/src/widgets/paginated_data_table.dart';

import '../../../app_window_bloc.dart';
import '../../../bloc_provider.dart';
import '../db_view_bloc.dart';
import '../db_view_models.dart';

///默认一页数量
const int DEFAULT_PAGE_SIZE = 20;

///数据表
class DbTableDataWidget extends StatefulWidget {
  final TableInfo tableInfo;

  DbTableDataWidget({Key key, this.tableInfo}) : super(key: key);

  @override
  _DbTableDataWidgetState createState() => _DbTableDataWidgetState();
}

class _DbTableDataWidgetState extends State<DbTableDataWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  WebBloc _webBloc;
  DbViewBloc _dbViewBloc;
  AppWindowBloc _windowBloc;
  DbTableDataSource _dataSource;
  IndexedItemPicker _itemPicker;

  @override
  void initState() {
    _webBloc = BlocProvider.of<WebBloc>(context).first;
    _windowBloc = BlocProvider.of<AppWindowBloc>(context).first;
    _dbViewBloc = BlocProvider.of<DbViewBloc>(context).first;
    _itemPicker = IndexedItemPicker(context);
    _dataSource = DbTableDataSource(
        widget.tableInfo, _dbViewBloc, DEFAULT_PAGE_SIZE, _itemPicker,
        onCellTap: _onCellTap, onError: (e, s) {
      _windowBloc.toast('DataSource error: $e');
    });
    _dataSource.addListener(() {
      setState(() {});
    });
    debugPrint(
        'initState table, column size: ${widget.tableInfo.columns.length}');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildActionBar(),
        Expanded(
            flex: 1,
            child: CustomPaginatedDataTable(
              headingRowHeight: 32,
              dataRowHeight: 32,
              rowsPerPage: _dataSource.rowsPerPage,
              showCheckboxColumn: false,
              onPageChanged: (int) {
                //clear select
                _itemPicker.clear();
              },
              onRowsPerPageChanged: (size) {
                _dataSource.rowsPerPage = size;
                setState(() {});
              },
              columns: widget.tableInfo.columns.map((e) {
                if (e.pk == 1) {
                  return DataColumn(
                      label: Row(
                    children: [
                      Icon(
                        Icons.outlined_flag,
                        size: 18,
                      ),
                      Text(e.name)
                    ],
                  ));
                } else {
                  return DataColumn(label: Text(e.name));
                }
              }).toList(growable: false),
              source: _dataSource,
            )),
      ],
    );
  }

  void _onCellTap(row, col) {
    debugPrint(
        'DataCell onTap row: $row, column: $col, shift: ${_webBloc.isShiftPressed}, meta: ${_webBloc.isMetaPressed}');
    TableColumn column = _dataSource.tableInfo.columns[col];
    bool forceSelect = false;
    if (column.pk == 1) {
      //primary key can not edit
      _dataSource.setEditing(-1, -1);
    } else if (_webBloc.isShiftPressed || _webBloc.isMetaPressed) {
      //do not start edit when Shift or Meta pressed
      _dataSource.setEditing(-1, -1);
    } else if (_dataSource.canEdit(row, col)) {
      //can start edit
      _dataSource.setEditing(row, col);
      forceSelect = true;
    }
    _itemPicker.onItemTap(row, forceSelect: forceSelect);
  }

  ///工具栏
  Widget _buildActionBar() {
    return Container(
      height: 30,
      color: actionBarBackgroundColor(Theme.of(context)),
      child: Row(
        children: <Widget>[
          ActionIcon(
            Icons.refresh,
            enable: true,
            onTap: () {
              _dataSource.refresh();
            },
          ),
          ActionIcon(
            Icons.delete_forever,
            enable: _dataSource.selectedRowCount > 0,
            onTap: _actionDeleteFocused,
          ),
        ],
      ),
    );
  }

  ///删除选中
  void _actionDeleteFocused() {
    _windowBloc.showDialog(
        msg: 'Delete ${_dataSource.selectedRowCount} rows?',
        actions: [
          DialogAction(
              text: 'Confirm',
              handler: (ctrl) {
                ctrl.dismiss();
                _dbViewBloc
                    .deleteTableData(
                        widget.tableInfo, _dataSource.getSelectedData())
                    .then((value) {
                  _windowBloc.toast('${value?.sqlResult?.first?.message}');
                  _dataSource.refresh();
                }).catchError((e, s) {
                  debugPrint('delete failed: $e $s');
                  _windowBloc.toast('delete failed: $e');
                });
              },
              isPositive: true),
          DialogAction(
              text: 'Cancel',
              handler: (ctrl) {
                ctrl.dismiss();
              },
              isPositive: false)
        ]);
  }
}

typedef onCellTap = void Function(int row, int col);

///限制可显示的长度 超过会卡死了。。
const int SHOW_TEXT_LENGTH_LIMIT = 500;

///数据源
class DbTableDataSource extends DataTableSource {
  final TableInfo tableInfo;
  final DbViewBloc dbViewBloc;
  final Function onError;
  final onCellTap;
  final IndexedItemPicker itemPicker;
  int rowsPerPage;
  bool _fetching = false;
  Map<int, Map> data = Map<int, Map>();

  // $row/$cel
  String _editingCell;

  DbTableDataSource(
      this.tableInfo, this.dbViewBloc, this.rowsPerPage, this.itemPicker,
      {this.onError, this.onCellTap}) {
    itemPicker.addListener(() {
      notifyListeners();
    });
  }

  @override
  DataRow getRow(int index) {
    if (index >= rowCount) {
      return null;
    }
    if (data[index] != null) {
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
    } else if (!_fetching) {
      _fetching = true;
      int offset = index - (index % rowsPerPage);
      dbViewBloc
          .fetchTableData(tableInfo.dbId, tableInfo.name, offset, rowsPerPage)
          .then((list) {
        int i = offset;
        list.forEach((element) {
          data[i] = element;
          i++;
        });
        _fetching = false;
        notifyListeners();
      }).catchError((e, s) {
        debugPrint('getRow error: $e $s');
        _fetching = false;
        if (onError != null) {
          onError(e, s);
        }
      });
    }
    return null;
  }

  List<DataCell> _createRowCells(int row) {
    List<DataCell> cells = List<DataCell>();
    for (int i = 0; i < tableInfo.columns.length; i++) {
      cells.add(DataCell(
          ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 500),
              child: _buildCellWidget(row, i)), onTap: () {
        if (onCellTap != null) {
          onCellTap(row, i);
        }
      }));
    }
    return cells;
  }

  String _dataSubstring(String str) {
    if (str.length < SHOW_TEXT_LENGTH_LIMIT) {
      return str;
    } else {
      return str.substring(0, SHOW_TEXT_LENGTH_LIMIT) + '...';
    }
  }

  Widget _buildCellWidget(int row, int col) {
    String current = '$row/$col';
    String colName = tableInfo.columns[col].name;
    return current != _editingCell
        ? Text(
            _dataSubstring('${data[row][colName]}'), //数据太长就卡住了
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        : ListValueInputWidget(
            TextEditingController.fromValue(
                TextEditingValue(text: '${data[row][colName]}')), (newValue) {
            if (newValue != '${data[row][colName]}') {
              //value changed, update
              _updateValue(row, colName, newValue);
            } else {
              //cancel
              _editingCell = null;
              notifyListeners();
            }
          }, () {
            //cancel
            _editingCell = null;
            notifyListeners();
          });
  }

  void _updateValue(int index, String colName, String newValue) {
    dbViewBloc
        .updateTableData(tableInfo, data[index], colName, newValue)
        .then((value) {
      //success
      data[index][colName] = newValue;
      _editingCell = null;
      notifyListeners();
    }).catchError((e, s) {
      debugPrint('updateTableData error: $e $s');
      if (onError != null) {
        onError(e, s);
      }
    });
  }

  ///是否可编辑
  bool canEdit(int row, int col) {
    String colName = tableInfo.columns[col].name;
    //字符串太长会卡死。。
    return '${data[row][colName]}'.length < SHOW_TEXT_LENGTH_LIMIT;
  }

  bool isEditing(int row, int col) {
    return _editingCell == '$row/$col';
  }

  void setEditing(int row, int col) {
    _editingCell = '$row/$col';
    notifyListeners();
  }

  @override
  int get selectedRowCount {
    return itemPicker.selectedCount;
  }

  @override
  bool get isRowCountApproximate {
    return false;
  }

  @override
  int get rowCount {
    return tableInfo?.count ?? 0;
  }

  void refresh() {
    data.clear();
    itemPicker.clear();
    notifyListeners();
  }

  List<Map> getSelectedData() {
    return itemPicker.selectedItem.map((e) => data[e]).toList(growable: false);
  }
}
