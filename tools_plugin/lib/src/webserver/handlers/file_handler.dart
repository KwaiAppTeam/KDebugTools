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
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http_server/http_server.dart';
import 'package:k_debug_tools/src/fileexplorer/file_explorer.dart';
import 'package:k_debug_tools/src/fileexplorer/file_explorer_models.dart';
import 'package:k_debug_tools/src/webserver/handlers/static_handler.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart' as shelf;
import 'package:archive/archive_io.dart';

import '../handler_def.dart';

class FileHandler extends AbsAppHandler {
  @override
  shelf.Router get router {
    final router = shelf.Router();
    //list file
    router.get('/list', _list);
    //download file or Directory
    router.get('/download', _download);
    //delete file or Directory
    router.post('/delete', _delete);
    //upload file
    router.post('/upload', _upload);
    //rename file
    router.post('/rename', _rename);
    //read file
    router.get('/read/<path|.*>', _read);
    router.options('/read/<path|.*>', _readOptions);
    //type file
    router.get('/type', _type);
    //save file
    router.post('/save', _save);

    router.all('/<ignored|.*>', (Request request) => notFound());

    return router;
  }

  Future<Response> _read(Request request, String path) async {
    path = Uri.decodeFull(path);
    if (FileSystemEntity.isFileSync(path)) {
      return createStaticFileHandler(path, useHeaderBytesForContentType: true)(
          request);
    } else {
      return notFound(msg: 'File $path Not Found');
    }
  }

  ///读取文件 todo
  Future<Response> _readOptions(Request request, String path) async {
    debugPrint('request options');
    Map<String, Object> headers = Map<String, String>();
    //允许跨域
    headers['Access-Control-Allow-Origin'] = '*';
    headers[HttpHeaders.allowHeader] = 'GET,POST';
    return Response.ok(null, headers: headers);
  }

  ///type文件
  Future<Response> _type(Request request) async {
    if (request.url.hasQuery &&
        request.url.queryParameters['path']?.isNotEmpty == true) {
      String path = Uri.decodeFull(request.url.queryParameters['path']!);
      if (FileSystemEntity.isFileSync(path)) {
        String? mime = await lookupMime(File(path));
        var stat = await File(path).stat();
        var data = {
          'size': stat.size,
          'mime': mime ??
              await lookupMime(File(path),
                  useHeaderBytesForContentType: true) ??
              'application/octet-stream'
        };
        return ok(data);
      } else {
        debugPrint('file $path not found');
        return notFound();
      }
    } else {
      return notFound(msg: 'path not specified');
    }
  }

  ///覆盖写入文件
  Future<Response> _save(Request request) async {
    if (request.url.hasQuery &&
        request.url.queryParameters['path']?.isNotEmpty == true) {
      String path = Uri.decodeFull(request.url.queryParameters['path']!);
      File file = File(path);
      Completer<Response> completer = Completer();
      try {
        debugPrint('save file: $path');
        String newData = await request.readAsString();
        file.writeAsString(newData, flush: true).then((value) {
          completer.complete(ok(null));
        }).catchError((e) {
          debugPrint('save failed, $e');
          completer.complete(error('$e'));
        });
      } catch (e) {
        debugPrint('save failed, $e');
        completer.complete(error('$e'));
      }
      return completer.future;
    } else {
      return notFound();
    }
  }

  ///下载文件或文件夹
  Future<Response> _download(Request request) async {
    if (request.url.hasQuery &&
        request.url.queryParameters['path']?.isNotEmpty == true) {
      String path = Uri.decodeFull(request.url.queryParameters['path']!);
      String name = path.substring(1 + path.lastIndexOf('/'));
      bool isDir = FileSystemEntity.isDirectorySync(path);
      File file;
      //do zip
      if (isDir) {
        try {
          //file = temp zipfile...
          Directory tempDir = await getTemporaryDirectory();
          //temp file name
          name = '${name}_zip_${DateTime.now().millisecondsSinceEpoch}.zip';
          file = File('${tempDir.path}/$name');
          var encoder = ZipFileEncoder();
          encoder.create(file.path);
          encoder.addDirectory(Directory(path), includeDirName: true);
          encoder.close();
        } catch (e) {
          return error('$e');
        }
      } else {
        file = File(path);
      }
      if (!file.existsSync()) {
        return notFound();
      }
      //write file
      Map<String, Object> headers = Map<String, Object>();
      headers[HttpHeaders.contentTypeHeader] = ContentType.binary.value;
      //file name
      headers['Content-Disposition'] =
          'attachment; filename="${Uri.encodeFull(name)}"';
      //todo delete when close
      return Response.ok(file.openRead(), headers: headers);
    } else {
      return notFound();
    }
  }

