import 'package:flutter/material.dart';

import '../../../data/models/product.dart';
import '../../core/theme/app_colors.dart';

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

enum _Status { all, available, outOfStock, nearExpired }

const _statusLabel = {
  _Status.all: 'Semua',
  _Status.available: 'Available',
  _Status.outOfStock: 'Out of stock',
  _Status.nearExpired: 'Near expired',
};

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _search = TextEditingController();
  bool _searching = false;
  String? _brand;
  _Status _status = _Status.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _isNear(Product p) =>
      p.expiry.isBefore(DateTime.now().add(const Duration(days: 730)));

  bool _match(Product p) {
    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty && !p.name.toLowerCase().contains(q)) return false;
    if (_brand != null &&
        !p.name.toLowerCase().contains(_brand!.toLowerCase())) {
      return false;
    }
    switch (_status) {
      case _Status.all:
        return true;
      case _Status.available:
        return p.stock > 0;
      case _Status.outOfStock:
        return p.stock == 0;
      case _Status.nearExpired:
        return _isNear(p);
    }
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) _search.clear();
    });
  }

  void _openFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Filter Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ),
            for (final s in _Status.values)
              ListTile(
                title: Text(
                  _statusLabel[s]!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                trailing: _status == s
                    ? const Icon(Icons.check, color: AppColors.red)
                    : null,
                onTap: () {
                  setState(() => _status = s);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = dummyProducts;
    final shown = items.where(_match).toList();
    final outOfStock = items.where((p) => p.stock == 0).length;
    final nearExpired = items.where(_isNear).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _searching
                        ? Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _search,
                              autofocus: true,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(
                                color: AppColors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Cari produk...',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                              ),
                            ),
                          )
                        : const Text(
                            'Product List',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _toggleSearch,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _searching ? Icons.close : Icons.search,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final b in const [
                            'Indomie',
                            'Sosro',
                            'Ultra Milk',
                            'Kapal Api',
                          ])
                            GestureDetector(
                              onTap: () => setState(
                                () => _brand = _brand == b ? null : b,
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _brand == b
                                      ? AppColors.red
                                      : AppColors.grey,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  b,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _brand == b
                                        ? AppColors.white
                                        : AppColors.black,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _openFilter,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.tune,
                          color: AppColors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Filter',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                          ),
                        ),
                        if (_status != _Status.all) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
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
                    child: shown.isEmpty
                        ? const Center(
                            child: Text(
                              'Produk tidak ditemukan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                          )
                        : ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
                          child: Scrollbar(
                            thickness: 3,
                            radius: const Radius.circular(8),
                            child: ListView.separated(
                              physics: const ClampingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              itemCount: shown.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                indent: 14,
                                endIndent: 14,
                              ),
                          
                              itemBuilder: (_, i) =>
                                  _Row(index: i + 1, product: shown[i]),
                            ),
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
              const SizedBox(height: 16),
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
                    color: AppColors.black,
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
          SizedBox(
            width: 72,
            height: 30,
            child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.grey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
            child: Text(
              out ? 'Out of stock' : '${product.stock} box',
              style: TextStyle(
                fontSize: out ? 10 : 13,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
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
        width: 28,
        padding: const EdgeInsets.symmetric(vertical: 2),
        alignment: Alignment.center,
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
