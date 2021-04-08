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
import 'dart:ui';
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:k_debug_tools/src/model/base_model.dart';

import '../widgets/list_widgets.dart';

class DeviceInfoPage extends StatefulWidget {
  @override
  _DeviceInfoPageState createState() => _DeviceInfoPageState();
}

class _DeviceInfoPageState extends State<DeviceInfoPage> {
  bool _inited = false;
  List<BaseKeyValue> _basekvs = List();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!_inited) {
      _inited = true;
      _initInfo(context);
    }
    return ListView.separated(
      controller: ScrollController(),
      padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
      itemCount: _basekvs.length,
      itemBuilder: (BuildContext context, int i) {
        return SimpleListInfoWidget(
          label: _basekvs[i].key,
          value: _basekvs[i].value,
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return Divider(height: 1, color: Color(0xff000000));
      },
    );
  }

  void _initInfo(context) async {
    //device
    DeviceInfoPlugin deviceInfo = new DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo _androidInfo = await deviceInfo.androidInfo;
      _basekvs.add(BaseKeyValue('androidId', _androidInfo.androidId));
      _basekvs.add(BaseKeyValue(
        'brand/manufacturer',
        '${_androidInfo.brand}/${_androidInfo.manufacturer}',
      ));
      _basekvs.add(BaseKeyValue(
        'model',
        '${_androidInfo.model}',
      ));
      _basekvs.add(BaseKeyValue(
        'release',
        'Android ${_androidInfo.version?.release}',
      ));
      _basekvs.add(BaseKeyValue(
        'Android sdkInt',
        '${_androidInfo.version?.sdkInt}',
      ));
      //屏幕信息
      _addWindowInfo();
      _basekvs.add(BaseKeyValue(
        'codename',
        '${_androidInfo.version?.codename}',
      ));
      _basekvs.add(BaseKeyValue(
        'incremental',
        '${_androidInfo.version?.incremental}',
      ));

      _basekvs.add(BaseKeyValue(
        'fingerprint',
        '${_androidInfo.fingerprint}',
      ));
      _basekvs.add(BaseKeyValue(
        'hardware',
        '${_androidInfo.hardware}',
      ));
      _basekvs.add(BaseKeyValue(
        'host',
        '${_androidInfo.host}',
      ));

      _basekvs.add(BaseKeyValue(
        'id',
        '${_androidInfo.id}',
      ));

      _basekvs.add(BaseKeyValue(
        'product',
        '${_androidInfo.product}',
      ));
      _basekvs.add(BaseKeyValue(
        'tags',
        '${_androidInfo.tags}',
      ));
    } else if (Platform.isIOS) {
      IosDeviceInfo _iosInfo = await deviceInfo.iosInfo;
      _basekvs.add(BaseKeyValue(
        'name',
        '${_iosInfo.name}',
      ));
      _basekvs.add(BaseKeyValue(
        'systemName',
        '${_iosInfo.systemName}',
      ));
      _basekvs.add(BaseKeyValue(
        'systemVersion',
        '${_iosInfo.systemVersion}',
      ));
      //屏幕信息
      _addWindowInfo();
      _basekvs.add(BaseKeyValue(
        'model',
        '${_iosInfo.model}',
      ));
      _basekvs.add(BaseKeyValue(
        'identifierForVendor',
        '${_iosInfo.identifierForVendor}',
      ));

      _basekvs.add(BaseKeyValue(
        'sysname',
        '${_iosInfo.utsname.sysname}',
      ));
      _basekvs.add(BaseKeyValue(
        'nodename',
        '${_iosInfo.utsname.nodename}',
      ));
      _basekvs.add(BaseKeyValue(
        'release',
        '${_iosInfo.utsname.release}',
      ));
      _basekvs.add(BaseKeyValue(
        'version',
        '${_iosInfo.utsname.version}',
      ));
      _basekvs.add(BaseKeyValue(
        'machine',
        '${_iosInfo.utsname.machine}',
      ));
    }
    _addPlatformInfo();
    setState(() {});
  }

  void _addWindowInfo() {
    //window
    _basekvs.add(
        BaseKeyValue('devicePixelRatio', window.devicePixelRatio.toString()));
    _basekvs.add(
        BaseKeyValue('textScaleFactor', window.textScaleFactor.toString()));
    _basekvs.add(BaseKeyValue('physicalSize', window.physicalSize.toString()));
    _basekvs.add(BaseKeyValue(
        'topPadding', MediaQuery.of(context).padding.top.toString()));
    _basekvs.add(BaseKeyValue(
        'bottomPadding', MediaQuery.of(context).padding.bottom.toString()));
  }

  void _addPlatformInfo() {
    _basekvs.add(BaseKeyValue(
      'numberOfProcessors',
      '${Platform.numberOfProcessors}',
    ));
    _basekvs.add(BaseKeyValue(
      'localeName',
      '${Platform.localeName}',
    ));
    _basekvs.add(BaseKeyValue(
      'operatingSystemVersion',
      '${Platform.operatingSystemVersion}',
    ));
    _basekvs.add(BaseKeyValue(
      'localHostname',
      '${Platform.localHostname}',
    ));
  }
}
