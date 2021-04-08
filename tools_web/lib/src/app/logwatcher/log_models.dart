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

const LogLevelTag = ['E', 'W', 'I', 'D', 'V'];
enum LogLevel {
  error,
  warn,
  info,
  debug,
  verbose,
}

class LogEntry {
  int level; //0-5:
  int time;
  String msg;

  LogEntry({this.level, this.time, this.msg});

  LogEntry.fromJson(Map<String, dynamic> json) {
    level = json['level'];
    time = json['time'];
    msg = json['msg'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['level'] = this.level;
    data['time'] = this.time;
    data['msg'] = this.msg;
    return data;
  }
}
