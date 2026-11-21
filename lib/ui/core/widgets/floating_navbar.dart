import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class NavItem {
  const NavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Navbar melayang: bar gelap solid, tab aktif melebar menjadi pil merah
/// berisi ikon + label, tab lain hanya ikon. Daftar tab diberikan shell tiap
/// role.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _barColor = Color(0xFF333333);
  static const _padding = 8.0;
  static const _gap = 4.0;

  /// Tab aktif selebar 2,3 tab biasa.
  static const _activeWeight = 2.3;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: _padding),
        decoration: BoxDecoration(
          color: _barColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0x1AFFFFFF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x59000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final n = items.length;
            final free = c.maxWidth - _gap * (n - 1);
            final unit = free / (_activeWeight + (n - 1));
            final activeW = unit * _activeWeight;

            return Row(
              children: [
                for (var i = 0; i < n; i++) ...[
                  if (i > 0) const SizedBox(width: _gap),
                  _NavButton(
                    item: items[i],
                    selected: i == currentIndex,
                    width: i == currentIndex ? activeW : unit,
                    expandedWidth: activeW,
                    onTap: () => onTap(i),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.width,
    required this.expandedWidth,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final double width;
  final double expandedWidth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.white : Colors.white60;
    final radius = BorderRadius.circular(24);

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: width,
        height: 48,
        decoration: BoxDecoration(
          color: selected ? AppColors.red : Colors.transparent,
          borderRadius: radius,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: ClipRect(
              child: OverflowBox(
                minWidth: 0,
                maxWidth: expandedWidth,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, color: color, size: 24),
                    if (selected) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
