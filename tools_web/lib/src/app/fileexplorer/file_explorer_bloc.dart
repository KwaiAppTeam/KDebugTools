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

import 'dart:async';
import 'dart:html' as html;
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'package:rxdart/subjects.dart';
import 'package:k_debug_tools_web/src/app/fileexplorer/file_explorer_models.dart';
import 'package:flutter/widgets.dart';
import 'package:k_debug_tools_web/src/app/imagepreview/image_preview.dart';
import 'package:k_debug_tools_web/src/app/texteditor/text_editor.dart';
import 'package:k_debug_tools_web/src/app/videoplayer/video_player.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/web_http.dart';
import '../../app_window_bloc.dart';
import '../../web_bloc.dart';
import '../app_register.dart';
import '../model.dart';
import 'file_explorer_models.dart';

class FileExplorerBloc extends AppBlocBase {
  static const String PATH = 'api/file';

  int _fileSt = 0;

  BehaviorSubject<int> _fileSub = BehaviorSubject<int>();

  Sink<int> get _fileSink => _fileSub.sink;

  Stream<int> get fileStream => _fileSub.stream;

  ///指定了根目录 不能跳出此目录
  String _specifiedRootDir;

  ///显示tree
  bool showTree = true;

  ///虚拟的根目录
  FileModel _rootDir;

  FileModel get rootDir => _rootDir;

  ///当前显示的目录
  FileModel get showingDir =>
      _showingHistory.isNotEmpty ? _showingHistory.last : null;

  ///是否可返回
  bool get canGoBack => _showingHistory.length > 1;

  ///是否可上传
  bool get canUpload => (showingDir?.absolute?.isNotEmpty == true);

  ///显示历史
  final List<FileModel> _showingHistory = List<FileModel>();

  WebBloc _webBloc;
  AppWindowBloc _windowBloc;

  FileExplorerBloc(context, {bool showTree = true, String rootDirPath})
      : super(context) {
    this.showTree = showTree ?? true;
    _specifiedRootDir = rootDirPath;
    _webBloc = BlocProvider.of<WebBloc>(context).first;
    _windowBloc = BlocProvider.of<AppWindowBloc>(context).first;
  }

  ///初始化根目录数据
  Future<FileModel> initRootDir() async {
    //fetch root data
    var queryParameters = {
      'path': _specifiedRootDir?.isNotEmpty == true
          ? Uri.encodeFull(_specifiedRootDir)
          : '',
    };
    Uri uri = Uri.http(getHost(), '$PATH/list', queryParameters);
    var response = await httpGet(uri);
    Map<String, Object> jsonResponse = convert.jsonDecode(response.body);
    if (response.statusCode == 200) {
      List list = (jsonResponse['data'] as Map)['files'] as List;
      List<FileModel> rootSubs = List<FileModel>();
      list.forEach((element) {
        rootSubs.add(FileModel.fromMap(element as Map<String, Object>));
      });
      _rootDir = FileModel(
          type: 'dir',
          name: 'Root',
          subFiles: rootSubs,
          absolute: _specifiedRootDir ?? '');
      _showingHistory.add(_rootDir);
      notifyFileChanged();
      return Future.value(_rootDir);
    } else {
      return Future.error(
          ErrorResult.create('fetch data failed', jsonResponse));
    }
  }

  void notifyFileChanged([var f]) {
    _fileSink.add(++_fileSt);
  }

  ///刷新当前文件夹
  Future reloadShowingDir() async {
    if (showingDir != null) {
      return loadAndShowDir(showingDir, ignoreCache: true);
    } else {
      return Future.error('no dir showing');
    }
  }

  ///列出子文件; 默认会用缓存数据
  Future<FileModel> loadDir(FileModel model, {bool ignoreCache = false}) async {
    if (model.subFiles == null || model.subFiles.isEmpty || ignoreCache) {
      model = await _fetchDir(model);
      notifyFileChanged();
    }
    return model;
  }

