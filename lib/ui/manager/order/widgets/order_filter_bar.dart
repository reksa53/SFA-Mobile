import 'package:flutter/material.dart';
import 'package:sfa_mobile/ui/core/theme/app_colors.dart';
import 'package:sfa_mobile/ui/core/theme/app_text_styles.dart';

class OrderFilterBar extends StatelessWidget {
  const OrderFilterBar({super.key, required this.selected, required this.onSelected, this.onStatusTap});

  /// Kunci = nilai parameter `period` di API, value = label chip.
  static const _periods = {'hari': 'Hari', 'minggu': 'Minggu', 'bulan': 'Bulan', 'tahun': 'Tahun'};

  final String? selected;
  final ValueChanged<String> onSelected;
  final VoidCallback? onStatusTap;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final p in _periods.entries) ...[
                _PeriodChip(label: p.value, active: p.key == selected, onTap: () => onSelected(p.key)),
                const SizedBox(width: 6),
              ],
            ]),
          ),
        ),
        InkWell(
          onTap: onStatusTap,
          child: Row(children: [
            const Icon(Icons.tune, size: 18, color: AppColors.white),
            const SizedBox(width: 6),
            Text('Status', style: AppTextStyles.navLabel.copyWith(fontSize: 13, color: AppColors.white)),
          ]),
        ),
      ]);
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: active ? AppColors.white : AppColors.grey,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            Text(label, style: AppTextStyles.navLabel.copyWith(fontSize: 12, color: AppColors.black)),
            const SizedBox(width: 4),
            const Icon(Icons.schedule, size: 13, color: AppColors.black),
          ]),
        ),
      );
}