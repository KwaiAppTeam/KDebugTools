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

import 'package:k_debug_tools/k_debug_tools.dart';

///定义所有需要配置的环境key
const List<String> EnvKeys = ['BIZ_URL', 'PASSPORT_URL', 'other'];

///定义所有环境
const List<ServerEnvConfig> ServerConfigs = [
  ServerEnvConfig(index: 0, name: '线上环境', canEdit: false, envs: {
    'PASSPORT_URL': 'https://passport.demo.com',
    'BIZ_URL': 'https://biz.demo.com',
    'other': 'someConfigs'
  }),
  ServerEnvConfig(index: 1, name: '测试环境1', canEdit: true, envs: {
    'PASSPORT_URL': 'https://passport-tst.demo.com',
    'BIZ_URL': 'https://biz-test.demo.com',
    'other': 'someConfigs'
  }),
  ServerEnvConfig(index: 2, name: '测试环境2', canEdit: true, envs: {
    'PASSPORT_URL': 'https://passport-custom.demo.com',
    'BIZ_URL': 'https://passport-custom.demo.com',
    'other': 'someConfigs'
  }),
  ServerEnvConfig(index: 3, name: '自定义', canEdit: true, envs: {}),
];
