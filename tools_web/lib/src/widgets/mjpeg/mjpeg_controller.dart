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
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:flutter/services.dart' show rootBundle;

const _trigger = 0xFF;
const _soi = 0xD8;
const _eoi = 0xD9;

enum MjpegControllerStatusValue {
  unknow,
  loading,
  ready,
  playing,
  paused,
  stopped,
  timeouted
}

class MjpegControllerStatus extends ChangeNotifier {
  MjpegControllerStatus(this._value);

  MjpegControllerStatusValue _value;

  MjpegControllerStatusValue get value => this._value;

  set value(MjpegControllerStatusValue newValue) {
    if (newValue == this._value) return;
    this._value = newValue;
    this.notifyListeners();
  }
}

class MjpegErrorMessage extends ChangeNotifier {
  MjpegErrorMessage(this._value, [this._onError]);

  void Function(Object error) _onError;
  String _value;

  String get value => this._value;

  set value(String newValue) {
    if (newValue == this._value) return;
    this._value = newValue;
    this.notifyListeners();
    if (this._onError != null) this._onError(newValue);
  }
}

class MjpegFrameImage extends ChangeNotifier {
  MjpegFrameImage(this._value);

  MemoryImage _value;

  MemoryImage get value => this._value;

  set value(MemoryImage newValue) {
    if (newValue == this._value) return;
    this._value = newValue;
    this.notifyListeners();
  }
}

abstract class MjpegController {
  MjpegController({
    bool autoControl,
    Function(Object error) onError, // 出现错误时回调
    Function() onNoResponse, // 播放过程中数据流无响应时回调
  })  : this._autoControl = autoControl ?? false,
        this._onNoResponse = onNoResponse {
    this._status = MjpegControllerStatus(MjpegControllerStatusValue.unknow);
    this._errMsg = MjpegErrorMessage(null, onError);
    this._frame = MjpegFrameImage(null);
  }

  final Function() _onNoResponse;
  final bool _autoControl; // 是否自动控制，当开启自动控制时且流已经打开时，只要有订阅者就会自动播放，订阅者为空就会自动暂停
  List<Object> _subscribers = []; // 订阅者名单
  String _url = "";

  MjpegControllerStatus _status;
  MjpegErrorMessage _errMsg;
  MjpegFrameImage _frame;

  MjpegControllerStatus get status => this._status;

  MjpegErrorMessage get errMsg => this._errMsg;

  MjpegFrameImage get frame => this._frame;

  String get url => this._url;

  factory MjpegController.fromHttp(
      {Map<String, String> headers,
      String method,
      Duration timeout,
      bool autoControl,
      Function(Object error) onError,
      Function() onNoResponse}) {
    return _MjpegControllerFromHttp(
        headers: headers,
        method: method,
        timeout: timeout,
        autoControl: autoControl,
        onError: onError,
        onNoResponse: onNoResponse);
  }

  factory MjpegController.fromAsset(
      {int fps = 15,
      bool isLoop = true,
      bool autoControl,
      Function(Object error) onError,
      Function() onNoResponse}) {
    return _MjpegControllerFromAsset(
        fps: fps,
        isLoop: isLoop,
        autoControl: autoControl,
        onError: onError,
        onNoResponse: onNoResponse);
  }

  void _waiting() async {
    while (this._status.value == MjpegControllerStatusValue.loading)
      await Future.delayed(Duration(microseconds: 10));
  }

  void addSubscriber(Object subscriber) {
    if (!this._subscribers.contains(subscriber)) {
      this._subscribers.add(subscriber);
      if (this._autoControl &&
          [MjpegControllerStatusValue.ready, MjpegControllerStatusValue.paused]
              .contains(this._status.value)) this.play();
    }
  }

  void removeSubscriber(Object subscriber) {
    if (this._subscribers.contains(subscriber)) {
      this._subscribers.remove(subscriber);
      if (this._autoControl &&
          this._subscribers.isEmpty &&
          MjpegControllerStatusValue.playing == this._status.value)
        this.pause();
    }
  }

  Future<bool> open(String url) async {
    this._url = url;
    this._status.value = MjpegControllerStatusValue.ready;
    this._frame.value = null;
    this._errMsg.value = null;
    if (this._autoControl && this._subscribers.isNotEmpty) this.play();
    return true;
  }

  Future<void> close() async {
    this._waiting();
    this._status.value = MjpegControllerStatusValue.unknow;
    this._frame.value = null;
    this._errMsg.value = null;
  }

