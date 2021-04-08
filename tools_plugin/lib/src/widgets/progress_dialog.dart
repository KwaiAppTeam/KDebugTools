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

class ProgressDialog extends Dialog {
  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: LoadingContent(false),
    );
  }
}

class LoadingContent extends StatefulWidget {
  final bool _centerOnly;

  LoadingContent(this._centerOnly);

  @override
  LoadingState createState() => LoadingState(_centerOnly);
}

class LoadingState extends State<LoadingContent>
    with SingleTickerProviderStateMixin {
  final bool _centerOnly;

  LoadingState(this._centerOnly);

  AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
    _animationController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    if (_centerOnly) {
      return _center();
    } else {
      return Center(
        heightFactor: 1,
        widthFactor: 1,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10.0)),
          child: _center(),
        ),
      );
    }
  }

  Widget _center() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        RotationTransition(
          turns: Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
              parent: _animationController, curve: Curves.linear)),
          child: Container(
              height: 60.0,
              width: 60.0,
              child: Icon(
                Icons.rotate_right,
                size: 36,
                color: Colors.white,
              )),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

showLoadingDialog(BuildContext context) {
  showDialog(
      context: context,
      builder: (context) => ProgressDialog(),
      barrierDismissible: false);
}

dismissLoadingDialog(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop(context);
}
