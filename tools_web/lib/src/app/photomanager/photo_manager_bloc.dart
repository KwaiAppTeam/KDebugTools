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
import 'dart:collection';
import 'dart:html' as html;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'package:k_debug_tools_web/src/widgets/item_picker.dart';
import 'package:rxdart/subjects.dart';
import 'package:flutter/widgets.dart';
import 'package:k_debug_tools_web/src/bloc_provider.dart';
import 'package:k_debug_tools_web/src/web_http.dart';
import '../../app_window_bloc.dart';
import '../../web_bloc.dart';
import '../app_register.dart';
import '../model.dart';
import 'asset_preview.dart';
import 'photo_models.dart';

enum SortType { createDesc, createAsc }
enum TypeFilter { All, Photo, Video }

class PhotoManagerBloc extends AppBlocBase {
  static const String PATH = 'api/photo';

  ItemPicker<Asset> _itemPicker;

  SortType _sortType = SortType.createDesc;

  TypeFilter _typeFilter = TypeFilter.All;

  int _photoSt = 0;

  BehaviorSubject<int> _photoSub = BehaviorSubject<int>();

  SortType get sortType => _sortType;

  TypeFilter get typeFilter => _typeFilter;

  Sink<int> get _photoSink => _photoSub.sink;

  Stream<int> get photoStream => _photoSub.stream;

  final SplayTreeSet<Album> _albumsCache = SplayTreeSet<Album>((o1, o2) {
    //按数量倒序 按名称升序
    if (o1.assetCount > o2.assetCount) {
      return -1;
    } else if (o1.assetCount < o2.assetCount) {
      return 1;
    } else {
      return o1.name.compareTo(o2.name);
    }
  });
  final Map<String, List<Asset>> _albumAssetCache = Map<String, List<Asset>>();

  ItemPicker<Asset> get itemPicker => _itemPicker;

  ///当前显示的相册
  Album _showingAlbum;

  Album get showingAlbum => _showingAlbum;

  SplayTreeSet<Album> get albums => _albumsCache;

  WebBloc _webBloc;
  AppWindowBloc _windowBloc;

  PhotoManagerBloc(context) : super(context) {
    _webBloc = BlocProvider.of<WebBloc>(context).first;
    _windowBloc = BlocProvider.of<AppWindowBloc>(context).first;
    _itemPicker = ItemPicker<Asset>(context);
    _itemPicker.addListener(() {
      notifyFileChanged();
    });
  }

  ///初始化相册数据
  Future<SplayTreeSet<Album>> fetchAlbums() async {
    Uri uri = Uri.http(getHost(), '$PATH/album');
    var response = await httpGet(uri);
    Map<String, Object> jsonResponse = convert.jsonDecode(response.body);
    if (response.statusCode == 200) {
      List list = (jsonResponse['data'] as Map)['albums'] as List;
      List<Album> albums = <Album>[];
      list.forEach((element) {
        albums.add(Album.fromJson(element as Map<String, dynamic>));
      });
      _albumsCache.clear();
      _albumsCache.addAll(albums);
      notifyFileChanged();
      return Future.value(_albumsCache);
    } else {
      return Future.error(
          ErrorResult.create('fetch data failed', jsonResponse));
    }
  }

  void notifyFileChanged([var f]) {
    _photoSink.add(++_photoSt);
  }

  ///获取相册内数据
  SplayTreeSet<Asset> getShowingAssets() {
    List<Asset> cache = _albumAssetCache['${_showingAlbum?.id}'] ?? <Asset>[];
    if (TypeFilter.Photo == _typeFilter) {
      cache = cache.where((element) => element.type == 1).toList();
    } else if (TypeFilter.Video == _typeFilter) {
      cache = cache.where((element) => element.type == 2).toList();
    }
    return _sortAssets(cache);
  }

