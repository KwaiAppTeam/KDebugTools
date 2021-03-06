// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'common_widgets.dart';
import 'ui/theme.dart';

/// Constructs the light or dark theme for the app
ThemeData themeFor({
  @required bool isDarkTheme,
}) {
  return isDarkTheme ? _darkTheme() : _lightTheme();
}

ThemeData _darkTheme() {
  final theme = ThemeData.dark();
  return _baseTheme(
    theme: theme,
    primaryColor: devtoolsGrey[900],
    backgroundColor: theme.canvasColor,
    indicatorColor: devtoolsBlue[400],
    selectedRowColor: devtoolsGrey[600],
  );
}

ThemeData _lightTheme() {
  final theme = ThemeData.light();
  return _baseTheme(
    theme: theme,
    primaryColor: devtoolsBlue[600],
    backgroundColor: theme.canvasColor,
    indicatorColor: Colors.yellowAccent[400],
    selectedRowColor: devtoolsBlue[600],
  );
}

ThemeData _baseTheme({
  @required ThemeData theme,
  @required Color primaryColor,
  @required Color backgroundColor,
  @required Color indicatorColor,
  @required Color selectedRowColor,
}) {
  return theme.copyWith(
    primaryColor: primaryColor,
    indicatorColor: indicatorColor,
    selectedRowColor: selectedRowColor,
    // Same values for both light and dark themes.
    primaryColorDark: devtoolsBlue[700],
    primaryColorLight: devtoolsBlue[400],
    accentColor: devtoolsBlue[400],
    backgroundColor: devtoolsGrey[600],
    toggleableActiveColor: devtoolsBlue[400],
    canvasColor: backgroundColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: theme.colorScheme.copyWith(background: backgroundColor),
    // TODO(kenz): add fixed height to all of these button themes when
    // https://github.com/flutter/flutter/issues/73741 is fixed.
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        primary: theme.colorScheme.contrastForeground,
        minimumSize: const Size(buttonMinWidth, defaultButtonHeight),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        primary: theme.colorScheme.contrastForeground,
        minimumSize: const Size(buttonMinWidth, defaultButtonHeight),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(buttonMinWidth, defaultButtonHeight),
      ),
    ),
  );
}

/// Threshold used to determine whether a colour is light/dark enough for us to
/// override the default DevTools themes with.
///
/// A value of 0.5 would result in all colours being considered light/dark, and
/// a value of 0.1 allowing around only the 10% darkest/lightest colours by
/// Flutter's luminance calculation.
const _lightDarkLuminanceThreshold = 0.1;

bool isValidDarkColor(Color color) {
  if (color == null) {
    return false;
  }
  return color.computeLuminance() <= _lightDarkLuminanceThreshold;
}

bool isValidLightColor(Color color) {
  if (color == null) {
    return false;
  }
  return color.computeLuminance() >= 1 - _lightDarkLuminanceThreshold;
}

const defaultButtonHeight = 36.0;
const buttonMinWidth = 36.0;

const defaultIconSize = 16.0;
const actionsIconSize = 20.0;
const defaultIconThemeSize = 24.0;

const defaultSpacing = 16.0;
const denseSpacing = 8.0;
const denseRowSpacing = 6.0;

const defaultBorderRadius = 4.0;

const borderPadding = 2.0;
const densePadding = 4.0;

const smallProgressSize = 12.0;

const defaultListItemHeight = 28.0;

const defaultChartHeight = 150.0;

const defaultScrollBarOffset = 10.0;

const defaultTabBarViewPhysics = NeverScrollableScrollPhysics();

/// Branded grey color.
///
/// Source: https://drive.google.com/open?id=1QBhMJqXyRt-CpRsHR6yw2LAfQtiNat4g
const ColorSwatch<int> devtoolsGrey = ColorSwatch<int>(0xFF202124, {
  900: Color(0xFF202124),
  600: Color(0xFF60646B),
  100: Color(0xFFD5D7Da),
  50: Color(0xFFEAEBEC), // Lerped between grey100 and white
});

