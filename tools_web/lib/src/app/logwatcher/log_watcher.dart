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
import 'package:intl/intl.dart';
import 'package:k_debug_tools_web/src/app/logwatcher/log_models.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/custom_color.dart';
import 'package:k_debug_tools_web/src/theme.dart';
import 'package:k_debug_tools_web/src/widgets/common_widgets.dart';

import 'log_watcher_bloc.dart';

class LogWatcherWindow extends StatefulWidget {
  @override
  _LogWatcherWindowState createState() => _LogWatcherWindowState();
}

class _LogWatcherWindowState extends State<LogWatcherWindow> {
  LogWatcherBloc _bloc;

  @override
  void dispose() {
    _bloc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _bloc ??= LogWatcherBloc(context);
    return BlocProvider(
      child: LogWatcher(),
      blocs: [_bloc],
    );
  }
}

class LogWatcher extends StatefulWidget {
  @override
  _LogWatcherState createState() => _LogWatcherState();
}

class _LogWatcherState extends State<LogWatcher> {
  LogWatcherBloc _logWatcherBloc;
  TextEditingController _filterEditingController;
  ScrollController _scrollController;
  bool _needAutoScroll = true;
  bool _dataChanged = false;
  int _dataLength = 0;

  @override
  void initState() {
    _logWatcherBloc = BlocProvider.of<LogWatcherBloc>(context).first;
    _filterEditingController = TextEditingController();
    _filterEditingController.addListener(() {
      _logWatcherBloc.applyKeywordFilter(_filterEditingController.value?.text);
    });
    WidgetsBinding.instance.addPersistentFrameCallback((timeStamp) {
      if (_needAutoScroll && _dataChanged && _scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        _dataChanged = false;
      }
    });
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      //手动滑了之后不自动滚了 但手动再次滑倒底部后再开启自动滚
      _needAutoScroll = (_scrollController.offset ==
          _scrollController.position.maxScrollExtent);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _logWatcherBloc.stateStream,
      builder: (ctx, _) {
        return Container(
          width: double.infinity,
          child: Column(
            children: <Widget>[
              //顶部菜单 action
              _buildActionWidget(),
              Expanded(child: _buildContentWidget()),
            ],
          ),
        );
      },
    );
  }

  ///日志内容区域
  Widget _buildContentWidget() {
    List<LogEntry> list = _logWatcherBloc.filteredLogList;
    if (_dataLength != list.length) {
      _dataLength = list.length;
      _dataChanged = true;
    }
    StringBuffer buffer = StringBuffer();
    list.forEach((element) {
      buffer.write(DateFormat('HH:mm:ss')
          .format(DateTime.fromMillisecondsSinceEpoch(element.time)));
      buffer.write(LogLevelTag[element.level].toString().split('.'));
      buffer.write(': ');
      buffer.write(element.msg);
      buffer.writeln();
    });
    buffer.writeln();
    buffer.writeln();
    return Container(
        width: double.infinity,
        child: Scrollbar(
          controller: _scrollController,
          child: SelectableText(
            buffer.toString(),
            style: Theme.of(context).textTheme.bodyText2,
          ),
        ));
  }

//  //目前使用TextSpan多行时会无法选中
//  List<InlineSpan> _buildSpan() {
//    List<InlineSpan> result = List<InlineSpan>();
//
//    List<LogEntry> list = _logWatcherBloc.filteredLogList;
//    if (_dataLength != list.length) {
//      _dataLength = list.length;
//      _dataChanged = true;
//    }
//
//    list.forEach((element) {
//      Color color = element.level < LogLevel.info.index
//          ? CustomTheme.textLogError
//          : CustomTheme.textLogNormal;
//      StringBuffer buffer = StringBuffer();
//      buffer.write(DateFormat('HH:mm:ss')
//          .format(DateTime.fromMillisecondsSinceEpoch(element.time)));
//      buffer.write(LogLevelTag[element.level].toString().split('.'));
//      buffer.write(': ');
//      buffer.write(element.msg);
//      buffer.writeln();
//      InlineSpan span =
//          TextSpan(text: buffer.toString(), style: TextStyle(color: color));
//
//      result.add(span);
//    });
//    return result;
//  }

  ///action区域
  Widget _buildActionWidget() {
    return Container(
      height: 30,
      color: actionBarBackgroundColor(Theme.of(context)),
      child: Row(
        children: <Widget>[
          ActionIcon(
            _logWatcherBloc.isEnable ? Icons.stop : Icons.play_arrow,
            tooltip: _logWatcherBloc.isEnable ? 'Stop' : 'Start',
            enable: true,
            customColor: _logWatcherBloc.isEnable
                ? CustomColor.iconActionRed
                : CustomColor.iconActionGreen,
            onTap: () {
              _logWatcherBloc.setEnable(!_logWatcherBloc.isEnable);
            },
          ),
          ActionIcon(
            Icons.delete,
            tooltip: 'Clear',
            enable: true,
            onTap: () {
              _logWatcherBloc.clear();
            },
          ),
          //filter
          Expanded(child: _filterActionWidget()),
        ],
      ),
    );
  }

  ///过滤
  Widget _filterActionWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('过滤:'),
        Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              border: Border.all(color: Theme.of(context).focusColor)),
          margin: EdgeInsets.fromLTRB(4, 0, 4, 0),
          padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
          width: 300,
          height: 25,
          child: TextField(
            textAlign: TextAlign.start,
            showCursor: true,
            style: TextStyle(fontSize: 14),
            decoration: null,
            controller: _filterEditingController,
          ),
        )
      ],
    );
  }
}
