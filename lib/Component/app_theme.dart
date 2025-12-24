import 'package:book_app/extensions/storage_ext.dart';
import 'package:flutter/material.dart';

ThemeData appLightTheme({String? fontFamily}) {
  final family = fontFamily ?? "".boxfontFamily;
  return ThemeData(
    fontFamily: family.isEmpty ? null : family,
    scaffoldBackgroundColor: Colors.white,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6C5CE7),
      brightness: Brightness.light,
    ),
  );
}

ThemeData appDarkTheme({String? fontFamily}) {
  final family = fontFamily ?? "".boxfontFamily;
  return ThemeData(
    fontFamily: family.isEmpty ? null : family,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F1115),
    cardColor: const Color(0xFF1A1D23),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6C5CE7),
      brightness: Brightness.dark,
      background: const Color(0xFF0F1115),
      surface: const Color(0xFF1A1D23),
    ),
  );
}
