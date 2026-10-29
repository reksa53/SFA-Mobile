import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/navigation/main_shell.dart';
import 'core/theme/app_theme.dart';

class SfaApp extends StatelessWidget {
  const SfaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Central Sinn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: child!,
      ),
      // Nanti diganti halaman Login, lalu masuk ke MainShell.
      home: const MainShell(),
    );
  }
}