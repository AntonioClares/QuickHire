import 'package:flutter/material.dart';
import 'package:quickhire/core/theme/color_palette.dart';

class AppTheme {
  static final ThemeData quickhireAppTheme = ThemeData.light().copyWith(
    textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Sen'),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: Palette.primary,
      selectionColor: Palette.primary,
      selectionHandleColor: Palette.primary,
    ),
  );
}
