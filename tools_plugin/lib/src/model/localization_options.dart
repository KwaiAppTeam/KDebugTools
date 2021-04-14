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

LocalizationOptions? _localizationOptions;

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
      basicInfo: "基本信息",
      commonTools: "常用工具",
      debugTools: "联调调试",
      otherTools: "其他工具",
      dialogConfirm: "确定",
      dialogCancel: "取消",
      unconfigured: "未设置",
      config: "配置",
      parentDir: "上级目录",
      refresh: "刷新",
      fileOpen: "打开",
      fileRename: "重命名",
      fileDelete: "删除",
      fileDeleteSuccess: "删除成功",
      httpProxy: "Http代理",
      httpRequest: "Http抓包",
      requestDetail: "请求详情",
      appInfo: "应用信息",
      deviceInfo: "设备信息",
      floatButton: "悬浮按钮",
      fileExplorer: "文件浏览",
      performanceToggle: "性能监控",
      serverConfig: "服务器配置",
      copied: "已复制到剪切板",
      webServer: "Web服务",
      rules: "配置",
      records: "请求记录",
    );
  }
}
