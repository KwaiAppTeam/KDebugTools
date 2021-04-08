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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/widgets/common_widgets.dart';

import '../../app_window_bloc.dart';
import '../../theme.dart';
import 'image_preview_bloc.dart';

class ImagePreviewWindow extends StatefulWidget {
  final String filePath;

  ImagePreviewWindow({Key key, this.filePath}) : super(key: key);

  @override
  _ImagePreviewWindowState createState() => _ImagePreviewWindowState();
}

class _ImagePreviewWindowState extends State<ImagePreviewWindow> {
  ImagePreviewBloc _bloc;

  @override
  void dispose() {
    _bloc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _bloc ??= ImagePreviewBloc(context, widget.filePath);
    return BlocProvider(
      child: ImagePreview(),
      blocs: [_bloc],
    );
  }
}

class ImagePreview extends StatefulWidget {
  @override
  _ImagePreviewState createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  AppWindowBloc _windowBloc;
  ImagePreviewBloc _imageBloc;

  @override
  void initState() {
    _windowBloc = BlocProvider.of<AppWindowBloc>(context).first;
    _imageBloc = BlocProvider.of<ImagePreviewBloc>(context).first;
    CachedNetworkImage.evictFromCache(_imageBloc.networkPath);
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
          Expanded(child: _buildContentWidget()),
        ],
      ),
    );
  }

  Widget _buildContentWidget() {
    return ClipRect(
      child: SizedBox.expand(
        child: InteractiveViewer(
          child: CachedNetworkImage(
            placeholder: (context, url) =>
                UnconstrainedBox(child: CircularProgressIndicator()),
            imageUrl: _imageBloc.networkPath,
            imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
          ),
        ),
      ),
    );
  }

  ///action区域
  Widget _buildActionWidget() {
    return Container(
      height: 30,
      color: actionBarBackgroundColor(Theme.of(context)),
      child: Row(
        children: <Widget>[
          ActionIcon(
            Icons.refresh,
            enable: true,
            onTap: () {
              CachedNetworkImage.evictFromCache(_imageBloc.networkPath);
              _imageBloc.refresh();
              setState(() {});
            },
          ),
          ActionIcon(
            Icons.file_download,
            enable: _imageBloc.canDownload,
            onTap: () {
              _imageBloc.download();
            },
          ),
          ActionIcon(
            Icons.delete_forever,
            enable: _imageBloc.canDownload,
            onTap: () {
              _imageBloc.delete().then((value) {
                _windowBloc.toast('删除成功');
                setState(() {});
              }).catchError((e) {
                _windowBloc.toast('删除失败 $e');
              });
            },
          ),
        ],
      ),
    );
  }
}
