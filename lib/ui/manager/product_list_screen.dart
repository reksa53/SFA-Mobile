import 'package:flutter/material.dart';

import '../../data/models/product.dart';
import '../core/theme/app_colors.dart';

const _months = [
  'jan',
  'feb',
  'mar',
  'apr',
  'mei',
  'jun',
  'jul',
  'agu',
  'sep',
  'okt',
  'nov',
  'des',
];

String _exp(DateTime d) =>
    'EXP. ${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = dummyProducts;
    final outOfStock = items.where((p) => p.stock == 0).length;
    final limit = DateTime.now().add(const Duration(days: 730));
    final nearExpired = items.where((p) => p.expiry.isBefore(limit)).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Product List',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.search),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final b in const [
                    'Indomie',
                    'Sosro',
                    'Ultra Milk',
                    'Kapal Api',
                  ])
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        b,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const Spacer(),
                  const Icon(Icons.tune, color: AppColors.white, size: 16),
                  const SizedBox(width: 4),
                  const Text(
                    'Filter',
                    style: TextStyle(color: AppColors.white, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Scrollbar(
                    thickness: 3,
                    radius: const Radius.circular(8),
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(), // scroll lebih halus, mantul di ujung
                      padding: const EdgeInsets.symmetric(vertical: 6), // baris atas/bawah tidak mepet
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 14, endIndent: 14),
                      itemBuilder: (_, i) => _Row(index: i + 1, product: items[i]),
                    ),
                  ),
                ),
              ),
            ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _Stat('All Product', items.length),
                        const SizedBox(height: 8),
                        _Stat('Near Expired', nearExpired),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        _Stat('Available', items.length - outOfStock),
                        const SizedBox(height: 8),
                        _Stat('Out of Stock', outOfStock),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 110), // ruang buat floating navbar
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.index, required this.product});
  final int index;
  final Product product;

  @override
  Widget build(BuildContext context) {
    final out = product.stock == 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${index.toString().padLeft(2, '0')}.',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _exp(product.expiry),
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.grey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              out ? 'Out of stock' : '${product.stock} box',
              style: TextStyle(
                fontSize: out ? 10 : 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: AppColors.white, fontSize: 13),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$value',
          style: const TextStyle(color: AppColors.white, fontSize: 11),
        ),
      ),
    ],
  );
}
