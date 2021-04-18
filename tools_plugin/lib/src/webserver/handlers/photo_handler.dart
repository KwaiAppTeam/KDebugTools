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
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:http_parser/http_parser.dart';
import 'package:http_server/http_server.dart';
import 'package:k_debug_tools/src/model/photo_models.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart' as shelf;
import 'package:archive/archive_io.dart';

import '../handler_def.dart';
import 'static_handler.dart';

class PhotoHandler extends AbsAppHandler {
  @override
  shelf.Router get router {
    final router = shelf.Router();
    //list album
    router.get('/album', _album);
    //list asset
    router.get('/asset', _asset);
    //read thumb
    router.get('/thumb', _thumb);
    //read file
    router.get('/read', _read);

    //download photo
    router.get('/download', _download);
    //delete photo
    router.post('/delete', _delete);
    //upload to default album
    router.post('/upload', _upload);

    router.all('/<ignored|.*>', (Request request) => notFound());

    return router;
  }

  ///列出所有相册
  Future<Response> _album(Request request) async {
    Map<String, Object> data = Map<String, Object>();
    List<Album> albums = <Album>[];
    data['albums'] = albums;
    List<AssetPathEntity> list = await PhotoManager.getAssetPathList();
    list.forEach((entity) {
      albums.add(Album(
          id: entity.id,
          name: entity.name,
          assetCount: entity.assetCount,
          albumType: entity.albumType));
    });
    return ok(data);
  }

  ///列出相册内容
  Future<Response> _asset(Request request) async {
    String? albumId;
    if (request.url.hasQuery &&
        request.url.queryParameters['albumId']?.isNotEmpty == true) {
      albumId = Uri.decodeFull(request.url.queryParameters['albumId']!);
    }
    Map<String, Object> data = Map<String, Object>();
    List<Asset> assets = <Asset>[];
    data['assets'] = assets;
    List<AssetPathEntity> list = await PhotoManager.getAssetPathList();
    for (var album in list) {
      if (album.id == albumId || (albumId == null && album.isAll)) {
        List<AssetEntity> assetList = await album.assetList;
        assetList.forEach((element) {
          assets.add(Asset(
            id: element.id,
            title: element.title,
            type: element.typeInt,
            duration: element.duration,
            width: element.width,
            height: element.height,
            createTs: element.createDateTime.millisecondsSinceEpoch,
          ));
        });
        break;
      }
    }
    return ok(data);
  }

  ///缩略图
  Future<Response> _thumb(Request request) async {
    String? assetId;
    if (request.url.hasQuery &&
        request.url.queryParameters['assetId']?.isNotEmpty == true) {
      assetId = Uri.decodeFull(request.url.queryParameters['assetId']!);
    }
    if (assetId == null) {
      return notFound();
    }
    AssetEntity? asset = await AssetEntity.fromId(assetId);
    if (asset == null) {
      return notFound();
    }
    String hash =
        (asset.id + asset.modifiedDateTime.toString()).hashCode.toString();
    //检查缓存
    if (request.headers[HttpHeaders.ifNoneMatchHeader] == hash) {
      return new Response.notModified();
    } else if (request.headers[HttpHeaders.ifModifiedSinceHeader] ==
        formatHttpDate(asset.modifiedDateTime)) {
      return new Response.notModified();
    }
    //缩略图数据
    Uint8List? thumb = await asset.thumbDataWithSize(128, 128, quality: 50);
    if (thumb == null) {
      return notFound();
    }
    var headers = {
      'Access-Control-Allow-Origin': '*',
      HttpHeaders.contentLengthHeader: thumb.length.toString(),
      HttpHeaders.contentTypeHeader: 'image/jpeg',
      HttpHeaders.lastModifiedHeader: formatHttpDate(asset.modifiedDateTime),
      HttpHeaders.contentMD5Header: hash,
      HttpHeaders.etagHeader: hash,
      HttpHeaders.ageHeader: '0',
      HttpHeaders.expiresHeader:
          HttpDate.format(DateTime.now().add(Duration(days: 30)).toUtc())
    };
    return Response.ok(thumb, headers: headers);
  }

  ///读取原文件
  Future<Response> _read(Request request) async {
    String? assetId;
    if (request.url.hasQuery &&
        request.url.queryParameters['assetId']?.isNotEmpty == true) {
      assetId = Uri.decodeFull(request.url.queryParameters['assetId']!);
    }
    if (assetId == null) {
      return notFound();
    }
    AssetEntity? asset = await AssetEntity.fromId(assetId);
    if (asset == null) {
      return notFound();
    }

    File? file = await asset.originFile;
    //todo remove cache in ios
    return createStaticFileHandler(file!.path,
        useHeaderBytesForContentType: true)(request);
  }

