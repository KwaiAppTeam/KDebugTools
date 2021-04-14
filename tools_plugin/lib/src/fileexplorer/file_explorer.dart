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

import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:k_debug_tools/src/widgets/dialog.dart';
import 'package:k_debug_tools/src/widgets/toast.dart';
import 'package:path_provider/path_provider.dart';

import '../../k_debug_tools.dart';
import 'file_explorer_models.dart';

class FileExplorerPage extends StatefulWidget {
  @override
  _FileExplorerPageState createState() => _FileExplorerPageState();
}

class _FileExplorerPageState extends State<FileExplorerPage> {
  final List<FileModel> _history = <FileModel>[];

  @override
  void initState() {
    _initRoot();
    super.initState();
  }

  void _initRoot() async {
    FileModel root = FileModel(type: 'dir', absolute: '');
    root.subFiles = await listAllDirs();
    _history.add(root);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List<FileModel>? subs = _history.isNotEmpty ? _history.last.subFiles : null;
    return Column(
      children: <Widget>[
        Visibility(
          visible: _history.length > 1,
          child: Container(
            height: 36,
            padding: EdgeInsets.only(left: 16, right: 16),
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(width: 1, color: Colors.black26))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _history.removeLast();
                    setState(() {});
                  },
                  child: Container(
                      alignment: Alignment.center,
                      height: 36,
                      child: Text(localizationOptions.parentDir)),
                ),
                GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _reloadCurrentSubs();
                    },
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        alignment: Alignment.center,
                        height: 36,
                        child: Text(localizationOptions.refresh),
                      ),
                    )),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            controller: ScrollController(),
            padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
            itemCount: subs?.length ?? 0,
            itemBuilder: (BuildContext context, int index) {
              return _buildItemWidget(subs!.elementAt(index));
            },
            separatorBuilder: (BuildContext context, int index) {
              return Divider(height: 1, color: Color(0xff000000));
            },
          ),
        ),
        Visibility(
          visible: _history.length > 1,
          child: Container(
              padding: EdgeInsets.all(2),
              width: double.infinity,
              color: Colors.black12,
              child: Text(_history.isNotEmpty ? _history.last.absolute! : '')),
        ),
      ],
    );
  }

  ///重新加载当前文件夹内容
  void _reloadCurrentSubs() async {
    if (_history.isNotEmpty && _history.last.absolute!.isNotEmpty) {
      List<FileModel> files = <FileModel>[];
      _history.last.subFiles = files;
      Directory dir = Directory(_history.last.absolute!);
      try {
        dir.listSync().forEach((element) {
          String name =
              element.path.substring(1 + element.path.lastIndexOf('/'));
          if (element is File) {
            File f = element;
            files.add(FileModel(
                name: name,
                type: 'file',
                absolute: element.path,
                lastModified: f.lastModifiedSync().millisecondsSinceEpoch,
                size: f.lengthSync()));
          } else if (element is Directory) {
            files.add(
                FileModel(name: name, type: 'dir', absolute: element.path));
          }
        });
      } catch (e) {
        debugPrint('$e');
        Toast.showToast('$e');
      }
    }
    setState(() {});
  }

  ///长按菜单
  void _onLongPress(FileModel f) {
    if (!f.readOnly) {
      //弹出上下文菜单
      showContextMenuDialog(
              context,
              <String>[
                localizationOptions.fileOpen,
                localizationOptions.fileRename,
                localizationOptions.fileDelete
              ],
              title: f.name)
          .then((index) {
        if (index != null) {
          debugPrint('ContextMenu $index clicked');
          switch (index) {
            case 0:
              _openFile(f);
              break;
            case 1:
              //弹出重命名对话框
              showInputDialog(context,
                      title: '${localizationOptions.fileRename} ${f.name}',
                      initValue: f.name!)
                  .then((str) {
                debugPrint('Rename input $str');
                if (str != null && str.isNotEmpty && f.name != str) {
                  String newpath = f.absolute!
                          .substring(0, f.absolute!.lastIndexOf('/') + 1) +
                      str;
                  debugPrint('Rename to $newpath');
                  try {
                    if (f.isDir) {
                      Directory(f.absolute!).renameSync(newpath);
                    } else {
                      File(f.absolute!).renameSync(newpath);
                    }
                    _reloadCurrentSubs();
                  } catch (e) {
                    debugPrint('$e');
                    Toast.showToast('$e');
                  }
                }
              });
              break;
            case 2:
              bool isDir = FileSystemEntity.isDirectorySync(f.absolute!);
              if (isDir) {
                Directory(f.absolute!).deleteSync(recursive: true);
              } else {
                File(f.absolute!).deleteSync(recursive: true);
              }
              _reloadCurrentSubs();
              Toast.showToast(localizationOptions.fileDeleteSuccess);
              break;
          }
        }
      });
    }
  }

  //todo 打开文件
  void _openFile(FileModel f) {}

  Widget _buildItemWidget(FileModel f) {
    String lastTime = f.lastModified > 0
        ? DateFormat('yyyy-MM-dd HH:mm:ss')
            .format(DateTime.fromMillisecondsSinceEpoch(f.lastModified))
        : '';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        //open dir or file
        if (f.isDir) {
          _history.add(f);
          _reloadCurrentSubs();
        } else {
          _openFile(f);
        }
      },
      onLongPress: () {
        _onLongPress(f);
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 48),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Icon(f.isDir ? Icons.folder : Icons.insert_drive_file),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    f.name ?? '',
                    style: TextStyle(),
                    maxLines: 2,
                  ),
                  Visibility(
                    visible: !f.isDir,
                    child: Row(
                      children: <Widget>[
                        Text(
                          f.sizeStr,
                          style: TextStyle(color: Colors.black26, fontSize: 12),
                        ),
                        SizedBox(width: 8),
                        Text(
                          lastTime,
                          style: TextStyle(color: Colors.black26, fontSize: 12),
                        )
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

///所有可用目录
Future<List<FileModel>> listAllDirs() async {
  List<FileModel> all = <FileModel>[];
  if (Platform.isAndroid) {
    final appDir = await getApplicationSupportDirectory();
    all.add(FileModel(
        name: 'AppDir',
        type: 'dir',
        readOnly: true,
        absolute: appDir.path.substring(0, appDir.path.lastIndexOf('/'))));
    final exAppDir = await (getExternalStorageDirectory());
    if (exAppDir != null) {
      List<String> ps = exAppDir.path.split('/');
      all.add(FileModel(
          name: 'ExtAppDir',
          type: 'dir',
          readOnly: true,
          absolute: ps.sublist(0, ps.length - 1).join('/')));
      all.add(FileModel(
          name: 'ExtRoot',
          type: 'dir',
          readOnly: true,
          absolute: ps.sublist(0, ps.length - 4).join('/')));
    }
  } else {
    //ios
    final docDir = await getApplicationDocumentsDirectory();
    all.add(FileModel(
        name: 'DocumentsDir',
        type: 'dir',
        readOnly: true,
        absolute: docDir.path));
    final supportDir = await getApplicationSupportDirectory();
    all.add(FileModel(
        name: 'SupportDir',
        type: 'dir',
        readOnly: true,
        absolute: supportDir.path));
  }
  //添加自定义要显示的文件夹
  Debugger.instance.customRootDirs.forEach((key, value) {
    all.add(FileModel(name: key, type: 'dir', readOnly: true, absolute: value));
  });
  return all;
}
