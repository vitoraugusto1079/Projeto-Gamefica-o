import 'package:flutter/material.dart';

/// Paleta da identidade visual do PHP Defense.
class AppColors {
  static const background = Color(0xFF050B1A);
  static const surface = Color(0xFF0B1630);
  static const surfaceHigh = Color(0xFF12224A);
  static const border = Color(0xFF1E3A6E);
  static const cyan = Color(0xFF00E5FF);
  static const purple = Color(0xFFB04DFF);
  static const red = Color(0xFFFF3D5A);
  static const green = Color(0xFF3DFFA2);
  static const amber = Color(0xFFFFC23D);
  static const text = Color(0xFFE6F1FF);
  static const textDim = Color(0xFF8BA3C7);
  static const gold = Color(0xFFFFD54F);
  static const silver = Color(0xFFCFD8DC);
  static const bronze = Color(0xFFD7965B);
}

ThemeData buildAppTheme() {
  final scheme = const ColorScheme.dark(
    primary: AppColors.cyan,
    secondary: AppColors.purple,
    error: AppColors.red,
    surface: AppColors.surface,
    onPrimary: AppColors.background,
    onSecondary: Colors.white,
    onSurface: AppColors.text,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'monospace',
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: AppColors.text, displayColor: AppColors.text),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      labelStyle: const TextStyle(color: AppColors.textDim),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.cyan, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.red, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        backgroundColor: AppColors.cyan,
        foregroundColor: AppColors.background,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: AppColors.cyan,
        side: const BorderSide(color: AppColors.cyan),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48), foregroundColor: AppColors.cyan),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surfaceHigh,
      contentTextStyle: TextStyle(color: AppColors.text),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: const DialogThemeData(backgroundColor: AppColors.surface),
  );
}
