import 'package:book_app/core/constants/app_colors.dart';
import 'package:book_app/extensions/storage_ext.dart';
import 'package:flutter/material.dart';

ThemeData appLightTheme({String? fontFamily}) {
  final family = fontFamily ?? "".boxfontFamily;
  return ThemeData(
    fontFamily: family.isEmpty ? null : family,
    scaffoldBackgroundColor: AppColors.bgLight,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: AppColors.secondary),
  );
}

ThemeData appDarkTheme({String? fontFamily}) {
  final family = fontFamily ?? "".boxfontFamily;
  return ThemeData(
    fontFamily: family.isEmpty ? null : family,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgDark,
    cardColor: AppColors.cardDark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      background: AppColors.bgDark,
      surface: AppColors.cardDark,
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: AppColors.secondary),
  );
}
