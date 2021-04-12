# KDebugTools接入手册


## 添加依赖与初始化

### 在pubspec.yaml中加入依赖

```yaml
...
dependencies:
  ...
  k_debug_tools: ^1.0.0
  ...
...
```

### 初始化

参考 [example](../tools_plugin/example/lib/main.dart)

导入 `package:k_debug_tools/k_debug_tools.dart`.

```dart
...
  Debugger.instance.init(
      autoStartWebServer: true,
      autoStartHttpHook: true);
...
```


### 在合适的地方加入唤起入口浮窗代码

```dart
Debugger.instance.showDebugger(context)
```

## 本地化配置

```dart
setLocalizationOptions(LocalizationOptions.buildEnOptions())
```
or
```dart
setLocalizationOptions(LocalizationOptions.buildZhOptions())
```

## App构建信息

工具默认会读取变量变量*BUILD_TIME*、*GIT_BRANCH*、*GIT_COMMIT*、*JENKINS_BUILD_ID*

在构建时可通过以下两种方式写入参数(需要flutter版本在1.17.4以上):

### 使用flutter命令构建时可使用\--dart-define=KEY=VALUE添加

```
flutter run --dart-define=GIT_BRANCH="$(git rev-parse --abbrev-ref HEAD)" --dart-define=GIT_COMMIT=$(git rev-parse --short HEAD) --dart-define=BUILD_TIME="$(date "+%Y-%m-%d %H:%M:%S")"
```
### 使用gradle构建时使用-Pdart-defines进行添加

```
gradle -Pdart-defines=GIT_BRANCH="$(git rev-parse  \--abbrev-ref HEAD)",GIT_COMMIT="$(git rev-parse  \--short HEAD)",BUILD_TIME="$(date "+%Y-%m-%d %H:%M:%S")",JENKINS_BUILD_ID=$BUILD_ID clean assembleDebug
```

## 支持服务器配置

在Debugger.instance.init时传入  
* allServEnvKeys 可配置key
* allServConfigs 默认服务器配置

参考[example的配置](../tools_plugin/example/lib/demo_serv_config.dart)

在创建请求时使用以下方法对域名进行映射

```
ServerEnv.instance.mapHost(onlineHost)
```

使用以下方法获取当前配置的值

```
ServerEnv.instance.getEnvValue(key)
```

## 添加自定义组件到面板

### 添加普通Item

调用以下方法添加到某一类目中

```
Debugger.instance.registerItemToXXX(SimpleToolItemWidget item);
```

### 添加带开关Item

```
Debugger.instance.registerItemToXXX(ToggleToolItemWidget item);
```

## Web端文件管理 添加自定义路径, 如下载目录、缓存目录等

```
Debugger.instance.addCustomDirToRoot(String name, String absolute);
```

## Web端DbView 添加自定义文件

```
Debugger.instance.registerDbFile(String filePath);
```

## 支持Web端FlutterUI功能

在根节点widget上包裹RepaintBoundary

参考[example代码](../tools_plugin/example/lib/main.dart)


