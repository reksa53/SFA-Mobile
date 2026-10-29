import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.rose,
          onPrimary: AppColors.white,
          surface: AppColors.background,
          onSurface: AppColors.white,
          error: AppColors.rose,
        ),
      );
}