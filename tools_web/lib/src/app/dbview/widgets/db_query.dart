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
import 'package:k_debug_tools_web/src/widgets/common_widgets.dart';

import '../../../bloc_provider.dart';
import '../db_view_bloc.dart';
import '../db_view_models.dart';

///sql查询
class DbQueryWidget extends StatefulWidget {
  final DbFile dbFile;

  DbQueryWidget({Key key, this.dbFile}) : super(key: key);

  @override
  _DbQueryWidgetState createState() => _DbQueryWidgetState();
}

class _DbQueryWidgetState extends State<DbQueryWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  DbViewBloc _dbViewBloc;
  int rowsPerPage = 10;
  TextEditingController _sqlEditingController;
  ExecResult _execResult;

  @override
  void initState() {
    _dbViewBloc = BlocProvider.of<DbViewBloc>(context).first;
    _sqlEditingController = TextEditingController();
    _sqlEditingController.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildActionBar(),
        Expanded(flex: 1, child: _buildInputArea()),
        Visibility(
            visible: _execResult != null,
            child: Expanded(
                flex: 1,
                child: DbQueryExecResultWidget(
                  key: Key(_execResult?.hashCode?.toString()),
                  execResult: _execResult,
                )))
      ],
    );
  }

  ///工具栏
  Widget _buildActionBar() {
    String selectText = _sqlEditingController.selection.baseOffset > -1
        ? _sqlEditingController.text.substring(
            _sqlEditingController.selection.baseOffset,
            _sqlEditingController.selection.extentOffset)
        : '';
    return Container(
      height: 30,
      color: actionBarBackgroundColor(Theme.of(context)),
      child: Row(
        children: <Widget>[
          //exec all
          ActionIcon(
            Icons.playlist_play,
            enable: _sqlEditingController.text.trim().isNotEmpty,
            onTap: () {
              _dbViewBloc
                  .executeSql(
                      widget.dbFile.id.toString(), _sqlEditingController.text)
                  .then((value) {
                setState(() {
                  _execResult = value;
                });
              }).catchError((e) {});
            },
          ),
          //exec select
          ActionIcon(
            Icons.play_arrow,
            enable: selectText.isNotEmpty,
            onTap: () {
              _dbViewBloc
                  .executeSql(widget.dbFile.id.toString(), selectText)
                  .then((value) {
                setState(() {
                  _execResult = value;
                });
              }).catchError((e) {});
            },
          ),
          ActionIcon(
            Icons.stop,
            enable: false,
            onTap: () {
              //todo
            },
          ),
        ],
      ),
    );
  }

  ///sql输入区域
  Widget _buildInputArea() {
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
          controller: _sqlEditingController,
        ),
      ),
    );
  }
}

///执行结果
class DbQueryExecResultWidget extends StatefulWidget {
  final ExecResult execResult;

  DbQueryExecResultWidget({Key key, this.execResult}) : super(key: key);

  @override
  _DbQueryExecResultWidgetState createState() =>
      _DbQueryExecResultWidgetState();
}

class _DbQueryExecResultWidgetState extends State<DbQueryExecResultWidget> {
  List<String> _tabs = <String>[];
  List<Widget> _tabViews = <Widget>[];
  PageController _pageController;

  int _pageIndex = 0;

  @override
  void didUpdateWidget(covariant DbQueryExecResultWidget oldWidget) {
    _pageIndex = 0;
    _tabs.clear();
    _tabViews.clear();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    _pageController =
        PageController(initialPage: this._pageIndex, keepPage: true);
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.execResult != null) {
      if (_tabs.isEmpty) {
        _tabs.add('Info');
        int dataIndex = 1;
        widget.execResult.dataResult?.forEach((element) {
          _tabs.add('Result $dataIndex');
          dataIndex++;
        });
      }
      if (_tabViews.isEmpty) {
        _tabViews
            .add(DbQueryExecResultSqlResult(execResult: widget.execResult));
        widget.execResult.dataResult?.forEach((element) {
          _tabViews.add(DbQueryExecResultDataResult(data: element));
        });
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTabBarWidget(),
        Expanded(
            child: PageView(
          physics: NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: _tabViews,
        )),
      ],
    );
  }

  Widget _buildTabBarWidget() {
    List<Widget> list = <Widget>[];
    ThemeData theme = Theme.of(context);
    for (int i = 0; i < _tabs.length; i++) {
      list.add(GestureDetector(
        onTap: () {
          setState(() {
            _pageIndex = _tabs.indexOf(_tabs[i]);
            _pageController.jumpToPage(_pageIndex);
          });
        },
        child: Container(
            padding: EdgeInsets.only(left: densePadding, right: densePadding),
            child: Stack(children: [
              Center(
                child: Text(_tabs[i]),
              ),
              Positioned(
                  height: 2,
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: i == _pageIndex ? theme.indicatorColor : null,
                  ))
            ])),
      ));
    }
    return Container(
      height: 30,
      color: titleSolidBackgroundColor(theme),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: list,
        ),
      ),
    );
  }
}

///执行结果中的sql信息
class DbQueryExecResultSqlResult extends StatefulWidget {
  final ExecResult execResult;

  DbQueryExecResultSqlResult({Key key, this.execResult}) : super(key: key);

  @override
  _DbQueryExecResultSqlResultState createState() =>
      _DbQueryExecResultSqlResultState();
}

class _DbQueryExecResultSqlResultState extends State<DbQueryExecResultSqlResult>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(
      builder: (_, constraints) {
        return Scrollbar(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.minWidth),
                child: DataTable(
                  headingRowHeight: 32,
                  dataRowHeight: 32,
                  showCheckboxColumn: false,
                  columns: [
                    DataColumn(label: Text('sql')),
                    DataColumn(label: Text('message')),
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
    List<DataRow> rows = List<DataRow>();
    widget.execResult?.sqlResult?.forEach((element) {
      rows.add(DataRow(cells: [
        DataCell(Text(element.sql.replaceAll('\n', ' ').trim())),
        DataCell(Text(element.message)),
      ]));
    });
    return rows;
  }
}

///执行结果中的数据
class DbQueryExecResultDataResult extends StatefulWidget {
  final List<Map> data;

  DbQueryExecResultDataResult({Key key, this.data}) : super(key: key);

  @override
  _DbQueryExecResultDataResultState createState() =>
      _DbQueryExecResultDataResultState();
}

class _DbQueryExecResultDataResultState
    extends State<DbQueryExecResultDataResult>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(
      builder: (_, constraints) {
        return Scrollbar(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.minWidth),
                child: DataTable(
                  headingRowHeight: 32,
                  dataRowHeight: 32,
                  showCheckboxColumn: false,
                  columns: _buildColumn(),
                  rows: _buildRow(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<DataColumn> _buildColumn() {
    List<DataColumn> columns = List<DataColumn>();
    widget.data.first.keys.forEach((element) {
      columns.add(DataColumn(label: Text(element)));
    });
    return columns;
  }

  List<DataRow> _buildRow() {
    List<DataRow> rows = List<DataRow>();
    widget.data.forEach((row) {
      List<DataCell> cells = List<DataCell>();
      widget.data.first.keys.forEach((k) {
        cells.add(DataCell(Text('${row[k]}')));
      });
      rows.add(DataRow(cells: cells));
    });
    return rows;
  }
}