  Future<void> play() async {
    if ([
      MjpegControllerStatusValue.unknow,
      MjpegControllerStatusValue.timeouted
    ].contains(this._status.value))
      throw "Cannot play a stream that is not open.";
    this._status.value = MjpegControllerStatusValue.playing;
  }

  Future<void> pause() async {
    if (this._status.value != MjpegControllerStatusValue.playing)
      throw "There is no stream playing.";
    this._status.value = MjpegControllerStatusValue.paused;
  }

  Future<void> stop() async {
    this._waiting();
    if (![
      MjpegControllerStatusValue.playing,
      MjpegControllerStatusValue.paused,
      MjpegControllerStatusValue.ready
    ].contains(this._status.value)) throw "There is no open stream.";

    this._status.value = MjpegControllerStatusValue.stopped;
  }
}

class _MjpegControllerFromHttp extends MjpegController {
  _MjpegControllerFromHttp(
      {this.headers,
      String method,
      Duration timeout,
      bool autoControl,
      Function(Object error) onError,
      Function() onNoResponse})
      : this.method = method ?? "GET",
        this.timeout = timeout ?? const Duration(seconds: 5),
        super(
            autoControl: autoControl,
            onError: onError,
            onNoResponse: onNoResponse);

  final String method;
  final Map<String, String> headers;
  final Duration timeout;

  StreamSubscription _subscription;
  StreamedResponse _response;
  Client _httpClient;
  Timer _noSourceCheckTimer;
  int _lastCounter = 0;
  int _counter = 0;

  Future<void> _removeListen() async {
    await this._subscription?.cancel();
    this._subscription = null;
  }

  void _cleanTimer() {
    this._noSourceCheckTimer?.cancel();
    this._noSourceCheckTimer = null;
    this._counter = 0;
    this._lastCounter = 0;
  }

  void _closeClient() {
    this._httpClient?.close();
    this._httpClient = null;
  }

  void _listen() {
    int startIndex = -1;
    List<int> buffer = [];
    this._subscription = this._response.stream.listen((data) async {
      if (this._status.value != MjpegControllerStatusValue.playing) return;

      if (buffer.isEmpty) {
        for (var i = 0; i < data.length - 1; i++) {
          if (data[i] == _trigger) {
            if (data[i + 1] == _soi)
              startIndex = i;
            else if (data[i + 1] == _eoi && startIndex != -1) {
              // 找到一帧数据
              if (this._status.value == MjpegControllerStatusValue.playing) {
                this._frame.value = MemoryImage(
                    Uint8List.fromList(data.sublist(startIndex, i + 2)));
                this._counter++;
              }
              startIndex = -1;
            }
          }
        }

        if (startIndex != -1) {
          buffer.addAll(data.sublist(startIndex));
          startIndex = 0;
        }
      } else {
        buffer.addAll(data);
        for (var i = 0; i < buffer.length - 1; i++) {
          if (buffer[i] == _trigger) {
            if (buffer[i + 1] == _soi)
              startIndex = i;
            else if (buffer[i + 1] == _eoi && startIndex != -1) {
              // 找到一帧数据
              if (this._status.value == MjpegControllerStatusValue.playing) {
                this._frame.value = MemoryImage(
                    Uint8List.fromList(buffer.sublist(startIndex, i + 2)));
                this._counter++;
              }
              startIndex = -1;
            }
          }
        }

        if (startIndex == -1)
          buffer.clear();
        else
          buffer.removeRange(0, startIndex);
      }
    }, onError: (err) async {
      this._errMsg.value = "Mjpeg stream has a error: $err";
      await this.stop();
    }, cancelOnError: true);
  }

  @override
  Future<bool> open(String url) async {
    assert(url != null);
    if (MjpegControllerStatusValue.ready == this._status.value &&
        this._url == url) return true;

    this._waiting();
    this._url = url;
    this._cleanTimer();
    await this._removeListen();

    if ([MjpegControllerStatusValue.playing, MjpegControllerStatusValue.paused]
        .contains(this._status.value)) return await super.open(url);

    this._status.value = MjpegControllerStatusValue.loading;
    this._closeClient();
    final request = Request(this.method, Uri.parse(this.url));
    if (this.headers != null) request.headers.addAll(this.headers);
    this._httpClient = new Client();
    //todo send hangs
    this._response = await this._httpClient.send(request).catchError((e) {
      debugPrint('open http connection error: $e');
      return null;
    });

    if (this._response == null ||
        this._response.statusCode < 200 ||
        this._response.statusCode >= 300) {
      this._errMsg.value = "Cannot open http connection. code: ${this._response?.statusCode}";
      this._status.value = MjpegControllerStatusValue.unknow;
      return false;
    }

    this._listen();
    this._subscription?.pause();
    return await super.open(url);
  }


