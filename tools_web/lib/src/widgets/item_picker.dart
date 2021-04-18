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

import 'dart:math';

import 'package:flutter/widgets.dart';

import '../bloc_provider.dart';
import '../web_bloc.dart';

///数据选择器 实现按住command shift 多选功能
class ItemPicker<T> extends ChangeNotifier {
  final BuildContext context;
  bool _tapToDeselect;
  WebBloc _webBloc;

  List<T> get selectedItem => _selectedItem.toList(growable: false);

  List<T> _selectedItem = List<T>();

  ///[tapToDeselect] 只有一个时点击也可以反选
  ItemPicker(this.context, {bool tapToDeselect = false}) {
    if (context != null && BlocProvider.of<WebBloc>(context).isNotEmpty) {
      _webBloc = BlocProvider.of<WebBloc>(context).first;
    }
    _tapToDeselect = tapToDeselect;
  }

  void _rangeSelect(T item) {
    //range select not support by default, use _multiSelect
    _multiSelect(item);
  }

  void _multiSelect(T item) {
    //change this select state only
    if (_selectedItem.contains(item)) {
      _selectedItem.remove(item);
    } else {
      _selectedItem.add(item);
    }
    notifyListeners();
  }

  void select(T item) {
    if (!_selectedItem.contains(item)) {
      _selectedItem.add(item);
      notifyListeners();
    }
  }

  void deselect(T item) {
    if (_selectedItem.contains(item)) {
      _selectedItem.remove(item);
      notifyListeners();
    }
  }

  //select/deselect
  void onItemTap(T item, {bool forceSelect = false}) {
    bool multiSelect = _webBloc?.isMetaPressed ?? false;
    bool rangeSelect = _webBloc?.isShiftPressed ?? false;
    if (rangeSelect) {
      _rangeSelect(item);
    } else if (multiSelect) {
      _multiSelect(item);
    } else {
      if (_selectedItem.length > 1 ||
          !_selectedItem.contains(item) ||
          forceSelect ||
          !_tapToDeselect) {
        if (_selectedItem.length == 1 && _selectedItem.contains(item)) {
          //already selected, do nothing
        } else {
          //only this will selected
          _selectedItem.clear();
          _selectedItem.add(item);
          notifyListeners();
        }
      } else {
        //deselect all
        _selectedItem.clear();
        notifyListeners();
      }
    }
  }

  void clear() {
    _selectedItem.clear();
    notifyListeners();
  }

  bool isSelected(T item) {
    return _selectedItem.contains(item);
  }

  int get selectedCount => _selectedItem.length;

  T get lastSelectItem => selectedCount > 0 ? _selectedItem.last : null;
}

///只能选中一个
class SingleItemPicker<T> extends ItemPicker<T> {
  SingleItemPicker(context, {bool tapToDeselect = false})
      : super(context, tapToDeselect: tapToDeselect);

  //select/deselect
  void onItemTap(T item, {bool forceSelect = false}) {
    if (_selectedItem.contains(item) && !forceSelect && _tapToDeselect) {
      _selectedItem.clear();
      notifyListeners();
    } else {
      _selectedItem.clear();
      _selectedItem.add(item);
      notifyListeners();
    }
  }
}

///有序数据选择器 实现按住shift进行范围选中
class IndexedItemPicker extends ItemPicker<int> {
  ///[tapToDeselect] 只有一个时点击也可以反选
  IndexedItemPicker(context, {bool tapToDeselect = false})
      : super(context, tapToDeselect: tapToDeselect);

  @override
  void _rangeSelect(int item) {
    if (_selectedItem.isEmpty) {
      _selectedItem.add(item);
      notifyListeners();
    } else {
      //select from min to max
      int minIndex = min(_selectedItem.reduce(min), item);
      int maxIndex = max(_selectedItem.reduce(max), item);
      if (minIndex != maxIndex) {
        _selectedItem.clear();
        for (int i = minIndex; i <= maxIndex; i++) {
          _selectedItem.add(i);
        }
        notifyListeners();
      }
    }
  }
}
