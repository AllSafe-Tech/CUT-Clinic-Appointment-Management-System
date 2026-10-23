import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'brand.dart';

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: CutColors.blue,
    brightness: Brightness.light,
  ).copyWith(
    primary: CutColors.blue,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFD9E5F5),
    onPrimaryContainer: CutColors.blue,
    secondary: CutColors.gold,
    onSecondary: CutColors.blue,
    secondaryContainer: const Color(0xFFFFF0CC),
    onSecondaryContainer: const Color(0xFF4A3400),
    error: CutColors.red,
    onError: Colors.white,
    surface: Colors.white,
    surfaceContainerLow: Colors.white,
    outline: const Color(0xFF8792A6),
    outlineVariant: CutColors.border,
  );

  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: CutColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: CutColors.blue,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: border(CutColors.border),
      enabledBorder: border(CutColors.border),
      focusedBorder: border(CutColors.blue, 2),
      errorBorder: border(CutColors.red),
      focusedErrorBorder: border(CutColors.red, 2),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: CutColors.blue,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: CutColors.blue,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: CutColors.blue),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: CutColors.blue),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: CutColors.border),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: CutColors.gold.withAlpha(110),
      elevation: 3,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: CutColors.blueDark,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: const DividerThemeData(color: CutColors.border, space: 1),
  );
}