  @override
  Future<void> close() async {
    if (this._status.value == MjpegControllerStatusValue.unknow) return;

    this._waiting();
    this._cleanTimer();
    await this._removeListen();
    this._closeClient();
    this._response = null;
    super.close();
  }

  @override
  Future<void> play() async {
    if (this._status.value == MjpegControllerStatusValue.playing) return;

    await super.play();
    this._subscription?.resume();
    this._cleanTimer();
    this._noSourceCheckTimer = Timer.periodic(this.timeout, (_) {
      if (this._counter > this._lastCounter)
        this._lastCounter = this._counter;
      else {
        this._frame.value = null;
        if (this._onNoResponse != null) this._onNoResponse();
      }
    });
  }

  @override
  Future<void> pause() async {
    await super.pause();
    this._subscription?.pause();
    this._cleanTimer();
  }

  @override
  Future<void> stop() async {
    await super.stop();
    this._subscription?.pause();
    this._cleanTimer();
  }
}

class _MjpegControllerFromAsset extends MjpegController {
  _MjpegControllerFromAsset(
      {@required this.sourceName,
      int fps,
      bool isLoop,
      bool autoControl,
      Function(Object error) onError,
      Function() onNoResponse})
      : assert(sourceName != null &&
            sourceName.isNotEmpty &&
            fps > 0 &&
            fps <= 50),
        this.fps = fps ?? 15,
        this.isLoop = isLoop ?? true,
        super(
            autoControl: autoControl,
            onError: onError,
            onNoResponse: onNoResponse);

  final String sourceName;
  final int fps;
  bool isLoop;
  int _position = 0;
  List<Uint8List> _buffer = [];
  Timer _timer;

  int get position => this._position;

  Future<bool> open(String url) async {
    assert(url != null);
    if (MjpegControllerStatusValue.ready == this._status.value &&
        this._url == url) return true;

    this._waiting();
    this._url = url;
    if (this._errMsg.value != null) return false;

    this._status.value = MjpegControllerStatusValue.loading;
    this._timer?.cancel();
    this._position = 0;

    if (this._buffer.isEmpty) {
      var source =
          (await rootBundle.load(this.sourceName)).buffer.asUint8List();
      if (source == null || source.isEmpty) {
        this._errMsg.value = "Unable to load MJPEG source.";
        this._status.value = MjpegControllerStatusValue.unknow;
        return false;
      }

      var startAt = -1;
      for (var i = 0; i < source.length - 1; i++) {
        if (startAt == -1 && source[i] == _trigger && source[i + 1] == _soi)
          startAt = i;
        else if (startAt != -1 &&
            source[i] == _trigger &&
            source[i + 1] == _eoi) {
          this._buffer.add(source.sublist(startAt, i + 2));
          startAt = -1;
        }
      }

      if (this._buffer.isEmpty) {
        this._errMsg.value = "Invalid MJPEG source.";
        this._status.value = MjpegControllerStatusValue.unknow;
        return false;
      }
    }

    return await super.open(url);
  }

  Future<void> close() async {
    await super.close();
    this._timer?.cancel();
    this._position = 0;
    this._buffer.clear();
  }

  Future<void> play([int position = -1]) async {
    assert(position >= -1);
    await super.play();
    if (this._status.value == MjpegControllerStatusValue.playing &&
        position == -1) return;

    this._timer?.cancel();
    if (position != -1) {
      if (position >= this._buffer.length) {
        if (this.isLoop)
          this._position = 0;
        else
          return await this.stop();
      } else
        this._position = position;
    }

    this._timer = Timer.periodic(
        Duration(microseconds: (1 / this.fps * 1000000).ceil()), (_) async {
      this._frame.value = MemoryImage(this._buffer[this._position]);
      this._position++;
      if (this._position >= this._buffer.length) {
        if (this.isLoop)
          this._position = 0;
        else
          await this.stop();
      }
    });
  }

  Future<void> pause() async {
    await super.pause();
    this._timer?.cancel();
  }

  Future<void> stop() async {
    await super.stop();
    this._timer?.cancel();
    this._position = 0;
  }
}
