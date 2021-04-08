# KDebugTools

KDebugTools is a powerful library for debugging Flutter applications

[Chinese](./README_CN.md)

![Overview](https://static.yximgs.com/udata/pkg/KS-IDEA/k_debug_tools/readme/web2.jpg)

![Overview](https://static.yximgs.com/udata/pkg/KS-IDEA/k_debug_tools/readme/sdk2.jpg)

### You can access these features via WebBrowser

* Check App and device information
* File management, transfer and preview
* Directly edit the shared preferences or database values
* Recording or throttling network with Flutter HttpClient
* Fetch logs of application
* View attributes of Flutter Widget
* Controlling the Flutter navigator
* Directly edit the device clipboard
* Cast and record device screen (Android only)

### All these features work without rooting your device or USB connection

## Usage

### Import the package

```yaml
...
dependencies:
  ...
  k_debug_tools: ^1.0.0
  ...
...
```

### Use the plugin

See the [`example`](tools_plugin/example) directory for a complete
sample app using KDebugTools.

You should be able to use `package:k_debug_tools` _almost_ as normal.

First of all, you must init the plugin with code like this:

```dart
...
  Debugger.instance.init(
      autoStartWebServer: true,
      autoStartHttpHook: true);
...
```

### Show floating button

```dart
...
  Debugger.instance.showDebugger(context);
...
```

### Show debugger panel

```dart
...
  Debugger.instance.showDebuggerDialog(context);
...
```

## Warning

Web tools of this project uses Google Analytics to anonymously report
feature usage statistics. This data is used to help improve this project
over time.
