import 'package:flutter/material.dart';
import 'package:sfa_mobile/ui/core/theme/app_colors.dart';
import 'package:sfa_mobile/ui/core/theme/app_text_styles.dart';

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final canAdd = value < max;
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF9B9B9B)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            customBorder: const CircleBorder(),
            onTap: value > 0 ? () => onChanged(value - 1) : null,
            child: SizedBox(
              width: 24,
              height: 24,
              child: Icon(
                Icons.remove,
                size: 16,
                color: value > 0 ? AppColors.black : AppColors.grey,
              ),
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: AppTextStyles.cardBody
                  .copyWith(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          InkWell(
            customBorder: const CircleBorder(),
            onTap: canAdd ? () => onChanged(value + 1) : null,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: canAdd ? AppColors.red : AppColors.grey,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 15, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}