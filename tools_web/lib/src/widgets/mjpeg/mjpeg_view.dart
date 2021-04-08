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

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'mjpeg_controller.dart';
//todo 目前请求还是block 无法加载数据
class MjpegView extends StatefulWidget {
  MjpegView(
      {Key key,
      @required this.controller,
      this.fit = BoxFit.contain,
      this.quality = FilterQuality.medium,
      this.color = Colors.black,
      this.statusBuilder,
      this.errorBuilder,
      this.noImageWidget})
      : assert(controller != null),
        this.key = key ?? UniqueKey(),
        super(key: ObjectKey(key));

  final Key key;
  final MjpegController controller;
  final BoxFit fit;
  final FilterQuality quality;
  final Color color;
  final Widget Function(
          BuildContext context, MjpegControllerStatusValue status, Widget child)
      statusBuilder;
  final Widget Function(BuildContext context, Object error) errorBuilder;
  final Widget noImageWidget;

  _MjpegViewState createState() => new _MjpegViewState();
}

class _MjpegViewState extends State<MjpegView> {
  bool _isVisible = false;
  double errMsgFontSize = 10.0;
  GlobalKey gKey = new GlobalKey();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      var size = this.gKey.currentContext.size;
      var min = math.min(size.width, size.height);

      min = math.max(min * 0.1, 10.0);
      this.setState(() => this.errMsgFontSize = min);
    });
  }

  @override
  void dispose() {
    super.dispose();
    this.widget.controller.removeSubscriber(this);
  }

  void updateVisible(bool visible) {
    if (visible == this._isVisible) return;

    this._isVisible = visible;
    if (visible)
      this.widget.controller.addSubscriber(this);
    else
      this.widget.controller.removeSubscriber(this);
  }

  Widget _getStatusBuilder(
      BuildContext context, MjpegControllerStatusValue status, Widget child) {
    if (this.widget.statusBuilder != null)
      return this.widget.statusBuilder(context, status, child);
    else if (status == MjpegControllerStatusValue.unknow) {
      return Container();
    } else if (status == MjpegControllerStatusValue.loading) {
      return Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(),
        ),
      );
    } else if (status == MjpegControllerStatusValue.ready) {
      return GestureDetector(
          child: Icon(Icons.play_arrow, color: Colors.white),
          onTap: this.widget.controller.play);
    } else if (status == MjpegControllerStatusValue.paused) {
      return Stack(
        children: [
          Positioned(child: child),
          Positioned(
              child: ConstrainedBox(
                  constraints: BoxConstraints.expand(),
                  child: GestureDetector(
                      child: Icon(Icons.play_arrow, color: Colors.white),
                      onTap: this.widget.controller.play)))
        ],
      );
    } else if (status == MjpegControllerStatusValue.playing) {
      return Stack(
        children: [
          Positioned(child: child),
          Positioned(
              child: ConstrainedBox(
                  constraints: BoxConstraints.expand(),
                  child: GestureDetector(
                      child: Icon(Icons.pause, color: Colors.white),
                      onTap: this.widget.controller.pause)))
        ],
      );
    } else if (status == MjpegControllerStatusValue.stopped) {
      return Stack(
        children: [
          Positioned(child: child),
          Positioned(
              child: ConstrainedBox(
                  constraints: BoxConstraints.expand(),
                  child: GestureDetector(
                      child: Icon(Icons.play_arrow, color: Colors.white),
                      onTap: this.widget.controller.play)))
        ],
      );
    } else {
      return Stack(
        children: [
          Positioned(child: child),
          Positioned(
              child: Center(
                  child: Icon(Icons.do_not_disturb, color: Colors.redAccent)))
        ],
      );
    }
  }

  Widget _getErrorBuilder(BuildContext context, Object error, Widget child) {
    if (error != null) {
      if (this.widget.errorBuilder != null)
        return this.widget.errorBuilder(context, error);
      else {
        return Container(
          padding: EdgeInsets.all(5),
          child: Text(
            error.toString(),
            overflow: TextOverflow.clip,
            style: TextStyle(color: Colors.red, fontSize: this.errMsgFontSize),
          ),
        );
      }
    }

    return child;
  }

  Widget _getImageWidget(MemoryImage image) {
    if (image == null) {
      if (this.widget.noImageWidget != null)
        return this.widget.noImageWidget;
      else
        return Container(color: Colors.black);
    }
    return Image(
        image: image,
        fit: this.widget.fit,
        gaplessPlayback: true,
        filterQuality: this.widget.quality,
        errorBuilder: (context, error, _) =>
            this.widget.errorBuilder(context, error));
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
        key: this.gKey,
        constraints: BoxConstraints.expand(),
        child: Container(
          color: this.widget.color,
          child: VisibilityDetector(
            key: this.widget.key,
            onVisibilityChanged: (VisibilityInfo info) =>
                this.updateVisible(info.visibleFraction > 0.1),
            child: ChangeNotifierProvider<MjpegErrorMessage>.value(
                value: this.widget.controller.errMsg,
                child: Consumer<MjpegErrorMessage>(
                  builder: (context, error, child) {
                    var statusWidget =
                        ChangeNotifierProvider<MjpegControllerStatus>.value(
                            value: this.widget.controller.status,
                            child: Consumer<MjpegControllerStatus>(
                                builder: (context, status, child) {
                              var imgWidget =
                                  ChangeNotifierProvider<MjpegFrameImage>.value(
                                      value: this.widget.controller.frame,
                                      child: Consumer<MjpegFrameImage>(
                                          builder: (context, image, child) {
                                        return ConstrainedBox(
                                            constraints:
                                                BoxConstraints.expand(),
                                            child: this
                                                ._getImageWidget(image.value));
                                      }));

                              return this._getStatusBuilder(
                                  context, status.value, imgWidget);
                            }));

                    return this
                        ._getErrorBuilder(context, error.value, statusWidget);
                  },
                )),
          ),
        ));
  }
}
