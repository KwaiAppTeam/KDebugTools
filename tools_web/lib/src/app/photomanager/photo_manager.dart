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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../web_bloc.dart';
import 'photo_manager_bloc.dart';
import 'widgets/album_tree.dart';
import 'widgets/asset_view.dart';

class PhotoManagerWindow extends StatefulWidget {
  PhotoManagerWindow();

  @override
  _PhotoManagerWindowState createState() => _PhotoManagerWindowState();
}

class _PhotoManagerWindowState extends State<PhotoManagerWindow> {
  PhotoManagerBloc _bloc;

  @override
  void dispose() {
    _bloc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _bloc ??= PhotoManagerBloc(context);
    return BlocProvider(
      child: PhotoManager(),
      blocs: [_bloc],
    );
  }
}

class PhotoManager extends StatefulWidget {
  @override
  _PhotoManagerState createState() => _PhotoManagerState();
}

class _PhotoManagerState extends State<PhotoManager> {
  WebBloc _webBloc;
  PhotoManagerBloc _photoBloc;
  AppWindowBloc _windowBloc;

  @override
  void initState() {
    _webBloc = BlocProvider.of<WebBloc>(context).first;
    _photoBloc = BlocProvider.of<PhotoManagerBloc>(context).first;
    _windowBloc = BlocProvider.of<AppWindowBloc>(context).first;
    _photoBloc.fetchAlbums().catchError((e) {
      _windowBloc.toast('$e');
    });
    _photoBloc.showAlbum(null).catchError((e) {
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
          stream: _photoBloc.photoStream,
          builder: (ctx, _) {
            return Split(
              axis: splitAxis,
              initialFractions: const [0.33, 0.67],
              children: [
                _buildLeftWidget(),
                _buildRightWidget(),
              ],
            );
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
                      border: Border.all(color: Theme.of(context).focusColor)),
                  child: AlbumTreeWidget()),
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
            AppLocalizations.of(context).refresh,
            icon: Icons.refresh,
            onTap: () {
              _photoBloc.fetchAlbums().catchError((e) {
                _windowBloc.toast('$e');
              });
              _photoBloc.fetchAlbumAssets(
                  album: _photoBloc.showingAlbum, ignoreCache: true);
            },
          ),
        ],
      ),
    );
  }

  ///右边区域
  Widget _buildRightWidget() {
    return Container(
        decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).focusColor)),
        child: AssetViewWidget());
  }
}