  ///获取相册内数据
  Future<SplayTreeSet<Asset>> fetchAlbumAssets(
      {Album album, bool ignoreCache = false}) async {
    if (_albumAssetCache['${album?.id}'] != null && !ignoreCache) {
      //use cache
      return _sortAssets(_albumAssetCache['${album?.id}']);
    }
    var queryParameters = {
      'albumId': album == null ? '' : Uri.encodeFull(album.id),
    };
    Uri uri = Uri.http(getHost(), '$PATH/asset', queryParameters);
    var response = await httpGet(uri);
    Map<String, Object> jsonResponse = convert.jsonDecode(response.body);
    if (response.statusCode == 200) {
      //success
      List list = (jsonResponse['data'] as Map)['assets'] as List;
      List<Asset> assetList = <Asset>[];
      list.forEach((element) {
        assetList.add(Asset.fromJson(element as Map<String, dynamic>));
      });
      _albumAssetCache['${album?.id}'] = assetList;
      return Future.value(_sortAssets(assetList));
    } else {
      return Future.error(
          ErrorResult.create('fetch data failed', jsonResponse));
    }
  }

  SplayTreeSet<Asset> _sortAssets(List<Asset> assets) {
    Function comp;
    if (SortType.createAsc == _sortType) {
      comp = (Asset o1, Asset o2) {
        if (o1.createTs > o2.createTs) {
          return 1;
        } else if (o1.createTs < o2.createTs) {
          return -1;
        } else {
          return o1.id.compareTo(o2.id);
        }
      };
    } else {
      comp = (Asset o1, Asset o2) {
        if (o1.createTs > o2.createTs) {
          return -1;
        } else if (o1.createTs < o2.createTs) {
          return 1;
        } else {
          return o1.id.compareTo(o2.id);
        }
      };
    }

    SplayTreeSet<Asset> sorted = SplayTreeSet<Asset>(comp);
    if (assets?.isNotEmpty ?? false) {
      sorted.addAll(assets);
    }
    return sorted;
  }

  ///显示相册
  Future<void> showAlbum(Album album) async {
    _showingAlbum = album;
    notifyFileChanged();
    fetchAlbumAssets(album: album).then((value) {
      notifyFileChanged();
    });
    return Future.value();
  }

  ///下载
  Future download(List<Asset> assets) {
    var queryParameters = {
      'assetIds': Uri.encodeFull(assets.map((e) => e.id).join(',')),
      'Token': getToken()
    };
    Uri uri = Uri.http(getHost(), '$PATH/download', queryParameters);
    html.AnchorElement anchorElement =
        new html.AnchorElement(href: uri.toString());
    anchorElement.download = uri.toString();
    anchorElement.click();
    return Future.value();
  }

  ///删除
  Future<List<String>> delete(List<Asset> assets) async {
    Uri uri = Uri.http(getHost(), '$PATH/delete');
    var response = await httpPost(uri,
        body: {'assetIds': assets.map((e) => e.id).toList()});
    if (response.statusCode == 200) {
      Map<String, Object> jsonResponse = convert.jsonDecode(response.body);
      List list = (jsonResponse['data'] as Map)['files'] as List<String>;
      fetchAlbums();
      _itemPicker.clear();
      return list;
    } else {
      return Future.error(
          ErrorResult.create('Error', convert.jsonDecode(response.body)));
    }
  }

  ///上传文件
  Future uploadFile(List<html.File> files) async {
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

    Uri uri = Uri.http(getHost(), '$PATH/upload');
    for (final file in files) {
      var request = http.MultipartRequest('POST', uri);
      request.headers['Pin'] = getPin();
      final reader = new html.FileReader();
      reader.onLoad.listen((dt) {
        debugPrint('upload ${file.name} , size: ${file.size}');
        request.files.add(http.MultipartFile.fromBytes('file', reader.result,
            filename: '${file.name}'));
        request.send().then((response) {
          completedCount++;
          if (response.statusCode == 200) {
            debugPrint('upload ${file.name} complete');
            fetchAlbums();
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

  void openFile(List<Asset> assetList, Asset asset) {
    _webBloc.openNewApp(AppItem(
        name: 'AssetPreview',
        icon: Icons.image,
        contentBuilder: (ctx) {
          return AssetPreviewWindow(
            assetList: assetList,
            initIndex: assetList.indexOf(asset),
          );
        }));
  }

  @override
  void dispose() {
    _photoSub.close();
    _itemPicker.dispose();
  }

  String getThumbUrl(Asset element) {
    return '${getHostWithSchema()}/$PATH/thumb?assetId=${element.id}';
  }

  void setSort(SortType sortType) {
    _sortType = sortType;
    notifyFileChanged();
  }

  void setFilterType(TypeFilter filter) {
    _typeFilter = filter;
    notifyFileChanged();
  }

  bool hasFilter() {
    return _typeFilter != TypeFilter.All;
  }
}