  ///查询子文件
  Future<FileModel> _fetchDir(FileModel model) async {
    var queryParameters = {
      'path': Uri.encodeFull(model.absolute),
    };
    Uri uri = Uri.http(getHost(), '$PATH/list', queryParameters);
    var response = await httpGet(uri);
    Map<String, Object> jsonResponse = convert.jsonDecode(response.body);
    if (response.statusCode == 200) {
      //success
      List list = (jsonResponse['data'] as Map)['files'] as List;
      List<FileModel> subFiles = <FileModel>[];
      list.forEach((element) {
        subFiles.add(FileModel.fromMap(element as Map<String, Object>));
      });
      model.subFiles = subFiles;
      notifyFileChanged();
      return Future.value(model);
    } else {
      return Future.error(
          ErrorResult.create('fetch data failed', jsonResponse));
    }
  }

  ///加载并显示文件夹; 默认会用缓存数据
  Future<FileModel> showDir(FileModel model) async {
    //标记显示文件夹
    if (showingDir?.absolute != model.absolute) {
      //加入历史记录中
      _showingHistory.add(model);
    }
    notifyFileChanged();
    return Future.value(model);
  }

  ///加载并显示文件夹; 默认会用缓存数据
  Future<FileModel> loadAndShowDir(FileModel model,
      {bool ignoreCache = false}) async {
    if (model.subFiles == null || model.subFiles.isEmpty || ignoreCache) {
      model = await _fetchDir(model);
    }
    return showDir(model);
  }

  ///查询文件类型mime
  Future<String> fetchFileMime(FileModel model) async {
    var queryParameters = {
      'path': Uri.encodeFull(model.absolute),
    };
    Uri uri = Uri.http(getHost(), '$PATH/type', queryParameters);
    var response = await httpGet(uri);
    Map<String, Object> jsonResponse = convert.jsonDecode(response.body);
    if (response.statusCode == 200) {
      //success
      String type = (jsonResponse['data'] as Map)['mime'];
      return Future.value(type);
    } else {
      return Future.error(
          ErrorResult.create('fetch type failed', jsonResponse));
    }
  }

  ///下载多个文件
  Future download(List<FileModel> files) {
    //多个文件发起多个请求进行下载
    int delayMs = 0;
    files.forEach((model) {
      new Timer(Duration(milliseconds: delayMs), () {
        var queryParameters = {
          'path': Uri.encodeFull(model.absolute),
          'Token':getToken()
        };
        Uri uri = Uri.http(getHost(), '$PATH/download', queryParameters);
        html.AnchorElement anchorElement =
            new html.AnchorElement(href: uri.toString());
        anchorElement.download = uri.toString();
        anchorElement.click();
      });
      //下一个延迟1s开始 防止浏览器拦截
      delayMs += 1000;
    });
    return Future.value();
  }

  ///下载指定文件
  Future downloadFile(String fileAbsolutePath) {
    var queryParameters = {
      'path': Uri.encodeFull(fileAbsolutePath),
      'Token':getToken()
    };
    Uri uri = Uri.http(getHost(), '$PATH/download', queryParameters);
    html.AnchorElement anchorElement =
        new html.AnchorElement(href: uri.toString());
    anchorElement.download = uri.toString();
    anchorElement.click();
    return Future.value();
  }

  ///删除文件
  Future delete(FileModel parent, List<FileModel> filesToDelete) async {
    Uri uri = Uri.http(getHost(), '$PATH/delete');
    var response = await httpPost(uri, body: {
      'pathList': filesToDelete.map((model) => model.absolute).toList()
    });
    if (response.statusCode == 200) {
      filesToDelete.forEach((element) {
        parent.subFiles.remove(element);
      });
      notifyFileChanged();
      return Future.value();
    } else {
      return Future.error(
          ErrorResult.create('Error', convert.jsonDecode(response.body)));
    }
  }

