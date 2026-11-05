import 'package:flutter/material.dart';

import '../../../config/app_assets.dart';
import '../../core/theme/app_colors.dart';

/// Foto latar + lapisan gelap, konten di tengah. Dipakai Login dan Register.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(AppAssets.loginBackground, fit: BoxFit.cover),
        const ColoredBox(color: AppColors.overlay),
        // Scaffold di atas foto: keyboard mengecilkan konten, bukan fotonya.
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}