import 'package:flutter/material.dart';
import 'package:sfa_mobile/data/models/order.dart';
import 'package:sfa_mobile/ui/core/theme/app_text_styles.dart';

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final style = _styleOf(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration:
                BoxDecoration(color: style.foreground, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            style.label,
            style: AppTextStyles.navLabel.copyWith(color: style.foreground),
          ),
        ],
      ),
    );
  }

  static _BadgeStyle _styleOf(OrderStatus status) => switch (status) {
        OrderStatus.accepted => const _BadgeStyle(
            'Accepted', Color(0xFFE3F4EA), Color(0xFF1E7B4B)),
        OrderStatus.rejected => const _BadgeStyle(
            'Rejected', Color(0xFFFBE4E7), Color(0xFFC0384B)),
        OrderStatus.pending =>
          const _BadgeStyle('EDIT', Color(0xFFE6EBFA), Color(0xFF3B4FC4)),
      };
}

class _BadgeStyle {
  const _BadgeStyle(this.label, this.background, this.foreground);

  final String label;
  final Color background;
  final Color foreground;
}