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

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:k_debug_tools_web/src/app/app_register.dart';
import 'package:k_debug_tools_web/src/widgets/toast.dart';
import 'bloc_provider.dart';
import 'widgets/common_widgets.dart';

class AppWindowBloc extends BlocBase {
  final GlobalKey<OverlayState> appWindowOverlayKey = GlobalKey<OverlayState>();

  final AppItem appItem;
  final ActionCallback onFocus;
  final ActionCallback onClose;
  final ValueSetter<bool> onFullScreen;
  final ValueSetter<bool> onMinimize;
  bool isFullScreen = false;
  bool isMinimize = false;

  Alignment get windowAlignment => appItem.windowAlignment;

  bool get canResize => appItem.canResize;

  bool get canMove => appItem.canMove;

  Size get defaultSize => appItem.defaultSize ?? Size(640, 480);

  AppWindowBloc(
      {@required this.appItem,
      this.onFocus,
      this.onClose,
      this.onFullScreen,
      this.onMinimize});

  ///toast
  void toast(String content) {
    KIToast.showToast(content, context: appWindowOverlayKey.currentContext);
  }

  ///dialog
  void showDialog(
      {String title,
      @required String msg,
      bool barrierDismissible = true,
      @required List<DialogAction> actions}) {
    OverlayEntry _dialogOverlay;
    Widget dialog = AlertDialog(
      title: title != null ? Text(title) : null,
      content: Text(msg ?? ''),
      actions: actions
          .map((action) => FlatButton(
              textTheme: action.isPositive
                  ? ButtonTextTheme.normal
                  : ButtonTextTheme.accent,
              onPressed: () {
                if (action.handler != null) {
                  action.handler(DialogController(_dialogOverlay));
                }
              },
              child: Text(action.text)))
          .toList(growable: false),
    );
    _dialogOverlay = OverlayEntry(
      builder: (_) => Container(
        child: Stack(
          children: <Widget>[
            GestureDetector(
              onTap: () {
                //点击外面蒙层取消
                if (barrierDismissible) {
                  _dialogOverlay.remove();
                }
              },
              child: Container(
                color: Colors.black26,
              ),
            ),
            dialog,
          ],
        ),
      ),
    );
    appWindowOverlayKey.currentState.insert(_dialogOverlay);
  }

  void setFocus() {
    if (onFocus != null) {
      onFocus();
    }
  }

  void close() {
    if (onClose != null) {
      onClose();
    }
  }

  void toggleFullScreen() {
    isFullScreen = !isFullScreen;
    if (onFullScreen != null) {
      onFullScreen(isFullScreen);
    }
  }

  void toggleMinimize() {
    isMinimize = !isMinimize;
    if (onMinimize != null) {
      onMinimize(isMinimize);
    }
  }

  @override
  void dispose() {}
}

typedef DialogActionCallback = void Function(DialogController);

class DialogController {
  OverlayEntry _dialog;

  DialogController(this._dialog);

  void dismiss() {
    _dialog?.remove();
  }
}

class DialogAction {
  String text;
  DialogActionCallback handler;
  bool isPositive = false;

  DialogAction({@required this.text, this.handler, this.isPositive = false});
}
