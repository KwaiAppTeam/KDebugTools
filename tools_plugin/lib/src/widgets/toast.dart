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
import 'package:oktoast/oktoast.dart' as ok;

class Toast {
  ///
  /// top
  /// bottom
  /// center
  ///
  static void showToast(String content,
      {BuildContext? context,
      ok.ToastPosition? position,
      bool dismissOtherToast = true,
      Duration? duration}) {
    //position = ToastPosition.top;
    position = ok.ToastPosition(align: Alignment.topCenter, offset: 265);
    ok.showToast(content,
        context: context,
        position: position,
        duration: duration,
        backgroundColor: Color(0xb2000000),
        radius: 4,
        textPadding: EdgeInsets.only(left: 16, right: 16, top: 11, bottom: 11),
        textStyle: TextStyle(fontSize: 14, color: Colors.white),
        dismissOtherToast: dismissOtherToast);
  }

  static void showToastWidget(Widget widget, {ok.ToastPosition? position}) {
    showToastWidget(widget, position: position);
  }

  static void disMissToast() {
    ok.dismissAllToast();
  }

  static Widget buildKToast(
    String msg, {
    BuildContext? context,
    TextStyle textStyle = const TextStyle(fontSize: 16, color: Colors.white),
    EdgeInsetsGeometry textPadding =
        const EdgeInsets.only(left: 20, right: 20, top: 17, bottom: 17),
    Color backgroundColor = const Color(0xb2000000),
    double radius = 8,
    TextAlign? textAlign,
  }) {
    return Container(
      margin: const EdgeInsets.all(50.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      padding: textPadding,
      child: ClipRect(
        child: Text(
          msg,
          style: textStyle,
          textAlign: textAlign,
          textDirection: TextDirection.ltr,
        ),
      ),
    );
  }
}
