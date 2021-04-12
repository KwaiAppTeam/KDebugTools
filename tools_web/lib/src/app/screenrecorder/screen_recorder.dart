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

import 'dart:html' as html;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:k_debug_tools_web/src/app/app_register.dart';
import 'package:k_debug_tools_web/src/app/fileexplorer/file_explorer.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/custom_color.dart';
import 'package:k_debug_tools_web/src/theme.dart';
import 'package:k_debug_tools_web/src/widgets/common_widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../app_window_bloc.dart';
import '../../web_bloc.dart';
import 'screen_recorder_bloc.dart';

class ScreenRecorderWindow extends StatefulWidget {
  final String filePath;

  ScreenRecorderWindow({Key key, this.filePath}) : super(key: key);

  @override
  _ScreenRecorderWindowState createState() => _ScreenRecorderWindowState();
}

class _ScreenRecorderWindowState extends State<ScreenRecorderWindow> {
  ScreenRecorderBloc _bloc;

  @override
  void dispose() {
    _bloc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _bloc ??= ScreenRecorderBloc(context);
    return BlocProvider(
      child: ScreenRecorder(),
      blocs: [_bloc],
    );
  }
}

class ScreenRecorder extends StatefulWidget {
  @override
  _ScreenRecorderState createState() => _ScreenRecorderState();
}

class _ScreenRecorderState extends State<ScreenRecorder> {
  WebBloc _webBloc;
  AppWindowBloc _windowBloc;
  ScreenRecorderBloc _screenBloc;
  AppItem recordFileDir;

  @override
  void initState() {
    _webBloc = BlocProvider.of<WebBloc>(context).first;
    _windowBloc = BlocProvider.of<AppWindowBloc>(context).first;
    _screenBloc = BlocProvider.of<ScreenRecorderBloc>(context).first;
    _screenBloc.fetchState().then((value) {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: _screenBloc.stateStream,
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
        });
  }

  ///打开文件夹
  void _openRecordFileDir(String dir) {
    //todo 考虑解耦
    recordFileDir ??= AppItem(
        name: AppLocalizations.of(context).recordFile,
        icon: Icons.insert_drive_file,
        contentBuilder: (ctx) {
          return FileExplorerWindow(
            showTree: false,
            specifiedRootDir: dir,
          );
        });
    if (!_webBloc.isAppOpened(recordFileDir)) {
      _webBloc.openNewApp(recordFileDir);
    }
  }

  Widget _buildContentWidget() {
    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              child: _screenBloc.lastPreviewData != null
                  ? Image.memory(
                      _screenBloc.lastPreviewData,
                      gaplessPlayback: true,
                    )
                  : Center(
                      child: _screenBloc.isAppRecording
                          ? CircularProgressIndicator()
                          : Container()),
            ),
          ),
          //play icon
          Positioned.fill(
            child: Visibility(
              visible: !_screenBloc.isWebPreviewing,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    _startPreview();
                  },
                  child: ClipOval(
                    child: Container(
                      color: Colors.black54,
                      child: Icon(
                        Icons.play_arrow,
                        size: 120,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  ///action区域
  Widget _buildActionWidget() {
    String recordState = '';
    if (_screenBloc.isAppRecording) {
      recordState = '${AppLocalizations.of(context).recording} ${_screenBloc.recordingDuration.inSeconds}s/';
    }
    return Container(
      height: 30,
      color: actionBarBackgroundColor(Theme.of(context)),
      child: Row(
        children: <Widget>[
          ActionIcon(
            !_screenBloc.isWebPreviewing ? Icons.play_arrow : Icons.pause,
            tooltip: !_screenBloc.isWebPreviewing ? 'Start' : 'Stop',
            enable: true,
            onTap: () {
              if (_screenBloc.isWebPreviewing) {
                _screenBloc.pausePreview();
              } else {
                _startPreview();
              }
            },
          ),
          ActionIcon(
            Icons.photo_camera,
            tooltip: 'Capture',
            enable: _screenBloc.isAppServiceRunning,
            onTap: () {
              _screenBloc.downloadCapture().catchError((e) {
                _windowBloc.toast('Download failed');
              });
            },
          ),
          ActionIcon(
            _screenBloc.isAppRecording ? Icons.videocam_off : Icons.videocam,
            tooltip: !_screenBloc.isAppRecording
                ? 'Start Recording'
                : 'Stop Recording',
            enable: _screenBloc.isAppServiceRunning,
            customColor: !_screenBloc.isAppServiceRunning
                ? null
                : (_screenBloc.isAppRecording
                    ? CustomColor.iconActionRed
                    : CustomColor.iconActionGreen),
            onTap: () {
              if (_screenBloc.isAppRecording) {
                _screenBloc.stopRecordToFile().then((value) {
                  _windowBloc.toast(AppLocalizations.of(context).stopRecord(value));
                }).catchError((e) {
                  _windowBloc.toast('${AppLocalizations.of(context).stopFailed} $e');
                });
              } else {
                _screenBloc.startRecordToFile().then((value) {
                  _windowBloc.toast(AppLocalizations.of(context).startRecord);
                }).catchError((e) {
                  _windowBloc.toast('${AppLocalizations.of(context).startFailed} $e');
                });
              }
            },
          ),
          ActionIcon(
            Icons.folder,
            tooltip: 'Open Folder',
            enable: _screenBloc.fileDir.isNotEmpty,
            onTap: () {
              _openRecordFileDir(_screenBloc.fileDir);
            },
          ),
          ActionIcon(
            Icons.open_in_browser,
            tooltip: 'Open in Browser',
            enable: _screenBloc.isAppServiceRunning,
            onTap: () {
              html.window.open(_screenBloc.cgiUrl, 'Preview');
              //这边暂停以节省手机带宽
              _screenBloc.pausePreview();
            },
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$recordState ${_screenBloc.fps}fps/${_screenBloc.bps ~/ 1000}Kbps',
                style: Theme.of(context).textTheme.bodyText2,
              ),
            ),
          )
        ],
      ),
    );
  }

  void _startPreview() {
    if (!_screenBloc.isAppServiceRunning) {
      _windowBloc.toast(AppLocalizations.of(context).checkScreenPermission);
    }
    _screenBloc.startPreview().then((value) {
      setState(() {});
    }).catchError((e) {
      _windowBloc.toast('${AppLocalizations.of(context).startFailed} $e');
    });
  }
}
