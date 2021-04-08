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
import 'dart:ui';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:k_debug_tools_web/src/app/app_register.dart';
import 'package:k_debug_tools_web/src/event/PinEvent.dart';
import 'package:k_debug_tools_web/src/event_bus.dart';
import 'package:k_debug_tools_web/src/theme.dart';
import 'package:k_debug_tools_web/src/web_bloc.dart';
import 'package:k_debug_tools_web/src/web_http.dart';
import 'package:k_debug_tools_web/src/websocket/web_socket_bloc.dart';
import 'package:k_debug_tools_web/src/widgets/root_navi_bar.dart';
import 'package:k_debug_tools_web/src/common_widgets.dart';

import 'src/bloc_provider.dart';
import 'src/common_widgets.dart';
import 'src/ui/theme.dart';

FirebaseAnalytics analytics = FirebaseAnalytics();

void main() {
  AppRegister.instance.registerDefault();
  analytics.setAnalyticsCollectionEnabled(true);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KDebugTools',
      theme: themeFor(isDarkTheme: true).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: devtoolsBlue[400],
        ),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  WebBloc _webBloc;
  WebSocketBloc _webSocketBloc;
  FocusNode _focusNode;
  bool _initLoading = true;
  bool _needInputPin = false;

  TextEditingController _pinEditingController = TextEditingController();

  StreamController<ErrorAnimationType> _pinErrorController;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final formKey = GlobalKey<FormState>();

  ///图标点击
  void _onAppIconClick(BuildContext ctx, AppItem appItem) {
    if (!_webBloc.isAppOpened(appItem)) {
      _webBloc.openNewApp(appItem);
      return;
    }
    _webBloc.showOpenedApp(appItem);
    return;
  }

  @override
  void initState() {
    _focusNode = FocusNode();
    _webBloc = WebBloc(context);
    _webSocketBloc = WebSocketBloc(context);
    _webSocketBloc.registerSub('init', (msg) {
      Map initInfo = jsonDecode(utf8.decode(msg.data)) as Map<String, dynamic>;
      setToken(initInfo['token']);
    });
    _pinErrorController = StreamController<ErrorAnimationType>();
    _initAuth();
    super.initState();
  }

  void _initAuth() async {
    //load pin code from local storage
    SharedPreferences pref = await SharedPreferences.getInstance();
    String p = pref.getString('_PIN') ?? '';
    if (p.isEmpty) {
      setState(() {
        _initLoading = false;
        _needInputPin = true;
      });
    } else {
      //check pin
      _checkPin(p).catchError((e) {
        setState(() {
          _initLoading = false;
          _needInputPin = true;
        });
      });
    }
  }

  Future _checkPin(String pin) async {
    var response = await httpPost(Uri.http(WebBloc.getHost(), 'api/pin/check'),
        body: {'pin': pin});
    _initLoading = false;
    if (response.statusCode == 200) {
      //verify success
      setPin(pin);
      SharedPreferences pref = await SharedPreferences.getInstance();
      pref.setString('_PIN', pin);
      _needInputPin = false;
      eventBus.fire(PinVerified());
    } else {
      _needInputPin = true;
    }
    if (_pinEditingController.text?.isNotEmpty ?? false) {
      _pinErrorController.add(ErrorAnimationType.shake);
      _pinEditingController.text = '';
    }
    setState(() {});
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _pinErrorController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: BlocProvider(
        blocs: [_webBloc],
        child: BlocProvider(
          blocs: [_webSocketBloc],
          child: StreamBuilder(
              stream: _webBloc.stateStream,
              builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                ThemeData theme = Theme.of(context);
                return Stack(
                  children: [
                    Scaffold(
                      appBar: _buildAppBar('KDebugTools'),
                      body: RawKeyboardListener(
                        autofocus: true,
                        focusNode: _focusNode,
                        onKey: _webBloc.handleOnKey,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Container(
                                padding: EdgeInsets.all(8),
                                color: theme.colorScheme.background,
                                child: ElevatedButtonTheme(
                                  data: ElevatedButtonThemeData(
                                    style: ElevatedButton.styleFrom(
                                      primary: theme.colorScheme
                                          .defaultDesktopAppItemBackground,
                                      minimumSize: const Size(
                                          buttonMinWidth, defaultButtonHeight),
                                    ),
                                  ),
                                  child: Wrap(
                                      direction: Axis.horizontal,
                                      alignment: WrapAlignment.start,
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _buildDeskTopItemWidgets()),
                                ),
                              ),
                            ),
                            //app windows
                            Overlay(
                              key: _webBloc.appAreaOverlay,
                            )
                          ],
                        ),
                      ),
                    ), //loading
                    Positioned.fill(
                      child: Visibility(
                        visible: _initLoading,
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                          child: Container(
                            color: Colors.white30,
                            child: UnconstrainedBox(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    //input pin
                    Positioned.fill(
                        child: Visibility(
                      visible: _needInputPin,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                        child: Container(
                          color: Colors.white30,
                          child: UnconstrainedBox(
                            child: _pinInput(),
                          ),
                        ),
                      ),
                    )),
                  ],
                );
              }),
        ),
      ),
    );
  }

  Widget _buildAppBar(String title) {
    Widget flexibleSpace = Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(top: 4.0, left: 160.0),
        child: RootNaviBar(),
      ),
    );

    final appBar = AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      title: Text(title),
      actions: [],
      flexibleSpace: flexibleSpace,
    );

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Hero(
        tag: 'AppBar',
        child: appBar,
      ),
    );
  }

  Widget _pinInput() {
    ThemeData theme = Theme.of(context);
    return Material(
      elevation: 20,
      child: Container(
        height: 160,
        width: 300,
        decoration: BoxDecoration(
          color: theme.colorScheme.background,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 24, 30, 12),
          child: Column(
            children: [
              DevToolsTooltip(
                tooltip: 'You can find it in device debugger panel',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Input PIN',
                        style: TextStyle(
                          color: theme.textTheme.bodyText1.color,
                          fontSize: 22,
                        )),
                    Icon(Icons.info_outline_rounded, size: 16)
                  ],
                ),
              ),
              SizedBox(
                height: 24,
              ),
              Form(
                key: formKey,
                child: PinCodeTextField(
                  appContext: context,
                  pastedTextStyle: TextStyle(
                    color: theme.textTheme.bodyText1.color,
                    fontWeight: FontWeight.bold,
                  ),
                  textStyle: TextStyle(
                    color: theme.textTheme.bodyText1.color,
                    fontWeight: FontWeight.bold,
                  ),
                  length: 4,
                  obscureText: true,
                  obscuringCharacter: '*',
                  blinkWhenObscuring: false,
                  animationType: AnimationType.fade,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(5),
                    fieldHeight: 50,
                    fieldWidth: 40,
                    selectedColor: theme.textTheme.bodyText2.color,
                    activeColor:
                        theme.textTheme.bodyText2.color.withOpacity(0.8),
                    inactiveColor:
                        theme.textTheme.bodyText2.color.withOpacity(0.8),
                  ),
                  cursorColor: theme.textTheme.bodyText1.color,
                  animationDuration: Duration(milliseconds: 300),
                  backgroundColor: Colors.transparent,
                  enableActiveFill: false,
                  errorAnimationController: _pinErrorController,
                  controller: _pinEditingController,
                  keyboardType: TextInputType.number,
                  boxShadows: [
                    BoxShadow(
                      offset: Offset(0, 1),
                      color: Colors.black12,
                      blurRadius: 10,
                    )
                  ],
                  onCompleted: (v) {
                    _checkPin(v);
                  },
                  onChanged: (v) {},
                  beforeTextPaste: (text) {
                    return false;
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  ///桌面上应用图标
  List<Widget> _buildDeskTopItemWidgets() {
    List<Widget> widgets = <Widget>[];
    AppRegister.instance.deskTopAppItems.forEach((element) {
      Widget itemWidget = Container(
        height: 128,
        width: 128,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                element.icon,
                size: 44,
                color: devtoolsGrey[50],
              ),
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  element.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: devtoolsGrey[50], fontSize: 18),
                ),
              )
            ],
          ),
        ),
      );

      widgets.add(ElevatedButton(
        onPressed: () {
          _onAppIconClick(context, element);
        },
        child: itemWidget,
      ));
    });
    return widgets;
  }
}
