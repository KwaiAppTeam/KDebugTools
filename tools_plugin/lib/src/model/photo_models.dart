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

class Album {
  Album({
    this.id,
    this.name,
    this.assetCount,
    this.albumType,
  });

  String id;
  String name;
  int assetCount;
  int albumType;

  factory Album.fromJson(Map<String, dynamic> json) => Album(
        id: json["id"],
        name: json["name"],
        assetCount: json["assetCount"],
        albumType: json["albumType"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "assetCount": assetCount,
        "albumType": albumType,
      };
}


class Asset {
  Asset({
    this.id,
    this.title,
    this.type,
    this.duration,
    this.width,
    this.height,
    this.createTs,
  });

  String id;
  String title;
  int type;
  int duration;
  int width;
  int height;
  int createTs;

  factory Asset.fromJson(Map<String, dynamic> json) => Asset(
    id: json["id"],
    title: json["title"],
    type: json["type"],
    duration: json["duration"],
    width: json["width"],
    height: json["height"],
    createTs: json["createTs"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "type": type,
    "duration": duration,
    "width": width,
    "height": height,
    "createTs": createTs,
  };
}