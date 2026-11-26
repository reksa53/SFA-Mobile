import 'package:flutter/material.dart';
import 'package:sfa_mobile/ui/core/theme/app_text_styles.dart';
import 'package:sfa_mobile/ui/core/theme/app_theme.dart';

class OrderFilterBar extends StatelessWidget {
  const OrderFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.onStatusTap,
  });

  /// Kunci = nilai parameter `period` di API, value = label chip.
  static const _periods = {
    'hari': 'Hari',
    'minggu': 'Minggu',
    'bulan': 'Bulan',
    'tahun': 'Tahun',
  };

  final String? selected;
  final ValueChanged<String> onSelected;
  final VoidCallback? onStatusTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final e in _periods.entries) ...[
                  _PeriodChip(
                    label: e.value,
                    active: e.key == selected,
                    onTap: () => onSelected(e.key),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ),
        InkWell(
          onTap: onStatusTap,
          child: Row(
            children: [
              Icon(Icons.tune, size: 18, color: p.text),
              const SizedBox(width: 6),
              Text(
                'Status',
                style: AppTextStyles.navLabel.copyWith(
                  fontSize: 13,
                  color: p.text,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? p.surface : p.chip,
          border: active ? p.surfaceBorder : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: AppTextStyles.navLabel.copyWith(
                fontSize: 12,
                color: p.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.schedule, size: 13, color: p.onSurface),
          ],
        ),
      ),
    );
  }
}