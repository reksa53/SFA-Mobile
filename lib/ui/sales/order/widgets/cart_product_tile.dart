import 'package:flutter/material.dart';
import 'package:sfa_mobile/data/repositories/order_repository.dart';
import 'package:sfa_mobile/ui/core/theme/app_colors.dart';
import 'package:sfa_mobile/ui/core/theme/app_text_styles.dart';
import 'package:sfa_mobile/ui/sales/order/widgets/quantity_stepper.dart';
import 'package:sfa_mobile/utils/rupiah.dart';

class CartProductTile extends StatelessWidget {
  const CartProductTile({
    super.key,
    required this.item,
    required this.quantity,
    required this.onChanged,
  });

  final CatalogItem item;
  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.grey,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.image_outlined,
                size: 28, color: AppColors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardBody.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatRupiah(item.price),
                  style: AppTextStyles.cardBody.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (item.available)
            QuantityStepper(
              value: quantity,
              max: product.stock,
              onChanged: onChanged,
            )
          else
            Text(
              'Tidak tersedia',
              style: AppTextStyles.cardBody.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.red,
              ),
            ),
        ],
      ),
    );
  }
}