  ///列出文件夹的内容
  Future<Response> _list(Request request) async {
    Map<String, Object> data = Map<String, Object>();
    List<FileModel> files = <FileModel>[];
    data['files'] = files;
    if (request.url.hasQuery &&
        request.url.queryParameters['path']?.isNotEmpty == true) {
      //list file in dir
      String path = Uri.decodeFull(request.url.queryParameters['path']!);
      Directory dir = Directory(path);
      if (!dir.existsSync()) {
        return notFound();
      } else {
        data['dir'] = path;
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
          return error('$e');
        }
      }
    } else {
      //list available
      data['dir'] = '/';
      files.addAll(await listAllDirs());
    }
    return ok(data);
  }

  ///删除文件
  ///path以英文逗号分割 如 path=/aaa/aaa,/aaa/bbb将删除两个文件或文件夹
  Future<Response> _delete(Request request) async {
    Map body = jsonDecode(await request.readAsString());
    //path or pathList
    String? path = body['path'];
    List<String> pathList;
    if (path != null) {
      pathList = [path];
    } else {
      pathList = (body['pathList'] as List?)?.cast<String>() ?? <String>[];
    }
    List<String> successTask = <String>[];
    List<String> failedTask = <String>[];
    Map<String, Object> data = Map<String, Object>();
    data['successTask'] = successTask;
    data['failedTask'] = failedTask;
    pathList.forEach((path) {
      if (FileSystemEntity.typeSync(path) == FileSystemEntityType.notFound) {
        debugPrint('delete failed, file not found: $path');
        failedTask.add(path);
      }
      bool isDir = FileSystemEntity.isDirectorySync(path);
      if (isDir) {
        //delete dir
        debugPrint('delete directory: $path');
        Directory(path).deleteSync(recursive: true);
        successTask.add(path);
      } else {
        debugPrint('delete file: $path');
        File(path).deleteSync(recursive: true);
        successTask.add(path);
      }
    });
    return ok(data);
  }

  ///上传文件 path为目标文件夹, Multipart的name需要是file
  Future<Response> _upload(Request request) async {
    if (request.url.hasQuery &&
        request.url.queryParameters['path']?.isNotEmpty == true) {
      String destPath = Uri.decodeFull(request.url.queryParameters['path']!);
      String replaceTag =
          Uri.decodeFull(request.url.queryParameters['replace'] ?? '');
      Directory dest = Directory(destPath);
      if (dest.existsSync() && !FileSystemEntity.isDirectorySync(destPath)) {
        //exist but not Directory
        return error('dest path is file');
      }
      Completer<Response> completer = Completer();
      try {
        ContentType ct = ContentType.parse(request.headers['content-type']!);
        String boundary = ct.parameters['boundary']!;
        request
            .read()
            .transform(MimeMultipartTransformer(boundary))
            .map(HttpMultipartFormData.parse)
            .map((HttpMultipartFormData formData) {
          String? name = formData.contentDisposition.parameters['name'];
          if (name == 'file') {
            String filename =
                formData.contentDisposition.parameters['filename']!;
            String destFile = dest.path + '/' + filename;
            //找到一个不存在的文件名 或删除旧文件
            while (FileSystemEntity.typeSync(destFile) !=
                FileSystemEntityType.notFound) {
              if ('true' == replaceTag.toLowerCase() &&
                  FileSystemEntity.isFileSync(destFile)) {
                //delete old file
                debugPrint('remove old file $destFile');
                File(destFile).deleteSync(recursive: true);
              } else {
                //rename new file
                int dotIndex = filename.indexOf('.');
                //a.png -> a-1.png;  fileA -> fileA-1
                if (dotIndex > 0) {
                  filename = filename.substring(0, dotIndex) +
                      '-1' +
                      filename.substring(dotIndex);
                } else {
                  filename = filename + '-1';
                }
                destFile = dest.path + '/' + filename;
              }
            }
            debugPrint('save file to $destFile...');
            IOSink sink = File(destFile).openWrite();
            sink.addStream(formData.cast()).whenComplete(() {
              debugPrint('save file to $destFile complete');
              sink.close();
              //return ok
              completer.complete(ok(null));
            });
          }
        }).listen((event) {});
      } catch (e) {
        debugPrint('upload failed, $e');
        completer.complete(error('$e'));
      }
      return completer.future;
    } else {
      debugPrint('upload failed, request params invalid.');
      return error('\'path\' not specified');
    }
  }

  ///重命名文件
  ///path newPath
  Future<Response> _rename(Request request) async {
    Map body = jsonDecode(await request.readAsString());
    String path = body['path'];
    String? newpath = body['newPath'];
    //旧文件不存在
    if (FileSystemEntity.typeSync(path) == FileSystemEntityType.notFound) {
      return error('rename failed, file not exist: $path');
    }
    //新文件存在
    if (FileSystemEntity.typeSync(newpath!) != FileSystemEntityType.notFound) {
      return error('rename failed, file exist: $newpath');
    }
    try {
      if (FileSystemEntity.isDirectorySync(path)) {
        Directory(path).renameSync(newpath);
      } else {
        File(path).renameSync(newpath);
      }
    } catch (e) {
      return error('rename failed, $e');
    }
    return ok(null);
  }
}
