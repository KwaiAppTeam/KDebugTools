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

import 'package:flutter/widgets.dart';
import 'package:k_debug_tools_web/src/web_bloc.dart';

abstract class BlocBase {
  @protected
  void dispose();
}

abstract class AppBlocBase extends BlocBase {
  BuildContext context;

  AppBlocBase(this.context);

  String getHost() {
    return WebBloc.getHost();
  }

  String getHostWithSchema() {
    return WebBloc.getHostWithSchema();
  }
}

class BlocProvider<T extends BlocBase> extends StatefulWidget {
  BlocProvider({
    Key key,
    @required this.child,
    @required this.blocs,
  }) : super(key: key);

  final Widget child;
  final List<T> blocs;

  @override
  _BlocProviderState<T> createState() => _BlocProviderState<T>();

  static List<T> of<T extends BlocBase>(BuildContext context) {
    _BlocProviderInherited<T> _provider =
        context.getElementForInheritedWidgetOfExactType<_BlocProviderInherited<T>>()?.widget;
    return _provider?.blocs;
  }
}

class _BlocProviderState<T extends BlocBase> extends State<BlocProvider<T>> {
  @override
  Widget build(BuildContext context) {
    return _BlocProviderInherited<T>(
      blocs: widget.blocs,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    widget.blocs.map((bloc) {
      bloc.dispose();
    });
    super.dispose();
  }
}

class _BlocProviderInherited<T> extends InheritedWidget {
  _BlocProviderInherited({
    Key key,
    @required Widget child,
    @required this.blocs,
  }) : super(key: key, child: child);

  final List<T> blocs;

  @override
  bool updateShouldNotify(_BlocProviderInherited oldWidget) => false;
}
