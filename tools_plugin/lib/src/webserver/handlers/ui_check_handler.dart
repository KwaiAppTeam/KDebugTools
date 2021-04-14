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

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http_parser/http_parser.dart';
import 'package:k_debug_tools/k_debug_tools.dart';
import 'package:k_debug_tools/src/uicheck/uicheck_models.dart';
import 'package:k_debug_tools/src/webserver/web_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart' as shelf;

import '../handler_def.dart';

///用于UI检查 提供flutter截图 widget数获取等功能
class UiCheckHandler extends AbsAppHandler {
  Uint8List? _screenshotPngBytes;
  double? _screenHeight;
  double? _screenWidth;

  @override
  shelf.Router get router {
    final router = shelf.Router();

    router.post('/capture', _capture);

    router.get('/screenshot', _getScreenshot);
    router.all('/<ignored|.*>', (Request request) => notFound());
    return router;
  }

  ///抓取flutter状态 截图 widget
  Future<Response> _capture(Request request) async {
    _screenHeight = window.physicalSize.height / window.devicePixelRatio;
    _screenWidth = window.physicalSize.width / window.devicePixelRatio;

    _screenshotPngBytes = await _captureScreen();
    if (_screenshotPngBytes == null) {
      return error('capture failed');
    }
    WidgetNode root = await _buildTree();
    return ok(FlutterCapture(
        screenWidth: _screenWidth,
        screenHeight: _screenHeight,
        paddingTop: window.padding.top / window.devicePixelRatio,
        paddingBottom: window.padding.bottom / window.devicePixelRatio,
        screenshot:
            'screenshot?t=${DateTime.now().millisecondsSinceEpoch}&Pin=${WebServer.instance.pin}',
        rootWidget: root));
  }

  ///flutter widget截屏方法
  Future<Uint8List?> _captureScreen() async {
    try {
      var boundary = await _findRenderRepaintBoundary();
      var image = await boundary!.toImage(pixelRatio: window.devicePixelRatio);
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      return pngBytes;
    } catch (e) {
      debugPrint('capture error: $e');
    }
    return null;
  }

  Future<RenderRepaintBoundary?> _findRenderRepaintBoundary() async {
    //有指定RenderRepaintBoundary
    if (Debugger.instance.rootRepaintBoundaryKey?.currentContext != null) {
      return Debugger.instance.rootRepaintBoundaryKey!.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
    }

    ///递归寻找
    RenderRepaintBoundary? find(BuildContext e) {
      RenderRepaintBoundary? boundary;
      var b = e.findRenderObject();
      if (b is RenderRepaintBoundary) {
        boundary = b;
        return boundary;
      }
      e.visitChildElements((element) {
        boundary = find(element);
        if (boundary != null) {
          return;
        }
      });
      return boundary;
    }

    //未指定,找最近一个
    RenderRepaintBoundary? boundary =
        find(await Debugger.instance.appContext.future);

    return boundary;
  }

  ///获取flutter截图
  Future<Response> _getScreenshot(Request request) async {
    //若有缓存 始终用缓存
    if (request.headers[HttpHeaders.ifNoneMatchHeader] != null) {
      return new Response.notModified();
    } else if (request.headers[HttpHeaders.ifModifiedSinceHeader] != null) {
      return new Response.notModified();
    }
    if (_screenshotPngBytes == null) {
      return notFound();
    }

    String hash = DateTime.now().millisecondsSinceEpoch.toString();
    var headers = {
      'Access-Control-Allow-Origin': '*',
      HttpHeaders.contentLengthHeader: _screenshotPngBytes!.length.toString(),
      HttpHeaders.contentTypeHeader: 'image/png',
      HttpHeaders.lastModifiedHeader: formatHttpDate(DateTime.now()),
      HttpHeaders.contentMD5Header: hash,
      HttpHeaders.etagHeader: hash,
      HttpHeaders.ageHeader: '0',
      HttpHeaders.expiresHeader:
          HttpDate.format(DateTime.now().add(Duration(minutes: 5)).toUtc())
    };
    return Response.ok(_screenshotPngBytes, headers: headers);
  }

