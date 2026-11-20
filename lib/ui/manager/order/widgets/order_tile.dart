import 'package:flutter/material.dart';
import 'package:sfa_mobile/data/models/order.dart';
import 'package:sfa_mobile/ui/core/theme/app_colors.dart';
import 'package:sfa_mobile/ui/core/theme/app_text_styles.dart';
import 'package:sfa_mobile/ui/core/widgets/order_status_badge.dart';

class OrderTile extends StatelessWidget {
  const OrderTile({super.key, required this.number, required this.order, this.showSales = false});

  static const _grey = Color(0xFF6B7280);
  final int number;
  final Order order;
  final bool showSales;

  @override
  Widget build(BuildContext context) {
    final subtitles = [
      if (showSales && order.salesName != null) 'Sales: ${order.salesName}',
      if (order.invoice != null) 'Inv. ${order.invoice}',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              child: Container(
                width: 28,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: const Color(0xFFF1F3F7), borderRadius: BorderRadius.circular(8)),
                child: Text('${number.toString().padLeft(2, '0')}.', style: AppTextStyles.navLabel.copyWith(color: _grey)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    order.storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardBody.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.black),
                  ),
                  for (final line in subtitles)
                    Text(line, style: AppTextStyles.cardBody.copyWith(fontSize: 12, color: _grey)),
                ],
              ),
            ),
            Align(alignment: Alignment.bottomRight, child: OrderStatusBadge(status: order.status)),
          ],
        ),
      ),
    );
  }
}