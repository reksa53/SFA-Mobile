import 'package:flutter/material.dart';
import 'package:sfa_mobile/ui/core/theme/app_text_styles.dart';
import 'package:sfa_mobile/ui/core/theme/app_theme.dart';

class OrderSummary extends StatelessWidget {
  const OrderSummary({
    super.key,
    required this.all,
    required this.pending,
    required this.accepted,
    required this.rejected,
  });

  final int all;
  final int pending;
  final int accepted;
  final int rejected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              OrderStat(label: 'All Order', value: all),
              const SizedBox(height: 8),
              OrderStat(label: 'Pending', value: pending),
            ],
          ),
          Column(
            children: [
              OrderStat(label: 'Accepted', value: accepted),
              const SizedBox(height: 8),
              OrderStat(label: 'Rejected', value: rejected),
            ],
          ),
        ],
      ),
    );
  }
}

class OrderStat extends StatelessWidget {
  const OrderStat({super.key, required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return SizedBox(
      width: 130,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.navLabel.copyWith(fontSize: 14, color: p.text),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: p.badge,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$value',
              style: AppTextStyles.navLabel.copyWith(color: p.onChip),
            ),
          ),
        ],
      ),
    );
  }
}
