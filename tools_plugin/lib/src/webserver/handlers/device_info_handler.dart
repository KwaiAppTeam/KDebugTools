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
import 'dart:ui';

import 'package:device_info/device_info.dart';
import 'package:flutter/widgets.dart';
import 'package:k_debug_tools/k_debug_tools.dart';
import 'package:k_debug_tools/src/model/base_model.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart' as shelf;

import '../handler_def.dart';

///设备信息
class DeviceInfoHandler extends AbsAppHandler {
  final Map<String, Object> dataCache = Map<String, Object>();

  @override
  shelf.Router get router {
    final router = shelf.Router();
    router.get('/info', _info);
    return router;
  }

  Future<Response> _info(Request request) async {
    if (dataCache.isNotEmpty) {
      return ok(dataCache);
    }
    DeviceInfoPlugin deviceInfo = new DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo _androidInfo = await deviceInfo.androidInfo;
      dataCache['brand'] = _androidInfo.brand;
      dataCache['model'] = _androidInfo.model;
      dataCache['version'] = _androidInfo.version?.release;
      dataCache['identifier'] = _androidInfo.androidId;
      dataCache['extra'] = _buildExtra(androidInfo: _androidInfo);
    } else if (Platform.isIOS) {
      IosDeviceInfo _iosInfo = await deviceInfo.iosInfo;
      dataCache['brand'] = 'Apple';
      dataCache['model'] = _iosInfo.utsname.machine;
      dataCache['version'] = _iosInfo.systemVersion;
      dataCache['identifier'] = _iosInfo.identifierForVendor;
      dataCache['extra'] = _buildExtra(iosInfo: _iosInfo);
    }
    BuildContext ctx = await Debugger.instance.appContext.future;
    dataCache['window'] = _buildWindowInfo(ctx);
    dataCache['platform'] = _buildPlatformInfo();

    return ok(dataCache);
  }

  List<BaseKeyValue> _buildExtra(
      {AndroidDeviceInfo androidInfo, IosDeviceInfo iosInfo}) {
    List<BaseKeyValue> result = List<BaseKeyValue>();
    if (androidInfo != null) {
      result.add(BaseKeyValue('androidId', androidInfo.androidId));
      result.add(BaseKeyValue(
        'VERSION.sdkInt',
        '${androidInfo.version?.sdkInt}',
      ));
      result.add(BaseKeyValue(
        'VERSION.codename',
        '${androidInfo.version?.codename}',
      ));
      result.add(BaseKeyValue(
        'VERSION.incremental',
        '${androidInfo.version?.incremental}',
      ));
      result.add(BaseKeyValue(
        'fingerprint',
        '${androidInfo.fingerprint}',
      ));
      result.add(BaseKeyValue(
        'hardware',
        '${androidInfo.hardware}',
      ));
      result.add(BaseKeyValue(
        'host',
        '${androidInfo.host}',
      ));
      result.add(BaseKeyValue(
        'id',
        '${androidInfo.id}',
      ));
      result.add(BaseKeyValue(
        'product',
        '${androidInfo.product}',
      ));
      result.add(BaseKeyValue(
        'tags',
        '${androidInfo.tags}',
      ));
    } else if (iosInfo != null) {
      result.add(BaseKeyValue(
        'name',
        '${iosInfo.name}',
      ));
      result.add(BaseKeyValue(
        'systemName',
        '${iosInfo.systemName}',
      ));

      result.add(BaseKeyValue(
        'identifierForVendor',
        '${iosInfo.identifierForVendor}',
      ));
      result.add(BaseKeyValue(
        'utsname.sysname',
        '${iosInfo.utsname.sysname}',
      ));
      result.add(BaseKeyValue(
        'utsname.nodename',
        '${iosInfo.utsname.nodename}',
      ));
      result.add(BaseKeyValue(
        'utsname.release',
        '${iosInfo.utsname.release}',
      ));
      result.add(BaseKeyValue(
        'utsname.version',
        '${iosInfo.utsname.version}',
      ));
    }
    return result;
  }

  List<BaseKeyValue> _buildWindowInfo(BuildContext context) {
    List<BaseKeyValue> result = List<BaseKeyValue>();
    //window
    result.add(
        BaseKeyValue('devicePixelRatio', window.devicePixelRatio.toString()));
    result.add(
        BaseKeyValue('textScaleFactor', window.textScaleFactor.toString()));
    result.add(BaseKeyValue('physicalSize', window.physicalSize.toString()));
    result.add(BaseKeyValue('topPadding', window.padding.top.toString()));
    result.add(BaseKeyValue('bottomPadding', window.padding.bottom.toString()));
    return result;
  }

  List<BaseKeyValue> _buildPlatformInfo() {
    List<BaseKeyValue> result = List<BaseKeyValue>();
    result.add(
        BaseKeyValue('numberOfProcessors', '${Platform.numberOfProcessors}'));
    result.add(BaseKeyValue('localeName', '${Platform.localeName}'));
    result.add(BaseKeyValue(
        'operatingSystemVersion', '${Platform.operatingSystemVersion}'));
    result.add(BaseKeyValue('localHostname', '${Platform.localHostname}'));
    return result;
  }
}
