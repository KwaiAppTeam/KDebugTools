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

LocalizationOptions _localizationOptions;

LocalizationOptions get localizationOptions =>
    _localizationOptions ?? LocalizationOptions.buildEnOptions();

void setLocalizationOptions(LocalizationOptions localizationOptions) {
  _localizationOptions = localizationOptions;
}

class LocalizationOptions {
  final String languageCode;

  final String basicInfo;
  final String commonTools;
  final String debugTools;
  final String otherTools;

  final String dialogConfirm;
  final String dialogCancel;

  final String unconfigured;
  final String config;
  final String parentDir;
  final String refresh;

  final String fileOpen;
  final String fileRename;
  final String fileDelete;
  final String fileDeleteSuccess;

  final String httpProxy;
  final String httpRequest;
  final String requestDetail;
  final String appInfo;
  final String deviceInfo;
  final String floatButton;
  final String fileExplorer;
  final String performanceToggle;
  final String serverConfig;
  final String copied;

  final String webServer;
  final String rules;
  final String records;

  LocalizationOptions(
    this.languageCode, {
    this.basicInfo = "BasicInfo",
    this.commonTools = "CommonTools",
    this.debugTools = "DebugTools",
    this.otherTools = "OtherTools",
    this.dialogConfirm = "Confirm",
    this.dialogCancel = "Cancel",
    this.unconfigured = "Unconfigured",
    this.config = "config",
    this.parentDir = "Parent",
    this.refresh = "refresh",
    this.fileOpen = "Open",
    this.fileRename = "Rename",
    this.fileDelete = "Delete",
    this.fileDeleteSuccess = "delete success",
    this.httpProxy = "HttpProxy",
    this.httpRequest = "HttpRequest",
    this.requestDetail = "Detail",
    this.appInfo = "AppInfo",
    this.deviceInfo = "DeviceInfo",
    this.floatButton = "FloatButton",
    this.fileExplorer = "FileExplorer",
    this.performanceToggle = "Performance",
    this.serverConfig = "Server",
    this.copied = "copied",
    this.webServer = "WebServer",
    this.rules = "rules",
    this.records = "records",
  });

  static LocalizationOptions buildEnOptions() {
    return LocalizationOptions("en");
  }

  static LocalizationOptions buildZhOptions() {
    return LocalizationOptions(
      "zh",
      basicInfo: "????????????",
      commonTools: "????????????",
      debugTools: "????????????",
      otherTools: "????????????",
      dialogConfirm: "??????",
      dialogCancel: "??????",
      unconfigured: "?????????",
      config: "??????",
      parentDir: "????????????",
      refresh: "??????",
      fileOpen: "??????",
      fileRename: "?????????",
      fileDelete: "??????",
      fileDeleteSuccess: "????????????",
      httpProxy: "Http??????",
      httpRequest: "Http??????",
      requestDetail: "????????????",
      appInfo: "????????????",
      deviceInfo: "????????????",
      floatButton: "????????????",
      fileExplorer: "????????????",
      performanceToggle: "????????????",
      serverConfig: "???????????????",
      copied: "?????????????????????",
      webServer: "Web??????",
      rules: "??????",
      records: "????????????",
    );
  }
}
