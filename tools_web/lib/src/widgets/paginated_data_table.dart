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

import 'dart:html';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:k_debug_tools_web/src/theme.dart';
import 'package:k_debug_tools_web/src/ui/theme.dart';

/// For Dropdown styling
class DropdownStyle {
  /// Colors
  final Color textColor;
  final Color triggerIconColor;
  final Color dropdownCanvasColor;

  /// FontSizes / Icon Sizes
  final double textSize;
  final double triggerIconSize;

  DropdownStyle({
    this.textColor,
    this.triggerIconColor,
    this.dropdownCanvasColor,
    this.textSize,
    this.triggerIconSize,
  });
}

/// For Previous / Next styling
class PreviousNextStyle {
  final Color iconColor;
  final double iconSize;

  PreviousNextStyle({
    this.iconColor,
    this.iconSize,
  });
}

/// Paginated Table
class CustomPaginatedDataTable extends StatefulWidget {
  final List<Widget> actions;
  final List<DataColumn> columns;
  final int sortColumnIndex;
  final bool sortAscending;
  final ValueSetter<bool> onSelectAll;
  final double dataRowHeight;
  final double headingRowHeight;
  final double horizontalMargin;
  final double columnSpacing;
  final bool showCheckboxColumn;
  final int initialFirstRowIndex;
  final ValueChanged<int> onPageChanged;
  final int rowsPerPage;
  static const int defaultRowsPerPage = 10;
  final List<int> availableRowsPerPage;
  final ValueChanged<int> onRowsPerPageChanged;
  final DataTableSource source;
  final TextStyle footerStyle;
  final DropdownStyle dropdownStyle;
  final PreviousNextStyle previousNextStyle;

  CustomPaginatedDataTable({
    Key key,
    this.actions,
    @required this.columns,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSelectAll,
    this.dataRowHeight = kMinInteractiveDimension,
    this.headingRowHeight = 56.0,
    this.horizontalMargin = 24.0,
    this.columnSpacing = 56.0,
    this.showCheckboxColumn = true,
    this.initialFirstRowIndex = 0,
    this.onPageChanged,
    this.rowsPerPage = defaultRowsPerPage,
    this.availableRowsPerPage = const <int>[
      defaultRowsPerPage,
      defaultRowsPerPage * 2,
      defaultRowsPerPage * 5,
      defaultRowsPerPage * 10
    ],
    this.onRowsPerPageChanged,
    this.footerStyle,
    this.dropdownStyle,
    this.previousNextStyle,
    @required this.source,
  })  : assert(columns != null),
        assert(columns.isNotEmpty),
        assert(sortColumnIndex == null ||
            (sortColumnIndex >= 0 && sortColumnIndex < columns.length)),
        assert(sortAscending != null),
        assert(dataRowHeight != null),
        assert(headingRowHeight != null),
        assert(horizontalMargin != null),
        assert(columnSpacing != null),
        assert(showCheckboxColumn != null),
        assert(rowsPerPage != null),
        assert(rowsPerPage > 0),
        assert(() {
          if (onRowsPerPageChanged != null)
            assert(availableRowsPerPage != null &&
                availableRowsPerPage.contains(rowsPerPage));
          return true;
        }()),
        assert(source != null),
        super(key: key);

  @override
  CustomPaginatedDataTableState createState() =>
      CustomPaginatedDataTableState();
}

class CustomPaginatedDataTableState extends State<CustomPaginatedDataTable> {
  int _firstRowIndex;
  int _rowCount;
  bool _rowCountApproximate;
  final Map<int, DataRow> _rows = <int, DataRow>{};

  @override
  void initState() {
    super.initState();
    _firstRowIndex = PageStorage.of(context)?.readState(context) as int ??
        widget.initialFirstRowIndex ??
        0;
    widget.source.addListener(_handleDataSourceChanged);
    _handleDataSourceChanged();
  }

