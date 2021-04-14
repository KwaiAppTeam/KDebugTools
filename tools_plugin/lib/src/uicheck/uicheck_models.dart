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

class FlutterCapture {
  FlutterCapture({
    this.screenWidth,
    this.screenHeight,
    this.paddingTop,
    this.paddingBottom,
    this.screenshot,
    this.rootWidget,
  });

  double? screenWidth;
  double? screenHeight;
  double? paddingTop;
  double? paddingBottom;
  String? screenshot;
  WidgetNode? rootWidget;

  factory FlutterCapture.fromJson(Map<String, dynamic> json) => FlutterCapture(
        screenWidth: json["screenWidth"],
        screenHeight: json["screenHeight"],
        paddingTop: json["paddingTop"],
        paddingBottom: json["paddingBottom"],
        screenshot: json["screenshot"],
        rootWidget: WidgetNode.fromJson(json["rootWidget"]),
      );

  Map<String, dynamic> toJson() => {
        "screenWidth": screenWidth,
        "screenHeight": screenHeight,
        "paddingTop": paddingTop,
        "paddingBottom": paddingBottom,
        "screenshot": screenshot,
        "rootWidget": rootWidget!.toJson(),
      };
}

class WidgetNode {
  WidgetNode({
    this.name,
    this.data,
    this.width,
    this.height,
    this.left,
    this.top,
    this.attrs,
    this.children,
  });

  String? name;
  String? data;
  double? width;
  double? height;
  double? left;
  double? top;
  Map<String, dynamic>? attrs;
  List<WidgetNode>? children;

  factory WidgetNode.fromJson(Map<String, dynamic> json) => WidgetNode(
        name: json["name"],
        data: json["data"],
        width: json["width"],
        height: json["height"],
        left: json["left"],
        top: json["top"],
        attrs: json["attrs"],
        children: json["children"] == null
            ? null
            : List<WidgetNode>.from(
                json["children"].map((x) => WidgetNode.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "data": data,
        "width": width,
        "height": height,
        "left": left,
        "top": top,
        "attrs": attrs,
        "children": children == null
            ? null
            : children!.map((e) => e.toJson()).toList(growable: false)
      };
}
