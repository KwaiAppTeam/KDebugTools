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

class FileModel {
  String? name;
  String? type;
  String? absolute;
  int? size;
  int lastModified;
  List<FileModel>? subFiles;
  bool readOnly = false;

  FileModel(
      {this.name,
      this.type,
      this.absolute,
      this.size,
      this.subFiles,
      this.lastModified = 0,
      this.readOnly = false});

  static fromMap(Map<String, Object> map) {
    FileModel model = FileModel();
    model.name = map['name'] as String? ?? '';
    model.type = map['type'] as String? ?? '';
    model.absolute = map['absolute'] as String? ?? '';
    model.size = map['size'] as int?;
    model.lastModified = map['lastModified'] as int? ?? 0;
    model.readOnly = map['readOnly'] as bool? ?? false;
    return model;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = Map<String, dynamic>();
    result['name'] = name;
    result['type'] = type;
    result['absolute'] = absolute;
    result['size'] = size;
    result['lastModified'] = lastModified;
    result['readOnly'] = readOnly;
    return result;
  }

  bool get isDir => type == 'dir';

  String get sizeStr => (size != null && size! > 0)
      ? '${(size! / 1024 / 1024).toStringAsFixed(2)}M'
      : '';
}