  @override
  void didUpdateWidget(CustomPaginatedDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      oldWidget.source.removeListener(_handleDataSourceChanged);
      widget.source.addListener(_handleDataSourceChanged);
      _handleDataSourceChanged();
    }
  }

  @override
  void dispose() {
    widget.source.removeListener(_handleDataSourceChanged);
    super.dispose();
  }

  void _handleDataSourceChanged() {
    setState(() {
      _rowCount = widget.source.rowCount;
      _rowCountApproximate = widget.source.isRowCountApproximate;
      _rows.clear();
    });
  }

  /// Ensures that the given row is visible.
  void pageTo(int rowIndex) {
    final int oldFirstRowIndex = _firstRowIndex;
    setState(() {
      final int rowsPerPage = widget.rowsPerPage;
      _firstRowIndex = (rowIndex ~/ rowsPerPage) * rowsPerPage;
    });
    if ((widget.onPageChanged != null) && (oldFirstRowIndex != _firstRowIndex))
      widget.onPageChanged(_firstRowIndex);
  }

  DataRow _getBlankRowFor(int index) {
    return DataRow.byIndex(
      index: index,
      cells: widget.columns
          .map<DataCell>((DataColumn column) => DataCell.empty)
          .toList(),
    );
  }

  DataRow _getProgressIndicatorRowFor(int index) {
    bool haveProgressIndicator = false;
    final List<DataCell> cells =
        widget.columns.map<DataCell>((DataColumn column) {
      if (!column.numeric) {
        haveProgressIndicator = true;
        return const DataCell(CircularProgressIndicator());
      }
      return DataCell.empty;
    }).toList();
    if (!haveProgressIndicator) {
      haveProgressIndicator = true;
      cells[0] = const DataCell(CircularProgressIndicator());
    }
    return DataRow.byIndex(
      index: index,
      cells: cells,
    );
  }

  List<DataRow> _getRows(int firstRowIndex, int rowsPerPage) {
    final List<DataRow> result = <DataRow>[];
    final int nextPageFirstRowIndex = firstRowIndex + rowsPerPage;
    bool haveProgressIndicator = false;
    for (int index = firstRowIndex; index < nextPageFirstRowIndex; index += 1) {
      DataRow row;
      if (index < _rowCount || _rowCountApproximate) {
        row = _rows.putIfAbsent(index, () => widget.source.getRow(index));
        if (row == null && !haveProgressIndicator) {
          row ??= _getProgressIndicatorRowFor(index);
          haveProgressIndicator = true;
        }
      }
      //不需要空白行
//      row ??= _getBlankRowFor(index);
      if (row != null) {
        result.add(row);
      }
    }
    return result;
  }

  void _handlePrevious() {
    pageTo(math.max(_firstRowIndex - widget.rowsPerPage, 0));
  }

  void _handleNext() {
    pageTo(_firstRowIndex + widget.rowsPerPage);
  }

  final GlobalKey _tableKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    ThemeData theme = Theme.of(context);
    // FOOTER
    final TextStyle footerTextStyle =
        widget.footerStyle ?? theme.textTheme.subtitle2.copyWith(fontSize: 12);
    final DropdownStyle footerDropdownStyle = widget.dropdownStyle ??
        DropdownStyle(
          textColor: theme.textTheme.subtitle2.color,
          triggerIconColor: titleSolidBackgroundColor(theme),
          dropdownCanvasColor: theme.canvasColor,
          textSize: 12.0,
          triggerIconSize: 18.0,
        );

    final PreviousNextStyle previousNextStyle = widget.previousNextStyle ??
        PreviousNextStyle(
          iconColor: theme.colorScheme.isLight ? Colors.black : Colors.white,
          iconSize: 24.0,
        );
    final List<Widget> footerWidgets = <Widget>[];
    if (widget.onRowsPerPageChanged != null) {
      final List<Widget> availableRowsPerPage = widget.availableRowsPerPage
          .where(
              (int value) => value <= _rowCount || value == widget.rowsPerPage)
          .map<DropdownMenuItem<int>>((int value) {
        return DropdownMenuItem<int>(
          value: value,
          child: Text('$value'),
        );
      }).toList();

      footerWidgets.addAll(<Widget>[
        DefaultTextStyle(
          style: footerTextStyle,
          child: Text("Rows :"),
        ),
        SizedBox(
          width: 10,
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 64.0),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                dropdownColor: footerDropdownStyle.dropdownCanvasColor,
                items: availableRowsPerPage.cast<DropdownMenuItem<int>>(),
                value: widget.rowsPerPage,
                onChanged: widget.onRowsPerPageChanged,
                style: TextStyle(
                  color: footerDropdownStyle.textColor,
                  fontSize: footerDropdownStyle.textSize,
                ),
                iconSize: footerDropdownStyle.triggerIconSize,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: footerDropdownStyle.triggerIconColor,
                ),
              ),
            ),
          ),
        ),
      ]);
    }

    footerWidgets.addAll(<Widget>[
      SizedBox(
        width: 10.0,
      ),
      DefaultTextStyle(
        style: footerTextStyle,
        child: Text(
          localizations.pageRowsInfoTitle(
            _firstRowIndex + 1,
            _firstRowIndex + widget.rowsPerPage,
            _rowCount,
            _rowCountApproximate,
          ),
        ),
      ),
      SizedBox(width: 10.0),
      IconButton(
        icon: Icon(
          Icons.chevron_left,
          color: (_firstRowIndex <= 0)
              ? previousNextStyle.iconColor.withOpacity(0)
              : previousNextStyle.iconColor,
          size: previousNextStyle.iconSize,
        ),
        padding: EdgeInsets.zero,
        tooltip: localizations.previousPageTooltip,
        onPressed: _firstRowIndex <= 0 ? null : _handlePrevious,
      ),
      SizedBox(width: 10.0),
      IconButton(
        icon: Icon(
          Icons.chevron_right,
          color: (!_rowCountApproximate &&
                  (_firstRowIndex + widget.rowsPerPage >= _rowCount))
              ? previousNextStyle.iconColor.withOpacity(0)
              : previousNextStyle.iconColor,
          size: previousNextStyle.iconSize,
        ),
        padding: EdgeInsets.zero,
        tooltip: localizations.nextPageTooltip,
        onPressed: (!_rowCountApproximate &&
                (_firstRowIndex + widget.rowsPerPage >= _rowCount))
            ? null
            : _handleNext,
      ),
      Container(width: 10.0),
    ]);

    // TABLE
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.minWidth),
                    child: DataTable(
                      key: _tableKey,
                      columns: widget.columns,
                      sortColumnIndex: widget.sortColumnIndex,
                      sortAscending: widget.sortAscending,
                      onSelectAll: widget.onSelectAll,
                      dataRowHeight: widget.dataRowHeight,
                      headingRowHeight: widget.headingRowHeight,
                      horizontalMargin: widget.horizontalMargin,
                      columnSpacing: widget.columnSpacing,
                      showCheckboxColumn: widget.showCheckboxColumn,
                      rows: _getRows(_firstRowIndex, widget.rowsPerPage),
                    ),
                  ),
                ),
              ),
            ),
            Visibility(
              visible: widget.source.rowCount > widget.rowsPerPage,
              child: Container(
                height: 30.0,
                color: titleSolidBackgroundColor(theme),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    children: footerWidgets,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
