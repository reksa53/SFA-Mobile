import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'manager_colors.dart';

/// Token warna semantik. Layar memakai ini (lewat `context.palette`), bukan
/// warna hardcode, supaya bisa berganti mode gelap / terang.
///
/// Mode gelap sengaja dipetakan ke [AppColors] dan warna yang sudah dipakai di
/// layar, jadi tampilannya sama dengan sebelum ada sistem tema.
@immutable
class AppPalette {
  const AppPalette({
    required this.isDark,
    required this.bg,
    required this.bgDeep,
    required this.surface,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.field,
    required this.divider,
    required this.surfaceBorder,
    required this.glass,
    required this.glassBorder,
    required this.glassStrong,
    required this.glassButton,
    required this.glassChip,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.textGhost,
    required this.hint,
    required this.chip,
    required this.onChip,
    required this.badge,
    required this.calendar,
    required this.panelField,
    required this.fieldHint,
    required this.sheet,
    required this.error,
    required this.navBar,
    required this.navIdle,
  });

  final bool isDark;

  /// Latar layar (Home, Visit, Product, dll).
  final Color bg;

  /// Latar layar yang lebih gelap (Customer).
  final Color bgDeep;

  /// Kartu / daftar "putih", dialog, bottom sheet. Putih di kedua mode.
  final Color surface;
  final Color onSurface;
  final Color onSurfaceMuted;

  /// Isi kolom input di atas [surface].
  final Color field;

  /// Garis pemisah di atas [surface].
  final Color divider;

  /// Garis tepi [surface] (null di mode gelap).
  final Border? surfaceBorder;

  /// Panel tembus pandang di atas [bg], plus garis tepi, tombol, dan chip-nya.
  final Color glass;
  final Color glassBorder;
  final Color glassStrong;
  final Color glassButton;
  final Color glassChip;

  /// Teks di atas [bg]: utama, sekunder, samar, dan sangat samar.
  final Color text;
  final Color textMuted;
  final Color textFaint;
  final Color textGhost;

  /// Teks petunjuk (hint) di atas [bg].
  final Color hint;

  /// Chip / badge angka kecil, dan teks di atasnya.
  final Color chip;
  final Color onChip;

  /// Badge angka di ringkasan (di atas [bg]).
  final Color badge;

  /// Panel besar (kalender, form) dan kolom input di dalamnya.
  final Color calendar;
  final Color panelField;
  final Color fieldHint;

  /// Bottom sheet / menu gelap.
  final Color sheet;

  /// Teks / garis error.
  final Color error;

  /// Navbar melayang.
  final Color navBar;
  final Color navIdle;

  static final AppPalette dark = AppPalette(
    isDark: true,
    bg: AppColors.background,
    bgDeep: const Color(0xFF3A3A3A),
    surface: AppColors.white,
    onSurface: AppColors.black,
    onSurfaceMuted: Colors.black54,
    field: const Color(0xFFF3F3F3),
    divider: const Color(0xFFE6E6E6),
    surfaceBorder: null,
    glass: const Color(0x14FFFFFF),
    glassBorder: Colors.white10,
    glassStrong: const Color(0x1AFFFFFF),
    glassButton: const Color(0x24FFFFFF),
    glassChip: AppColors.glass,
    text: AppColors.white,
    textMuted: Colors.white70,
    textFaint: Colors.white54,
    textGhost: Colors.white24,
    hint: AppColors.grey,
    chip: AppColors.grey,
    onChip: AppColors.white,
    badge: AppColors.black.withValues(alpha: 0.35),
    calendar: ManagerColors.calendar,
    panelField: const Color(0xFF3F3F3F),
    fieldHint: Colors.white38,
    sheet: const Color(0xFF565656),
    error: const Color(0xFFFF8A8A),
    navBar: AppColors.navBarGlass,
    navIdle: AppColors.grey,
  );

  static final AppPalette light = AppPalette(
    isDark: false,
    bg: const Color(0xFFF3F4F6),
    bgDeep: const Color(0xFFF3F4F6),
    surface: Colors.white,
    onSurface: const Color(0xFF111827),
    onSurfaceMuted: const Color(0xFF6B7280),
    field: const Color(0xFFF1F2F4),
    divider: const Color(0xFFE5E7EB),
    surfaceBorder: Border.all(color: const Color(0xFFE5E7EB)),
    glass: Colors.white,
    glassBorder: const Color(0xFFE5E7EB),
    glassStrong: const Color(0xFFE5E7EB),
    glassButton: const Color(0xFFE5E7EB),
    glassChip: const Color(0xFFE5E7EB),
    text: const Color(0xFF111827),
    textMuted: const Color(0xFF4B5563),
    textFaint: const Color(0xFF6B7280),
    textGhost: const Color(0xFFC4C8CE),
    hint: const Color(0xFF9CA3AF),
    chip: const Color(0xFFE5E7EB),
    onChip: const Color(0xFF374151),
    badge: const Color(0xFFE5E7EB),
    calendar: Colors.white,
    panelField: const Color(0xFFF1F2F4),
    fieldHint: const Color(0xFF9CA3AF),
    sheet: Colors.white,
    error: const Color(0xFFD32F2F),
    navBar: const Color(0xE6FFFFFF),
    navIdle: const Color(0xFF6B7280),
  );
}
