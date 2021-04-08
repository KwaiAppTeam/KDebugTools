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
import 'package:k_debug_tools_web/src/app_window_bloc.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/theme.dart';
import 'package:k_debug_tools_web/src/widgets/common_widgets.dart';
import 'package:k_debug_tools_web/src/widgets/split.dart';

import '../../web_bloc.dart';
import 'file_explorer_bloc.dart';
import 'widgets/file_explorer_list.dart';
import 'widgets/file_explorer_tree.dart';

class FileExplorerWindow extends StatefulWidget {
  final bool showTree;
  final String specifiedRootDir;

  FileExplorerWindow({this.showTree, this.specifiedRootDir});

  @override
  _FileExplorerWindowState createState() => _FileExplorerWindowState();
}

class _FileExplorerWindowState extends State<FileExplorerWindow> {
  FileExplorerBloc _bloc;

  @override
  void dispose() {
    _bloc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _bloc ??= FileExplorerBloc(context,
        showTree: widget.showTree, rootDirPath: widget.specifiedRootDir);
    return BlocProvider(
      child: FileExplorer(),
      blocs: [_bloc],
    );
  }
}

class FileExplorer extends StatefulWidget {
  @override
  _FileExplorerState createState() => _FileExplorerState();
}

class _FileExplorerState extends State<FileExplorer> {
  WebBloc _webBloc;
  FileExplorerBloc _fileBloc;
  AppWindowBloc _windowBloc;

  @override
  void initState() {
    _webBloc = BlocProvider.of<WebBloc>(context).first;
    _fileBloc = BlocProvider.of<FileExplorerBloc>(context).first;
    _windowBloc = BlocProvider.of<AppWindowBloc>(context).first;
    _fileBloc.initRootDir().catchError((e) {
      _windowBloc.toast('$e');
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final splitAxis = Split.axisFor(context, 0.85);
    return Padding(
      padding: EdgeInsets.all(densePadding),
      child: StreamBuilder(
          stream: _fileBloc.fileStream,
          builder: (ctx, _) {
            if(_fileBloc.showTree){
              return Split(
                axis: splitAxis,
                initialFractions: const [0.33, 0.67],
                children: [
                  _buildLeftWidget(),
                  _buildRightWidget(),
                ],
              );
            }
            return _buildRightWidget();
          }),
    );
  }

  ///树形目录结构
  Widget _buildLeftWidget() {
    return Container(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          //顶部菜单 action
          _buildTreeActionWidget(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: densePadding),
              child: Container(
                  decoration: BoxDecoration(
                      border:
                          Border.all(color: Theme.of(context).focusColor)),
                  child: FileTreeWidget()),
            ),
          ),
        ],
      ),
    );
  }

  ///树形目录结构上方action
  Widget _buildTreeActionWidget() {
    return Container(
      child: Row(
        children: <Widget>[
          ActionOutlinedButton(
            'Refresh',
            icon: Icons.refresh,
            onTap: () {
              //todo
            },
          ),
        ],
      ),
    );
  }

  ///右边区域
  Widget _buildRightWidget() {
    return Column(
      children: <Widget>[
        Expanded(
            child: Container(
                decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).focusColor)),
                child: FileListWidget())),
        //current dir absolute path
        Visibility(
          visible: (_fileBloc.showingDir?.absolute ?? '').isNotEmpty,
          child: Container(
              margin: EdgeInsets.only(top: denseSpacing),
              constraints: BoxConstraints(minHeight: 30),
              alignment: Alignment.centerLeft,
              child: SelectableText(
                _fileBloc.showingDir?.absolute ?? '',
                style: Theme.of(context).textTheme.bodyText2,
              )),
        )
      ],
    );
  }
}