  ///返回widget树
  FutureOr<WidgetNode> _buildTree() async {
    WidgetNode node;
    int count = 0;
    late Element rootElement;
    BuildContext ctx = await Debugger.instance.appContext.future;
    ctx.visitChildElements((element) {
      count++;
      if (count == 1) {
        rootElement = element;
      }
    });
    if (count > 1) {
      return Future.error('error: find $count root nodes');
    } else {
      node = _buildWidgetNodeTree(rootElement, 1);
    }
    return node;
  }

  List<ModalRoute> _findVisibleModalRoute(Element root) {
    Map<NavigatorState?, List<ModalRoute>> visibleRoutesMap =
        Map<NavigatorState?, List<ModalRoute>>();
    Map<NavigatorState?, List<ModalRoute>> inVisibleRoutesMap =
        Map<NavigatorState?, List<ModalRoute>>();

    void visitModalRoute(Element visitE) {
      if (visitE.widget is RenderObjectWidget) {
        ModalRoute? route = ModalRoute.of(visitE);
        if (route != null) {
          visibleRoutesMap[route.navigator] ??= <ModalRoute>[];
          inVisibleRoutesMap[route.navigator] ??= <ModalRoute>[];
          if (inVisibleRoutesMap[route.navigator]!.contains(route)) {
            return;
          }
          if (!visibleRoutesMap[route.navigator]!.contains(route)) {
            visibleRoutesMap[route.navigator]!.add(route);
          }
          //if (route.opaque) { //todo 一些透明的page上不透明的元素应该也要覆盖底下的元素 目前只显示最顶的page元素
          //set pre route inVisible
          visibleRoutesMap[route.navigator]!.removeWhere((element) {
            if (!inVisibleRoutesMap[route.navigator]!.contains(element) &&
                element != route) {
//              debugPrint('set inVisible $element, current: $route');
              inVisibleRoutesMap[route.navigator]!.add(element);
            }
            return element != route;
          });
//          }
        }
      }
      visitE.visitChildElements((child) {
        visitModalRoute(child);
      });
    }

    visitModalRoute(root);

    List<ModalRoute> all = <ModalRoute>[];
    visibleRoutesMap.forEach((key, value) {
      all.addAll(value);
    });
    return all;
  }

