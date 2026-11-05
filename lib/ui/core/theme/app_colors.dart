import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Palet final
  static const red = Color(0xFFC80000);
  static const white = Color(0xFFFFFFFF);
  static const grey = Color(0xFFC7C7C7);
  static const black = Color(0xFF000000);

  // Turunan palet (opasitas)
  static const glass = Color(0x38FFFFFF);       // putih 22%
  static const glassBorder = Color(0x66FFFFFF); // putih 40%
  static const whiteSoft = Color(0xB3FFFFFF);   // putih 70%
  static const overlay = Color(0x59000000);     // hitam 35%

  // Dari Figma versi lama. Belum ada di palet final, jangan dihapus
  static const background = Color(0xFF474747);
  static const card = Color(0xFFBCBCBC);
  static const navBarGlass = Color(0x806F6F6F); // 6F6F6F, opasitas 50%
}