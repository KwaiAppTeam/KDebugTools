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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:k_debug_tools_web/src/app/photomanager/photo_models.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../web_http.dart';

class AssetItemThumbWidget extends StatefulWidget {
  final Asset asset;
  final String thumbUrl;
  final bool showVideoIcon;

  const AssetItemThumbWidget(
      {Key key,
      @required this.asset,
      @required this.thumbUrl,
      this.showVideoIcon = true})
      : super(key: key);

  @override
  _AssetItemThumbWidgetState createState() => _AssetItemThumbWidgetState();
}

class _AssetItemThumbWidgetState extends State<AssetItemThumbWidget> {
  ValueNotifier<bool> _showImage = ValueNotifier(false);
  bool _hasShown = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
        key: Key(widget.thumbUrl),
        onVisibilityChanged: (info) {
          _showImage.value = _hasShown || info.visibleFraction > 0;
          _hasShown = _showImage.value;
        },
        child: ValueListenableBuilder(
          valueListenable: _showImage,
          builder: (ctx, showImage, child) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Visibility(
                    visible: showImage,
                    child: CachedNetworkImage(
                      placeholder: (context, url) => Container(),
                      imageUrl: widget.thumbUrl,
                      httpHeaders: {'Token': getToken()},
                      imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
                    )),
                Positioned(
                    top: 3,
                    left: 3,
                    child: (widget.showVideoIcon && widget.asset.type == 2)
                        ? Icon(Icons.slideshow_rounded)
                        : Container())
              ],
            );
          },
        ));
  }
}
