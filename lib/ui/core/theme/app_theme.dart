import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_palette.dart';
import 'theme_controller.dart';

export 'app_palette.dart';
export 'theme_controller.dart';
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

    static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.red,
      brightness: Brightness.light,
    ).copyWith(primary: AppColors.red),
    scaffoldBackgroundColor: AppPalette.light.bg,
  );
}





/// Bungkus layar yang sudah dimigrasi ke token warna.
///
/// Mode gelap: tidak mengubah apa-apa (memakai tema aplikasi yang sekarang).
/// Mode terang: memberi ThemeData terang, supaya dialog, date picker, dan widget
/// Material lain di dalam layar ikut terang. Layar yang belum dimigrasi tidak
/// dibungkus, jadi tetap gelap.
class ThemedPage extends StatelessWidget {
  const ThemedPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (context.palette.isDark) return child;
    return Theme(data: AppTheme.light, child: child);
  }
}