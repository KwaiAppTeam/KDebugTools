// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';


import 'theme.dart';
import 'ui/theme.dart';

const tooltipWait = Duration(milliseconds: 500);
const tooltipWaitLong = Duration(milliseconds: 1000);


/// Convenience [Divider] with [Padding] that provides a good divider in forms.
class PaddedDivider extends StatelessWidget {
  const PaddedDivider({
    Key key,
    this.padding = const EdgeInsets.only(bottom: 10.0),
  }) : super(key: key);

  const PaddedDivider.thin({Key key})
      : padding = const EdgeInsets.only(bottom: 4.0);

  /// The padding to place around the divider.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: const Divider(thickness: 1.0),
    );
  }
}


/// A widget, commonly used for icon buttons, that provides a tooltip with a
/// common delay before the tooltip is shown.
class DevToolsTooltip extends StatelessWidget {
  const DevToolsTooltip({
    @required this.tooltip,
    @required this.child,
  });

  final String tooltip;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: tooltipWait,
      child: child,
    );
  }
}



BorderSide defaultBorderSide(ThemeData theme) {
  return BorderSide(color: theme.focusColor);
}

/// An extension on [ScrollController] to facilitate having the scrolling widget
/// auto scroll to the bottom on new content.
extension ScrollControllerAutoScroll on ScrollController {

  /// Return whether the view is currently scrolled to the bottom.
  bool get atScrollBottom {
    final pos = position;
    return pos.pixels == pos.maxScrollExtent;
  }

  /// Scroll the content to the bottom using the app's default animation
  /// duration and curve..
  void autoScrollToBottom() async {
    await animateTo(
      position.maxScrollExtent,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOutCubic,
    );

    // Scroll again if we've received new content in the interim.
    if (hasClients) {
      final pos = position;
      if (pos.pixels != pos.maxScrollExtent) {
        jumpTo(pos.maxScrollExtent);
      }
    }
  }
}

/// Utility extension methods to the [Color] class.
extension ColorExtension on Color {
  /// Return a slightly darker color than the current color.
  Color darken([double percent = 0.05]) {
    assert(0.0 <= percent && percent <= 1.0);
    percent = 1.0 - percent;

    final c = this;
    return Color.fromARGB(
      c.alpha,
      (c.red * percent).round(),
      (c.green * percent).round(),
      (c.blue * percent).round(),
    );
  }

  /// Return a slightly brighter color than the current color.
  Color brighten([double percent = 0.05]) {
    assert(0.0 <= percent && percent <= 1.0);

    final c = this;
    return Color.fromARGB(
      c.alpha,
      c.red + ((255 - c.red) * percent).round(),
      c.green + ((255 - c.green) * percent).round(),
      c.blue + ((255 - c.blue) * percent).round(),
    );
  }
}

/// Utility extension methods to the [ThemeData] class.
extension ThemeDataExtension on ThemeData {
  /// Returns whether we are currently using a dark theme.
  bool get isDarkTheme => brightness == Brightness.dark;

  TextStyle get regularTextStyle => TextStyle(color: textTheme.bodyText2.color);

  TextStyle get subtleTextStyle => TextStyle(color: unselectedWidgetColor);

  TextStyle get selectedTextStyle =>
      TextStyle(color: textSelectionTheme.selectionColor);

  TextStyle get consoleText {
    return textTheme.bodyText2.copyWith(fontFamily: 'RobotoMono');
  }

  TextStyle get subtleConsoleText {
    return consoleText.copyWith(color: unselectedWidgetColor);
  }
}

/// Gets an alternating color to use for indexed UI elements.
Color alternatingColorForIndexWithContext(int index, BuildContext context) {
  final theme = Theme.of(context);
  final color = theme.canvasColor;
  return _colorForIndex(color, index, theme.colorScheme);
}

Color alternatingColorForIndex(int index, ColorScheme colorScheme) {
  final color = colorScheme.defaultBackgroundColor;
  return _colorForIndex(color, index, colorScheme);
}

Color _colorForIndex(Color color, int index, ColorScheme colorScheme) {
  if (index % 2 == 1) {
    return color;
  } else {
    return colorScheme.isLight ? color.darken() : color.brighten();
  }
}
