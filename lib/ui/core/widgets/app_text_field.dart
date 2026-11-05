import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Input bergaya kaca dengan label di atasnya.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.suffixIcon,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  static const _radius = BorderRadius.all(Radius.circular(28));

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder(
      borderRadius: _radius,
      borderSide: BorderSide(color: AppColors.glassBorder),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: _radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              onSubmitted: onSubmitted,
              textAlign: TextAlign.center,
              cursorColor: AppColors.white,
              style: AppTextStyles.fieldText,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTextStyles.fieldHint,
                filled: true,
                fillColor: AppColors.glass,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                suffixIcon: suffixIcon,
                border: border,
                enabledBorder: border,
                focusedBorder: border.copyWith(
                  borderSide:
                      const BorderSide(color: AppColors.white, width: 1.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}