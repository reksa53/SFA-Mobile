import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get headerTitle =>
      GoogleFonts.lilitaOne(fontSize: 24, color: AppColors.white);

  static TextStyle get cardTitle => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.black,
      );

  static TextStyle get cardBody =>
      GoogleFonts.inter(fontSize: 15, color: AppColors.black);


    static TextStyle get fieldLabel => GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.white);

  static TextStyle get fieldText => GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.white);

  static TextStyle get fieldHint =>
      fieldText.copyWith(color: AppColors.whiteSoft);

  static TextStyle get error => GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white);

  static TextStyle get button => GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5);
}