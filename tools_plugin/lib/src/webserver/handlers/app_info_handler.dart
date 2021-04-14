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

import 'package:k_debug_tools/src/model/base_model.dart';
import 'package:package_info/package_info.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart' as shelf;

import '../handler_def.dart';

///应用信息
class AppInfoHandler extends AbsAppHandler {
  @override
  shelf.Router get router {
    final router = shelf.Router();
    router.get('/info', _info);
    return router;
  }

  Future<Response> _info(Request request) async {
    Map<String, Object> data = Map<String, Object>();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    data['appName'] = packageInfo.appName;
    data['package'] = packageInfo.packageName;
    data['version'] = packageInfo.version;
    data['buildNumber'] = packageInfo.buildNumber;
    List<BaseKeyValue> kvs = <BaseKeyValue>[];
    data['extra'] = kvs;

    kvs.add(BaseKeyValue(
      'buildTime',
      const String.fromEnvironment('BUILD_TIME'),
    ));

    kvs.add(BaseKeyValue(
      'gitBranch',
      const String.fromEnvironment('GIT_BRANCH'),
    ));

    kvs.add(BaseKeyValue(
      'gitCommit',
      const String.fromEnvironment('GIT_COMMIT'),
    ));

    kvs.add(BaseKeyValue(
      'jenkinsBuildId',
      const String.fromEnvironment('JENKINS_BUILD_ID'),
    ));

    return ok(data);
  }
}
