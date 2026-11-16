import 'package:flutter/material.dart';
import 'package:sfa_mobile/ui/core/theme/app_colors.dart';

class SearchIconButton extends StatelessWidget {
  const SearchIconButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.search, color: AppColors.black),
        ),
      ),
    );
  }
}