  ///重命名
  Future rename(FileModel model, String newName) async {
    String newPath =
        '${model.absolute.substring(0, 1 + model.absolute.lastIndexOf('/'))}$newName';
    if (model.absolute == newPath) {
      return Future.value();
    }
    Uri uri = Uri.http(getHost(), '$PATH/rename');
    var response = await httpPost(uri, body: {
      'path': model.absolute,
      'newPath': newPath,
    });
    if (response.statusCode == 200) {
      model.absolute = newPath;
      model.name = newName;
      notifyFileChanged();
      return Future.value();
    } else {
      return Future.error(
          ErrorResult.create('Error', convert.jsonDecode(response.body)));
    }
  }

  ///返回
  void goBack() {
    if (canGoBack) {
      _showingHistory.removeLast();
      notifyFileChanged();
    }
  }

  ///上传文件
  Future uploadFile(FileModel dir, List<html.File> files) async {
    Completer completer = Completer();
    int completedCount = 0;
    int totalCount = files.length;
    void _checkCompleted() {
      if (totalCount == completedCount) {
        debugPrint('upload ${files?.length} files completed');
        completer.complete();
      }
    }
    debugPrint('start upload ${files?.length} files...');
    var queryParameters = {
      'path': Uri.encodeFull(dir.absolute),
      'Pin':getPin()
    };
    Uri uri = Uri.http(getHost(), '$PATH/upload', queryParameters);
    for (final file in files) {
      var request = http.MultipartRequest('POST', uri);
      final reader = new html.FileReader();
      reader.onLoad.listen((dt) {
        debugPrint('upload ${file.name} , size: ${file.size}');
        request.files.add(http.MultipartFile.fromBytes('file', reader.result,
            filename: '${file.name}'));
        request.send().then((response) {
          completedCount++;
          if (response.statusCode == 200) {
            debugPrint('upload ${file.name} complete');
//                response.stream.transform(utf8.decoder).listen((value) {
//                  print(value);
//                });
          } else {
            debugPrint(
                'upload ${file.name} error, statusCode: ${response.statusCode}');
          }
          _checkCompleted();
        }).catchError((e) {
          completedCount++;
          debugPrint('$e');
          _checkCompleted();
        });
      });
      reader.onError.listen((event) {
        debugPrint('upload ${file.name} error, $event');
      });
      reader.readAsArrayBuffer(file);
    }
    return completer.future;
  }

  void openFile(FileModel fileModel) {
    //check type
    fetchFileMime(fileModel).then((value) {
      if (_canOpenAsText(value)) {
        _webBloc.openNewApp(AppItem(
            name: 'TextEditor',
            subTitle: fileModel.name,
            icon: Icons.text_fields,
            contentBuilder: (ctx) {
              return TextEditorWindow(
                filePath: fileModel.absolute,
              );
            }));
      } else if (_canOpenAsImage(value)) {
        _webBloc.openNewApp(AppItem(
            name: 'ImagePreview',
            subTitle: fileModel.name,
            icon: Icons.image,
            contentBuilder: (ctx) {
              return ImagePreviewWindow(
                filePath: fileModel.absolute,
              );
            }));
      } else if (_canOpenAsVideo(value)) {
        _webBloc.openNewApp(AppItem(
            name: 'VideoPlayer',
            subTitle: fileModel.name,
            icon: Icons.video_library,
            contentBuilder: (ctx) {
              return VideoPlayerWindow(
                filePath: fileModel.absolute,
              );
            }));
      } else {
        _windowBloc.toast('can not open: $value');
      }
    }).catchError((e) {
      _windowBloc.toast('check type error: $e');
    });
  }

  bool _canOpenAsText(String type) {
    ContentType contentType = ContentType.parse(type ?? '');
    return contentType != null &&
        (contentType.primaryType == ContentType.text.primaryType ||
            contentType.subType == ContentType.json.subType ||
            contentType.subType == 'xml');
  }

  bool _canOpenAsImage(String type) {
    ContentType contentType = ContentType.parse(type ?? '');
    return contentType != null && (contentType.primaryType == 'image');
  }

  bool _canOpenAsVideo(String type) {
    ContentType contentType = ContentType.parse(type ?? '');
    return contentType != null && (contentType.primaryType == 'video');
  }

  @override
  void dispose() {
    _fileSub.close();
  }
}
