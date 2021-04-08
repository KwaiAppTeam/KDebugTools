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

import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';

import '../../app_window_bloc.dart';
import 'video_player_bloc.dart';

class VideoPlayerWindow extends StatefulWidget {
  final String filePath;

  VideoPlayerWindow({Key key, this.filePath}) : super(key: key);

  @override
  _VideoPlayerWindowState createState() => _VideoPlayerWindowState();
}

class _VideoPlayerWindowState extends State<VideoPlayerWindow> {
  VideoPlayerBloc _bloc;

  @override
  void dispose() {
    _bloc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _bloc ??= VideoPlayerBloc(context, widget.filePath);
    return BlocProvider(
      child: VideoPlayer(),
      blocs: [_bloc],
    );
  }
}

class VideoPlayer extends StatefulWidget {
  @override
  _VideoPlayerState createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  AppWindowBloc _windowBloc;
  VideoPlayerBloc _playerBloc;
  VideoPlayerController _videoPlayerController;
  ChewieController _chewieController;

  @override
  void initState() {
    _windowBloc = BlocProvider.of<AppWindowBloc>(context).first;
    _playerBloc = BlocProvider.of<VideoPlayerBloc>(context).first;
    _videoPlayerController =
        VideoPlayerController.network(_playerBloc.networkPath);
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      aspectRatio: 1 / 1,
      autoPlay: true,
      looping: false,
      allowFullScreen: false,
      customControls: MaterialControls(),
    );
    super.initState();
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildContentWidget();
  }

  Widget _buildContentWidget() {
    return SizedBox.expand(
      child: Chewie(
        controller: _chewieController,
      ),
    );
  }
}
