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
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:k_debug_tools/k_debug_tools.dart';
import 'package:k_debug_tools/src/navigator/navigator_models.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart' as shelf;

import '../handler_def.dart';

///用于获取navigator信息 跳转等功能
class NavigatorHandler extends AbsAppHandler {
  @override
  shelf.Router get router {
    final router = shelf.Router();

    router.get('/state', _state);

    router.post('/push', _push);
    router.post('/pop', _pop);

    router.all('/<ignored|.*>', (Request request) => notFound());
    return router;
  }

  ///抓取页面路由状态
  Future<Response> _state(Request request) async {
    NavigatorInfo? info = await _fetchRootNavigatorInfo();
    return ok(info);
  }

  ///弹出页面
  Future<Response> _pop(Request request) async {
    Map body = jsonDecode(await request.readAsString());
    String? name = body['name'];
    debugPrint('pop route $name ...');
    ModalRoute? route = await _findRoute(name);
    if (route != null) {
      bool popped = false;
      route.navigator!.popUntil((r) {
        String n = getRouteName(r as ModalRoute<dynamic>);
        popped |= (n == name);
        bool canPop = popped && n != name;
        if (canPop) {
          debugPrint('pop route $n');
        }
        return canPop;
      });
      return ok(null);
    } else {
      return notFound(msg: 'route not found');
    }
  }

  String getRouteName(ModalRoute route) {
    return '${objectRuntimeType(route, 'ModalRoute')}#${shortHash(route)}';
  }

  String getNavigatorName(Navigator navigator) {
    return '${objectRuntimeType(navigator, 'Navigator')}#${shortHash(navigator)}';
  }

  ///push页面
  Future<Response> _push(Request request) async {
    Map body = jsonDecode(await request.readAsString());
    String? url = body['url'];
    String? navigator = body['navigator'];
    debugPrint('push $navigator $url');

    NavigatorState? navigatorState = await _findNavigator(navigator);
    if (navigatorState == null) {
      debugPrint('navigator not found, use root navigator instead');
      BuildContext ctx = await Debugger.instance.appContext.future;
      navigatorState =
          Navigator.of(ctx, rootNavigator: true);
    }

    Completer<Response> completer = Completer();
    if (navigatorState != null) {
      try {
        Debugger.instance.pushNamed(navigatorState, url);
        completer.complete(ok(null));
      } catch (e) {
        completer.complete(error('$e'));
      }
    } else {
      completer.complete(notFound(msg: 'navigator not found'));
    }
    return completer.future;
  }

  ///返回rootElement
  FutureOr<Element> _rootElement() async {
    int count = 0;
    Element? rootElement;
    BuildContext ctx = await Debugger.instance.appContext.future;
    ctx.visitChildElements((element) {
      count++;
      if (count == 1) {
        rootElement = element;
      }
    });
    if (count > 1) {
      return Future.error('error: find $count root nodes');
    }
    return rootElement!;
  }

  Future<NavigatorState?> _findNavigator(String? name) async {
    Element rootElement = await (_rootElement());
    NavigatorState? target;

    void visitModalRoute(Element visitE) {
      if (visitE.widget is RenderObjectWidget) {
        ModalRoute? route = ModalRoute.of(visitE);
        if (route != null) {
          String navigatorName = getNavigatorName(route.navigator!.widget);
          if (navigatorName == name) {
            target = route.navigator;
          }
        }
      }
      if (target == null) {
        visitE.visitChildElements((childElement) {
          if (target == null) {
            visitModalRoute(childElement);
          }
        });
      }
    }

    visitModalRoute(rootElement);
    return target;
  }

  Future<ModalRoute?> _findRoute(String? name) async {
    Element rootElement = await (_rootElement());
    ModalRoute? target;

    void visitModalRoute(Element visitE) {
      if (visitE.widget is RenderObjectWidget) {
        ModalRoute? route = ModalRoute.of(visitE);
        if (route != null) {
          String routeName = getRouteName(route);
          if (routeName == name) {
            target = route;
          }
        }
      }
      if (target == null) {
        visitE.visitChildElements((childElement) {
          if (target == null) {
            visitModalRoute(childElement);
          }
        });
      }
    }

    visitModalRoute(rootElement);
    return target;
  }

  Future<NavigatorInfo?> _fetchRootNavigatorInfo() async {
    Element rootElement = await _rootElement();
    Map<NavigatorState?, List<ModalRoute>> addedRoutesMap =
        Map<NavigatorState?, List<ModalRoute>>();
    NavigatorInfo? _rootNavigator;
    int _dep = 0;
    void visitModalRoute(int dep, NavigatorInfo? parentNavigator,
        RouteInfo? routeInfo, Element visitE) {
      if (visitE.widget is Navigator) {
        parentNavigator = NavigatorInfo()
          ..name = getNavigatorName(visitE.widget as Navigator)
          ..routes = <RouteInfo?>[];
        //Navigator作为之前的routeInfo的子节点
        if (routeInfo != null) {
          routeInfo.childNavigators!.add(parentNavigator);
        }
        dep++;
      }
      //第一个找到的作为root navigator
      if (_rootNavigator == null) {
        _rootNavigator = parentNavigator;
      }
      if (visitE.widget is RenderObjectWidget) {
        ModalRoute? route = ModalRoute.of(visitE);
        if (route != null) {
          if (addedRoutesMap[route.navigator] == null) {
            addedRoutesMap[route.navigator] = <ModalRoute>[];
          }
          if (!addedRoutesMap[route.navigator]!.contains(route)) {
            addedRoutesMap[route.navigator]!.add(route);
            //新的routeInfo
            routeInfo = RouteInfo()
              ..name = getRouteName(route)
              ..settings = route.settings.toString()
              ..childNavigators = <NavigatorInfo?>[]
              ..isCurrent = route.isCurrent
              ..width = visitE.size?.width ?? 0
              ..height = visitE.size?.height ?? 0
              ..top = 0.0
              ..left = 0.0;
            RenderObject? renderObject = visitE.findRenderObject();
            if (renderObject is RenderBox) {
              var offset = renderObject.localToGlobal(Offset.zero);
              routeInfo.top = offset.dy;
              routeInfo.left = offset.dx;
            }
            parentNavigator!.routes!.add(routeInfo);
          }
        }
      }
      visitE.visitChildElements((childElement) {
        visitModalRoute(dep, parentNavigator, routeInfo, childElement);
      });
    }

    visitModalRoute(_dep, null, null, rootElement);

    return _rootNavigator;
  }

  String shortHash(Object object) {
    return object.hashCode.toUnsigned(20).toRadixString(16).padLeft(5, '0');
  }
}
