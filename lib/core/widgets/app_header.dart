import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.title, this.onProfileTap});

  final String title;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(title, style: AppTextStyles.headerTitle),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Profil',
                onPressed: onProfileTap,
                icon: const Icon(
                  Icons.account_circle,
                  size: 32,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}