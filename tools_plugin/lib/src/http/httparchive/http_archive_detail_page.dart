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
import 'package:k_debug_tools/src/http/http_models.dart';

import '../../../k_debug_tools.dart';
import 'http_request_widget.dart';
import 'http_response_widget.dart';

///网络请求详情
class HttpArchiveDetailPage extends StatefulWidget {
  final HttpArchive httpArchive;

  HttpArchiveDetailPage(this.httpArchive);

  @override
  _HttpArchiveDetailPageState createState() => _HttpArchiveDetailPageState();
}

class _HttpArchiveDetailPageState extends State<HttpArchiveDetailPage>
    with SingleTickerProviderStateMixin {
  final List<Tab> tabs = <Tab>[
    new Tab(text: "request"),
    new Tab(text: "response"),
  ];

  PageController _pageController;

  int currentIndex = 0;

  @override
  void initState() {
    _pageController = PageController(initialPage: 0);
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          child: Column(
            children: <Widget>[
              NavBar(
                title: localizationOptions.requestDetail,
                onBack: () {
                  Navigator.pop(context);
                },
              ),
              Expanded(
                  child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: 2,
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0) {
                    return RequestWidget(widget.httpArchive);
                  } else {
                    return ResponseWidget(widget.httpArchive);
                  }
                },
              )),
              BottomNavigationBar(
                currentIndex: currentIndex,
                onTap: _bottomTap,
                items: [
                  BottomNavigationBarItem(
                      icon: Icon(Icons.network_wifi), title: Text('request')),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.network_wifi), title: Text('response')),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _onPageChanged(int value) {
    if (mounted) {
      setState(() {
        currentIndex = value;
      });
    }
  }

  void _bottomTap(int value) {
    _pageController.animateToPage(value,
        duration: Duration(milliseconds: 300), curve: Curves.ease);
  }
}
