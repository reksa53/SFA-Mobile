import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/toko.dart';

class TokoCard extends StatelessWidget {
  const TokoCard({super.key, required this.toko, this.onTap});

  final Toko toko;
  final VoidCallback? onTap;

  static const double _photoSize = 82;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10);

    return Material(
      color: AppColors.card,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: _photoSize,
                height: _photoSize,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: _photoSize,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        toko.nama,
                        style: AppTextStyles.cardTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              toko.pemilik,
                              style: AppTextStyles.cardBody,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('(${toko.telepon})',
                              style: AppTextStyles.cardBody),
                        ],
                      ),
                      Text(
                        toko.alamat,
                        style: AppTextStyles.cardBody,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}