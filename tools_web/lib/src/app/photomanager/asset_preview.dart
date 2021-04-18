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

import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:k_debug_tools_web/src/app/videoplayer/video_player.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/widgets/common_widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../app_window_bloc.dart';
import '../../theme.dart';
import '../../web_http.dart';
import 'asset_preview_bloc.dart';
import 'photo_models.dart';

class AssetPreviewWindow extends StatefulWidget {
  final List<Asset> assetList;
  final int initIndex;

  AssetPreviewWindow({Key key, @required this.assetList, this.initIndex = 0})
      : super(key: key);

  @override
  _AssetPreviewWindowState createState() => _AssetPreviewWindowState();
}

class _AssetPreviewWindowState extends State<AssetPreviewWindow> {
  AssetPreviewBloc _bloc;

  @override
  void dispose() {
    _bloc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _bloc ??= AssetPreviewBloc(context);
    return BlocProvider(
      child: AssetPreview(
        assetList: widget.assetList,
        initIndex: widget.initIndex,
      ),
      blocs: [_bloc],
    );
  }
}

class AssetPreview extends StatefulWidget {
  final List<Asset> assetList;
  final int initIndex;

  const AssetPreview({Key key, this.assetList, this.initIndex})
      : super(key: key);

  @override
  _AssetPreviewState createState() => _AssetPreviewState();
}

class _AssetPreviewState extends State<AssetPreview> {
  AppWindowBloc _windowBloc;
  AssetPreviewBloc _previewBloc;

  int _index;

  List<Asset> _assetList;

  Asset get currentAsset =>
      (_index > -1 && _index < _assetList.length) ? _assetList[_index] : null;

  bool _showInfo = true;

  @override
  void initState() {
    _index = widget.initIndex;
    _assetList = widget.assetList.toList();

    _windowBloc = BlocProvider.of<AppWindowBloc>(context).first;
    _previewBloc = BlocProvider.of<AssetPreviewBloc>(context).first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Column(
        children: <Widget>[
          //顶部菜单 action
          _buildActionWidget(),
          Expanded(
              child: Stack(
            children: [
              Positioned.fill(child: _buildContentWidget()),
              Positioned(
                  right: 0,
                  top: 0,
                  child: Visibility(visible: _showInfo, child: _buildInfo()))
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    if (currentAsset == null) {
      return Container();
    }
    StringBuffer info = StringBuffer();
    info.write('id: ${currentAsset.id}\n');
    info.write('title: ${currentAsset.title}\n');
    info.write('width: ${currentAsset.width}\n');
    info.write('height: ${currentAsset.height}\n');
    if (currentAsset.type == 2) {
      info.write('duration: ${currentAsset.duration}s\n');
    }
    info.write(
        'create: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(currentAsset.createTs))}');
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background.withOpacity(0.5),
          border: Border.all(color: Theme.of(context).focusColor)),
      child: Padding(
          padding: EdgeInsets.all(densePadding),
          child: SelectableText(info.toString())),
    );
  }

  Widget _buildContentWidget() {
    if (currentAsset == null) {
      return Container();
    } else if (currentAsset.type == 1) {
      return ClipRect(
        child: SizedBox.expand(
          child: InteractiveViewer(
            maxScale: 5,
            child: CachedNetworkImage(
              placeholder: (context, url) =>
                  UnconstrainedBox(child: CircularProgressIndicator()),
              imageUrl: _previewBloc.networkPath(currentAsset),
              httpHeaders: {'Token': getToken()},
              imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
            ),
          ),
        ),
      );
    } else if (currentAsset.type == 2) {
      return VideoPlayerWindow(
        key: Key(_previewBloc.networkPathWithToken(currentAsset)),
        filePath: _previewBloc.networkPathWithToken(currentAsset),
      );
    } else {
      return Container();
    }
  }

  ///action区域
  Widget _buildActionWidget() {
    AppLocalizations l10n = AppLocalizations.of(context);
    return Container(
      height: 30,
      color: actionBarBackgroundColor(Theme.of(context)),
      child: Row(
        children: <Widget>[
          ActionIcon(
            Icons.share_outlined,
            enable: currentAsset != null,
            tooltip: l10n.copyLink,
            onTap: () {
              Clipboard.setData(ClipboardData(
                  text: '${_previewBloc.networkPathWithToken(currentAsset)}'));
              _windowBloc.toast(l10n.copied);
            },
          ),
          ActionIcon(
            Icons.file_download,
            enable: true,
            tooltip: l10n.download,
            onTap: () {
              _previewBloc.download(currentAsset);
            },
          ),
          ActionIcon(
            Icons.delete_forever,
            enable: currentAsset != null,
            tooltip: l10n.delete,
            onTap: _actionDeleteSelected,
          ),
          Expanded(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ActionIcon(
                Icons.info_outline_rounded,
                enable: true,
                checked: _showInfo,
                tooltip: l10n.viewInfo,
                onTap: () {
                  setState(() {
                    _showInfo = !_showInfo;
                  });
                },
              ),
              //todo support keyboard event
              ActionIcon(
                Icons.navigate_before,
                enable: true,
                onTap: () {
                  setState(() {
                    _index = max(0, _index - 1);
                  });
                },
              ),
              Text(
                '${_index + 1}/${_assetList.length}',
                style: Theme.of(context).textTheme.bodyText2,
              ),
              ActionIcon(
                Icons.navigate_next,
                enable: true,
                onTap: () {
                  setState(() {
                    _index = min(_assetList.length, _index + 1);
                  });
                },
              ),
            ],
          ))
        ],
      ),
    );
  }

  ///删除选中
  void _actionDeleteSelected() {
    AppLocalizations l10n = AppLocalizations.of(context);
    _windowBloc.showDialog(msg: l10n.deleteCurrent, actions: [
      DialogAction(
          text: l10n.confirm,
          handler: (ctrl) {
            ctrl.dismiss();
            _previewBloc.delete(currentAsset).then((value) {
              //delete current
              _assetList.removeAt(_index);
              _index = min(_assetList.length, _index + 1);
              setState(() {});
            }).catchError((e) {
              _windowBloc.toast(AppLocalizations.of(context).requestError(e));
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
}
