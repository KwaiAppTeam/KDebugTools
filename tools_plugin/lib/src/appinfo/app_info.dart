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

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info/package_info.dart';
import 'package:flutter/foundation.dart' as Foundation;
import '../widgets/list_widgets.dart';

class AppInfoPage extends StatefulWidget {
  @override
  _AppInfoPageState createState() => _AppInfoPageState();
}

class _AppInfoPageState extends State<AppInfoPage> {
  List<Widget> _widgets = <Widget>[];

  @override
  void initState() {
    _buildInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: ScrollController(),
      padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
      itemCount: _widgets.length,
      itemBuilder: (BuildContext context, int index) {
        return _widgets[index];
      },
      separatorBuilder: (BuildContext context, int index) {
        return Divider(height: 1, color: Color(0xff000000));
      },
    );
  }

  void _buildInfo() async {
    _widgets.clear();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    String appName = packageInfo.appName;
    String packageName = packageInfo.packageName;
    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;
    _widgets.add(SimpleListInfoWidget(
      label: 'appName',
      value: appName,
    ));
    _widgets.add(SimpleListInfoWidget(
      label: 'package',
      value: packageName,
    ));
    _widgets.add(SimpleListInfoWidget(
      label: 'version',
      value: version,
    ));
    _widgets.add(SimpleListInfoWidget(
      label: 'buildNumber',
      value: buildNumber,
    ));

    if (Foundation.kDebugMode) {
      _widgets.add(SimpleListInfoWidget(
        label: 'runMode',
        value: 'Debug',
      ));
    }

    if (Foundation.kProfileMode) {
      _widgets.add(SimpleListInfoWidget(
        label: 'runMode',
        value: 'Profile',
      ));
    }

    if (Foundation.kReleaseMode) {
      _widgets.add(SimpleListInfoWidget(
        label: 'runMode',
        value: 'Release',
      ));
    }

    _widgets.add(SimpleListInfoWidget(
      label: 'buildTime',
      value: const String.fromEnvironment('BUILD_TIME'),
    ));

    _widgets.add(SimpleListInfoWidget(
      label: 'gitBranch',
      value: const String.fromEnvironment('GIT_BRANCH'),
    ));

    _widgets.add(SimpleListInfoWidget(
      label: 'gitCommit',
      value: const String.fromEnvironment('GIT_COMMIT'),
    ));

    _widgets.add(SimpleListInfoWidget(
      label: 'jenkinsBuildId',
      value: const String.fromEnvironment('JENKINS_BUILD_ID'),
    ));

    setState(() {});
  }
}
