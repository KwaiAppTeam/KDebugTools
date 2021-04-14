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

class NavigatorInfo {
  NavigatorInfo({
    this.name,
    this.routes,
  });

  String? name;
  List<RouteInfo?>? routes;

  factory NavigatorInfo.fromJson(Map<String, dynamic> json) => NavigatorInfo(
        name: json["name"],
        routes: List<RouteInfo>.from(
            json["routes"].map((x) => RouteInfo.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "routes": List<dynamic>.from(routes!.map((x) => x!.toJson())),
      };
}

class RouteInfo {
  RouteInfo({
    this.name,
    this.settings,
    this.top,
    this.left,
    this.width,
    this.height,
    this.isCurrent,
    this.childNavigators,
  });

  String? name;
  String? settings;
  double? top;
  double? left;
  double? width;
  double? height;
  bool? isCurrent;
  List<NavigatorInfo?>? childNavigators;

  factory RouteInfo.fromJson(Map<String, dynamic> json) => RouteInfo(
        name: json["name"],
        settings: json["settings"],
        top: json["top"].toDouble(),
        left: json["left"].toDouble(),
        width: json["width"].toDouble(),
        height: json["height"].toDouble(),
        isCurrent: json["isCurrent"],
        childNavigators: List<NavigatorInfo>.from(
            json["childNavigators"].map((x) => NavigatorInfo.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "settings": settings,
        "top": top,
        "left": left,
        "width": width,
        "height": height,
        "isCurrent": isCurrent,
        "childNavigators":
            List<dynamic>.from(childNavigators!.map((x) => x!.toJson())),
      };
}
