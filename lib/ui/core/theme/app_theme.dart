import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';



class AppTheme {
  AppTheme._();

  static ThemeData get theme => ThemeData(

        filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(200, 44),
        shape: const StadiumBorder(),
        textStyle: AppTextStyles.button,
      ),
    ),
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.red,
          onPrimary: AppColors.white,
          surface: AppColors.background,
          onSurface: AppColors.white,
          error: AppColors.red,
        ),
      );
}