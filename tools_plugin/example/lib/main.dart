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

import 'package:flutter/material.dart';
import 'package:k_debug_tools/k_debug_tools.dart';

import 'demo_serv_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
  Debugger.instance.init(
      autoStartWebServer: true,
      autoStartHttpHook: true,
      allServEnvKeys: EnvKeys,
      allServConfigs: ServerConfigs);
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Timer? _logTimer;

  @override
  void initState() {
    super.initState();
    //auto show Debugger icon
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      Debugger.instance.showDebugger(context);
    });
    _logTimer?.cancel();
    _logTimer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
      debugPrint('debug print log...');
    });
  }

  @override
  Widget build(BuildContext context) {
    //RepaintBoundary用于flutter截图功能
    return RepaintBoundary(
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('KDebugTools'),
          ),
          body: Builder(
            builder: (ctx) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextButton(
                    onPressed: () {
                      Debugger.instance.showDebuggerDialog(ctx);
                    },
                    child: Text('Click >>> ShowDebugger'),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  TextButton(
                    onPressed: () {
                      debugPrint('request start');
                      HttpClient()
                          .getUrl(Uri.parse('https://www.kuaishou.com/'))
                          .then((value) async {
                        var resp = await value.close();
                        resp.listen((event) {}, onDone: () {
                          debugPrint('request complete');
                        });
                      });
                    },
                    child: Text('Click >>> make Http request'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
