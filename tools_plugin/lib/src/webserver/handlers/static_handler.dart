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
import 'dart:io';
import 'dart:math' as math;

import 'package:convert/convert.dart';
import 'package:flutter/cupertino.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';

/// The default resolver for MIME types based on file extensions.
final _defaultMimeTypeResolver = new MimeTypeResolver();

Handler createStaticFileHandler(String filePath,
    {bool useHeaderBytesForContentType: false,
    MimeTypeResolver contentTypeResolver}) {
  return (Request request) {
    var entityType = FileSystemEntity.typeSync(filePath, followLinks: true);
    File file;
    if (entityType == FileSystemEntityType.file) {
      file = new File(filePath);
    } else if (entityType == FileSystemEntityType.directory) {
      return new Response.notFound('Not Found');
    }

    if (file == null) {
      return new Response.notFound('Not Found');
    }

    return _handleFile(request, file, () async {
      return lookupMime(file,
          useHeaderBytesForContentType: useHeaderBytesForContentType,
          contentTypeResolver: contentTypeResolver);
    });
  };
}

FutureOr<String> lookupMime(File file,
    {bool useHeaderBytesForContentType: false,
    MimeTypeResolver contentTypeResolver}) async {
  contentTypeResolver ??= _defaultMimeTypeResolver;
  if (useHeaderBytesForContentType) {
    var length =
        math.min(contentTypeResolver.magicNumbersMaxLength, file.lengthSync());

    var byteSink = new ByteAccumulatorSink();

    await file.openRead(0, length).listen(byteSink.add).asFuture();
    byteSink.close(); //
    return contentTypeResolver.lookup(file.path, headerBytes: byteSink.bytes);
  } else {
    return contentTypeResolver.lookup(file.path);
  }
}

Future<String> _hash(File file, FileStat stat) async {
  String ret = '${stat.size}-${stat.modified.millisecondsSinceEpoch}';
  try {
    if (stat.size < 50 * 1024) {
      ret = md5.convert(await file.readAsBytes()).toString();
    } else {
      ret = md5.convert(utf8.encode(ret)).toString();
    }
  } catch (exception) {}

  return ret;
}

Future<Response> _handleFile(
    Request request, File file, FutureOr<String> getContentType()) async {
  var stat = file.statSync();
  var ifModifiedSince = request.ifModifiedSince;
  var hashNow = await _hash(file, stat);

  //check modified
  if (request.headers[HttpHeaders.ifNoneMatchHeader] != null) {
    String hashOld = request.headers[HttpHeaders.ifNoneMatchHeader];
    if (hashNow == hashOld) {
      //304
      return new Response.notModified();
    }
  } else if (ifModifiedSince != null) {
    var fileChangeAtSecResolution = toSecondResolution(stat.changed);
    if (!fileChangeAtSecResolution.isAfter(ifModifiedSince)) {
      return new Response.notModified();
    }
  }

  var headers = {
    //允许跨域
    'Access-Control-Allow-Origin': '*',
    HttpHeaders.contentLengthHeader: stat.size.toString(),
    HttpHeaders.lastModifiedHeader: formatHttpDate(stat.changed),
    HttpHeaders.contentMD5Header: hashNow,
    HttpHeaders.etagHeader: hashNow,
    //支持断点续传
    HttpHeaders.acceptRangesHeader: 'bytes',
    HttpHeaders.ageHeader: '0',
    HttpHeaders.cacheControlHeader: 'no-cache',
    HttpHeaders.expiresHeader:
        HttpDate.format(DateTime.now().add(Duration(days: 7)).toUtc())
  };

  var contentType = await getContentType();
  //写入类型
  if (contentType != null) headers[HttpHeaders.contentTypeHeader] = contentType;

  //是否请求部分数据
  if (request.headers[HttpHeaders.rangeHeader] != null) {
    //request:  bytes=start-end
    debugPrint('range: ${request.headers[HttpHeaders.rangeHeader]}');
    var r = request.headers[HttpHeaders.rangeHeader].split('=')[1].split('-');
    int s = r[0].isEmpty ? 0 : int.parse(r[0]);
    int e = r[1].isEmpty ? stat.size - 1 : int.parse(r[1]);
    //response: bytes 0-10/3103
    headers[HttpHeaders.contentRangeHeader] = 'bytes $s-$e/${stat.size}';
    headers[HttpHeaders.contentLengthHeader] = (1 + e - s).toString();
    return Response(206, body: file.openRead(s, e + 1), headers: headers);
  }

  return Response.ok(file.openRead(), headers: headers);
}

DateTime toSecondResolution(DateTime dt) {
  if (dt.millisecond == 0) return dt;
  return dt.subtract(new Duration(milliseconds: dt.millisecond));
}
