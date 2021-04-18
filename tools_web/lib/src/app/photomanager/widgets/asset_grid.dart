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

import 'package:flutter/material.dart';
import 'package:k_debug_tools_web/src/widgets/item_picker.dart';
import '../../../bloc_provider.dart';
import '../photo_manager_bloc.dart';
import '../photo_models.dart';
import 'asset_item_thumb.dart';

///格子
class AssetGirdWidget extends StatefulWidget {
  AssetGirdWidget();

  @override
  _AssetGirdWidgetState createState() => _AssetGirdWidgetState();
}

class _AssetGirdWidgetState extends State<AssetGirdWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  PhotoManagerBloc _photoBloc;
  ItemPicker _itemPicker;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    _photoBloc = BlocProvider.of<PhotoManagerBloc>(context).first;
    _itemPicker = _photoBloc.itemPicker;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(
      builder: (_, constraints) {
        return Scrollbar(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Wrap(
                direction: Axis.horizontal,
                alignment: WrapAlignment.start,
                spacing: 8,
                runSpacing: 8,
                children: _buildItemWidgets()),
          ),
        );
      },
    );
  }

  List<Widget> _buildItemWidgets() {
    List<Widget> widgets = <Widget>[];
    Iterable<Asset> assets = _photoBloc.getShowingAssets();
    assets?.forEach((element) {
      Widget w = SizedBox(
        width: 128,
        height: 128,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).focusColor),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                  child: GestureDetector(
                onDoubleTap: () {
                  _photoBloc.openFile(assets.toList(), element);
                },
                child: AssetItemThumbWidget(
                  asset: element,
                  thumbUrl: _photoBloc.getThumbUrl(element),
                ),
              )),
              Positioned(
                top: 2,
                right: 2,
                child: Checkbox(
                  value: _itemPicker.isSelected(element),
                  onChanged: (v) {
                    if (v) {
                      _itemPicker.select(element);
                    } else {
                      _itemPicker.deselect(element);
                    }
                  },
                ),
              )
            ],
          ),
        ),
      );
      widgets.add(w);
    });
    return widgets;
  }
}