/// Branded yellow color.
///
/// Source: https://drive.google.com/open?id=1QBhMJqXyRt-CpRsHR6yw2LAfQtiNat4g
const devtoolsYellow = ColorSwatch<int>(700, {
  700: Color(0xFFFFC108),
});

/// Branded blue color.
///
/// Source: https://drive.google.com/open?id=1QBhMJqXyRt-CpRsHR6yw2LAfQtiNat4g
const devtoolsBlue = ColorSwatch<int>(600, {
  700: Color(0xFF02569B),
  600: Color(0xFF0175C2),
  400: Color(0xFF13B9FD),
});

const devtoolsError = Color(0xFFAF4054);

const devtoolsWarning = Color(0xFFFDFAD5);

const selectedRowBackground = Color(0xFF0175C2);

extension DevToolsColorScheme on ColorScheme {
  Color get devtoolsLink =>
      isLight ? const Color(0xFF1976D2) : Colors.lightBlueAccent;

  Color get defaultBackgroundColor =>
      isLight ? Colors.grey[50] : Colors.grey[850];

  Color get chartAccentColor =>
      isLight ? const Color(0xFFCCCCCC) : const Color(0xFF585858);

  Color get chartTextColor => isLight ? Colors.black : Colors.white;

  Color get chartSubtleColor =>
      isLight ? const Color(0xFF999999) : const Color(0xFF8A8A8A);

  Color get toggleButtonBackgroundColor =>
      isLight ? const Color(0xFFE0EEFA) : const Color(0xFF2E3C48);

  // [toggleButtonForegroundColor] is the same for light and dark theme.
  Color get toggleButtonForegroundColor => const Color(0xFF2196F3);

  Color get functionSyntaxColor =>
      isLight ? const Color(0xFF795E26) : const Color(0xFFDCDCAA);

  Color get declarationsSyntaxColor =>
      isLight ? const Color(0xFF267f99) : const Color(0xFF4EC9B0);

  Color get modifierSyntaxColor =>
      isLight ? const Color(0xFF0000FF) : const Color(0xFF569CD6);

  Color get controlFlowSyntaxColor =>
      isLight ? const Color(0xFFAF00DB) : const Color(0xFFC586C0);

  Color get variableSyntaxColor =>
      isLight ? const Color(0xFF001080) : const Color(0xFF9CDCFE);

  Color get commentSyntaxColor =>
      isLight ? const Color(0xFF008000) : const Color(0xFF6A9955);

  Color get stringSyntaxColor =>
      isLight ? const Color(0xFFB20001) : const Color(0xFFD88E73);

  Color get numericConstantSyntaxColor =>
      isLight ? const Color(0xFF098658) : const Color(0xFFB5CEA8);

  // Light theme hover background is semi-transparent YellowAccent[100].
  Color get hoverBackgroundColor => const Color.fromARGB(150, 255, 255, 141);

  // Bar color for current selection (hover).
  Color get hoverSelectionBarColor =>
      isLight ? Colors.lime[600] : Colors.yellowAccent;

  Color get selectedListRowBackgroundColor => selectedRowBackground;

  // Title of the hover card.
  TextStyle get hoverTitleTextStyle => const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 16,
        decoration: TextDecoration.none,
      );

  // Items in the hover vard.
  TextStyle get hoverTextStyle => const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 11.5,
        decoration: TextDecoration.none,
      );

  // Value of items in hover e.g., capacity, etc.
  TextStyle get hoverValueTextStyle => const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.normal,
        fontSize: 11.5,
        decoration: TextDecoration.none,
      );

  // Used for custom extension event values.
  TextStyle get hoverSmallValueTextStyle => const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.normal,
        fontSize: 10,
        decoration: TextDecoration.none,
      );
}

Color titleSolidBackgroundColor(ThemeData theme) {
  return theme.canvasColor.darken(0.2);
}

Color actionBarBackgroundColor(ThemeData theme) {
  return theme.canvasColor.darken(0.2);
}