  ///生成可见的 WidgetNode
  WidgetNode _buildWidgetNodeTree(Element e, int dep) {
    WidgetNode node = WidgetNode(name: 'ROOT');
    //找出所有可见的ModalRoute
    List<ModalRoute> allVisibleModalRoute = _findVisibleModalRoute(e);

    ///递归查找子节点
    List<WidgetNode> buildNodes(Element e, int dep) {
      List<WidgetNode> sub = <WidgetNode>[];
      if (e.widget is RenderObjectWidget) {
        //filter by page visible
        ModalRoute? route = ModalRoute.of(e);
        if (route != null && !allVisibleModalRoute.contains(route)) {
          //not visible
//            debugPrint('not visible: ${e.toString()}');
          return sub;
        }
      }
      //filter by self opacity
      if (e.renderObject is RenderAnimatedOpacity &&
          (e.renderObject as RenderAnimatedOpacity).opacity.value == 0) {
        return sub;
      }
      if (e.renderObject is RenderOpacity &&
          (e.renderObject as RenderOpacity).opacity == 0) {
        return sub;
      }

      bool needVisitChild = true;
      //todo 其他控件需要处理
      if (e.widget is RawImage) {
        WidgetNode node = buildRawImage(e);
        _fillProperties(e, node);
        sub.add(node);
        needVisitChild = false;
      } else if (e.widget is RichText &&
          (e.widget as RichText).text is TextSpan) {
        WidgetNode node = buildTextSpanRichText(e);
        _fillProperties(e, node);
        sub.add(node);
        needVisitChild = false;
      } else if (e.widget is MaterialApp) {
        WidgetNode node = WidgetNode(name: e.widget.runtimeType.toString());
        _fillProperties(e, node);
        sub.add(node);
      } else if (e.widget is ColoredBox) {
        ColoredBox coloredBox = e.widget as ColoredBox;
        if (coloredBox.color.opacity != 0) {
          //ignore transparent
          WidgetNode node = WidgetNode(name: e.widget.runtimeType.toString());
          _fillProperties(e, node);
          node.attrs = {'color': coloredBox.color.toString()};
          sub.add(node);
        }
      } else if (e.widget is DecoratedBox) {
        WidgetNode node = WidgetNode(name: e.widget.runtimeType.toString());
        _fillProperties(e, node);
        DecoratedBox box = e.widget as DecoratedBox;
        node.attrs = {'decoration': box.decoration.toString()};
        sub.add(node);
      } else if (e.widget is Visibility && !(e.widget as Visibility).visible) {
        //child not visible
        needVisitChild = false;
      } else if (e.widget is Offstage && (e.widget as Offstage).offstage) {
        //child not visible
        needVisitChild = false;
      } else {
//        debugPrint('element ignored :${e.depth}  ${e.widget.runtimeType}');
      }
      if (needVisitChild) {
        e.visitChildElements((element) {
          var thisSubs = buildNodes(element, dep + 1);
          sub.addAll(thisSubs);
        });
      }
      // filter by position
      sub.removeWhere((element) {
        if (element.top! + element.height! < 0) {
          return true;
        }
        if (element.top! > _screenHeight!) {
          return true;
        }
        if (element.left! + element.width! < 0) {
          return true;
        }
        if (element.left! > _screenWidth!) {
          return true;
        }
        return false;
      });
      return sub;
    }

    node.children = buildNodes(e, dep);
    return node;
  }

  ///填充通用属性
  void _fillProperties(Element e, WidgetNode node) {
    node.width = e.size?.width ?? 0;
    node.height = e.size?.height ?? 0;
    RenderObject? renderObject = e.findRenderObject();
    if (renderObject is RenderBox) {
      var offset = renderObject.localToGlobal(Offset.zero);
      node.top = offset.dy;
      node.left = offset.dx;
    }
    if (node.top == null ||
        node.left == null ||
        node.top!.isNaN ||
        node.left!.isNaN) {
      node.width = node.height = node.top = node.left = 0;
    }
  }

  ///图片
  WidgetNode buildRawImage(Element e) {
    RawImage image = e.widget as RawImage;
    WidgetNode node = WidgetNode(name: 'RawImage');
    node.attrs = Map<String, dynamic>();
    node.attrs!['image'] = image.image?.toString();
    node.attrs!['alignment'] = image.alignment.toString();
    node.attrs!['invertColors'] = image.invertColors;
    node.attrs!['filterQuality'] = image.filterQuality.toString();
    node.attrs!['fit'] = image.fit?.toString();
    return node;
  }

  ///文本
  WidgetNode buildTextSpanRichText(Element e) {
    RichText richText = e.widget as RichText;
    TextSpan textSpan = richText.text as TextSpan;
    WidgetNode node =
        WidgetNode(name: 'TextSpan', data: textSpan.toPlainText());
    if (richText.text.style != null) {
      node.attrs = Map<String, dynamic>();
      node.attrs!['color'] = richText.text.style!.color?.toString();
      node.attrs!['family'] = richText.text.style!.fontFamily;
      node.attrs!['size'] = richText.text.style!.fontSize;
      node.attrs!['weight'] = richText.text.style!.fontWeight.toString();
      node.attrs!['baseline'] = richText.text.style!.textBaseline?.toString();
    }
    return node;
  }
}
