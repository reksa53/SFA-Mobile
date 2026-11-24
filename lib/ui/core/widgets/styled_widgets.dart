import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Simpan di: lib/core/widgets/styled_widgets.dart
/// Widget gaya bersama untuk Home Manager & Home Sales.

/// Judul section: aksen vertikal + ikon + judul (+ pill keterangan di kanan).
class StyledSection extends StatelessWidget {
  const StyledSection({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 18, color: p.textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: p.text,
                ),
              ),
            ),
            if (trailing != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: p.glassBorder.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  trailing!,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: p.textMuted,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

/// Avatar inisial berwarna lembut.
class StyledAvatar extends StatelessWidget {
  const StyledAvatar({
    super.key,
    required this.name,
    required this.color,
    this.size = 38,
  });

  final String name;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        initial,
        style: GoogleFonts.poppins(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Pill status kecil (Done / Missed / Pending, dst).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class Seg {
  const Seg(this.value, this.color);
  final int value;
  final Color color;
}

/// Bar proporsi bersegmen.
class SegmentBar extends StatelessWidget {
  const SegmentBar({super.key, required this.segments});

  final List<Seg> segments;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final active = segments.where((s) => s.value > 0).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 8,
        child: active.isEmpty
            ? ColoredBox(color: p.glassBorder.withValues(alpha: 0.5))
            : Row(
                children: [
                  for (var i = 0; i < active.length; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      flex: active[i].value,
                      child: ColoredBox(color: active[i].color),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Kerangka hero card: gradient merah + lingkaran dekoratif.
class HeroShell extends StatelessWidget {
  const HeroShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget circle(double size, double alpha) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE53935), Color(0xFF7F0F14)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.red.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(right: -40, top: -50, child: circle(150, 0.08)),
          Positioned(right: 30, bottom: -60, child: circle(110, 0.06)),
          child,
        ],
      ),
    );
  }
}

/// Animasi masuk bertahap (fade + geser halus).
class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (_, t, c) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 18), child: c),
      ),
      child: child,
    );
  }
}
