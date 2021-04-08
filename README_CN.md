# KDebugTools

KDebugTools是一套适用于Flutter平台的移动端应用研发辅助工具

![Overview](https://static.yximgs.com/udata/pkg/KS-IDEA/k_debug_tools/readme/web2.jpg)

![Overview](https://static.yximgs.com/udata/pkg/KS-IDEA/k_debug_tools/readme/sdk2.jpg)

### 通过内置的Web服务,可在电脑浏览器实现以下功能

* App和设备信息查询
* 设备文件管理、传输和预览
* SharedPreference、SQLite直接查询和修改
* Flutter网络抓包拦截及限流配置
* Flutter日志查看
* Flutter Widget属性检查
* Flutter路由跳转
* 设备剪切板同步
* 设备投屏及录制(Android)

### 所有功能无需ROOT,无需USB连接

## 接入方法

### 添加依赖

```yaml
...
dependencies:
  ...
  k_debug_tools: ^1.0.0
  ...
...
```

### 初始化

参考 [example](tools_plugin/example/lib/main.dart)

导入 `package:k_debug_tools/k_debug_tools.dart`.

```dart
...
  Debugger.instance.init(
      autoStartWebServer: true,
      autoStartHttpHook: true);
...
```

### 显示浮动按钮

```dart
...
  Debugger.instance.showDebugger(context);
...
```

### 显示面板

```dart
...
  Debugger.instance.showDebuggerDialog(context);
...
```

## 隐私说明

本项目在Web工具中会使用Google
Analytics进行匿名数据收集,用于数据分析,旨在改善并促进项目发展