  ///删除
  Future<Response> _delete(Request request) async {
    Map body = jsonDecode(await request.readAsString());
    //assetIds
    List<String> assetIds = (body['assetIds'] as List<dynamic>).cast<String>();
    List<String> deletedIds = await PhotoManager.editor.deleteWithIds(assetIds);
    Map<String, Object> data = Map<String, Object>();
    data['deletedIds'] = deletedIds;
    return ok(data);
  }

  ///上传到相册 Multipart的name需要是file
  Future<Response> _upload(Request request) async {
    Completer<Response> completer = Completer();
    try {
      ContentType ct = ContentType.parse(request.headers['content-type']!);
      String boundary = ct.parameters['boundary']!;
      final String tempDir = (await getTemporaryDirectory()).path;
      request
          .read()
          .transform(MimeMultipartTransformer(boundary))
          .map(HttpMultipartFormData.parse)
          .map((HttpMultipartFormData formData) {
        String? name = formData.contentDisposition.parameters['name'];
        if (name == 'file') {
          String? filename = formData.contentDisposition.parameters['filename'];
          String destFile = '$tempDir/$filename';
          //找到一个不存在的文件名
          while (FileSystemEntity.typeSync(destFile) !=
              FileSystemEntityType.notFound) {
            //rename new file
            int dotIndex = filename!.indexOf('.');
            //a.png -> a-1.png;  fileA -> fileA-1
            if (dotIndex > 0) {
              filename = filename.substring(0, dotIndex) +
                  '-1' +
                  filename.substring(dotIndex);
            } else {
              filename = filename + '-1';
            }
            destFile = '$tempDir/$filename';
          }
          debugPrint('save file to $destFile...');
          IOSink sink = File(destFile).openWrite();
          sink.addStream(formData.cast()).whenComplete(() {
            debugPrint('save file to $destFile complete');
            sink.close();
            //save to album
            PhotoManager.editor.saveImageWithPath(destFile).then((value) {
              //remove temp
              File(destFile).deleteSync(recursive: true);
              completer.complete(ok(null));
            }).catchError((e) {
              completer.complete(error('$e'));
            });
          });
        }
      }).listen((event) {} as void Function(Null)?);
    } catch (e) {
      debugPrint('upload failed, $e');
      completer.complete(error('$e'));
    }
    return completer.future;
  }

  ///下载文件或文件夹
  Future<Response> _download(Request request) async {
    if (request.url.hasQuery &&
        request.url.queryParameters['assetIds']?.isNotEmpty == true) {
      String idStr = Uri.decodeFull(request.url.queryParameters['assetIds']!);
      List<String> assetIds = idStr.split(',');
      File? file;
      late String name;
      //do zip
      if (assetIds.length > 1) {
        try {
          //file = temp zipfile...
          Directory tempDir = await getTemporaryDirectory();
          //temp file name
          name = 'download_${DateTime.now().millisecondsSinceEpoch}.zip';
          file = File('${tempDir.path}/$name');
          var encoder = ZipFileEncoder();
          encoder.create(file.path);
          for (String id in assetIds) {
            AssetEntity? assetEntity = await AssetEntity.fromId(id);
            File? assetFile = await assetEntity?.originFile;
            if (assetFile != null) {
              encoder.addFile(assetFile);
            }
          }
          encoder.close();
        } catch (e) {
          return error('$e');
        }
      } else if (assetIds.isNotEmpty) {
        AssetEntity? assetEntity = await AssetEntity.fromId(assetIds[0]);
        file = await assetEntity!.originFile;
        name = file!.path.substring(1 + file.path.lastIndexOf('/'));
      }
      if (file == null || !file.existsSync()) {
        return notFound();
      }
      //write file
      Map<String, Object> headers = Map<String, Object>();
      headers[HttpHeaders.contentTypeHeader] = ContentType.binary.value;
      headers[HttpHeaders.contentLengthHeader] = '${await file.length()}';
      //file name
      headers['Content-Disposition'] =
          'attachment; filename="${Uri.encodeFull(name)}"';
      //todo delete when close
      return Response.ok(file.openRead(), headers: headers);
    } else {
      return notFound();
    }
  }
}
