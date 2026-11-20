import 'package:flutter/material.dart';

import '../../../data/models/product.dart';
import '../../../data/services/product_service.dart';
import '/utils/format.dart';
import '../../core/theme/app_colors.dart';
import '/ui/core/widgets/common.dart';
import '../../manager/product/product_detail_screen.dart';

// Product List untuk role sales: hanya baca, tanpa tambah/filter.
class SalesProductListScreen extends StatefulWidget {
  const SalesProductListScreen({super.key});

  @override
  State<SalesProductListScreen> createState() => _SalesProductListScreenState();
}

class _SalesProductListScreenState extends State<SalesProductListScreen> {
  final _svc = ProductService.instance;
  final _search = TextEditingController();
  final _brands = <String>{};
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _svc.load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _match(Product p) {
    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty && !p.name.toLowerCase().contains(q) && !p.sku.toLowerCase().contains(q)) {
      return false;
    }
    return _brands.isEmpty || _brands.contains(p.brand);
  }

  void _toggleSearch() => setState(() {
        _searching = !_searching;
        if (!_searching) _search.clear();
      });

  void _flipBrand(String b) => setState(() {
        if (!_brands.remove(b)) _brands.add(b);
      });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _svc,
        builder: (context, _) {
          final all = _svc.active;
          final shown = all.where(_match).toList();

          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
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
                                style: kInputStyle,
                                decoration: const InputDecoration(
                                  hintText: 'Cari nama atau SKU...',
                                  hintStyle: TextStyle(color: kTextMuted),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 13),
                                ),
                              ),
                            )
                          : const Text(
                              'Product List',
                              style: TextStyle(color: AppColors.white, fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _toggleSearch,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
                        child: Icon(_searching ? Icons.close : Icons.search, color: AppColors.black),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (final b in _svc.brands)
                        GestureDetector(
                          onTap: () => _flipBrand(b),
                          child: Container(
                            height: 26,
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _brands.contains(b) ? AppColors.red : AppColors.grey,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Text(
                              b,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _brands.contains(b) ? AppColors.white : AppColors.black,
                              ),
                            ),
                          ),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(24)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: shown.isEmpty
                            ? Center(
                                child: _svc.loading
                                    ? const CircularProgressIndicator(color: AppColors.red)
                                    : Text(_svc.error ?? 'Produk tidak ditemukan',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.black)),
                              )
                            : ScrollConfiguration(
                                behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
                                child: Scrollbar(
                                  thickness: 3,
                                  radius: const Radius.circular(8),
                                  child: ListView.separated(
                                    physics: const ClampingScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    itemCount: shown.length,
                                    separatorBuilder: (_, _) =>
                                        const Divider(height: 1, indent: 14, endIndent: 14),
                                    itemBuilder: (_, i) => _Row(
                                      product: shown[i],
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductDetailScreen(product: shown[i], canEdit: false),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _Stat('Available', all.where((p) => p.stock > 0).length)),
                    const SizedBox(width: 24),
                    Expanded(child: _Stat('Near Expired', all.where((p) => p.nearExpired).length)),
                  ]),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          );
        },
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final out = p.stock == 0;
    final exp = p.nearestExpiry;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: const Color(0xFFF1F4F8), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.inventory_2_outlined, color: kTextMuted, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.black)),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 11, color: kTextMuted),
                  children: [
                    TextSpan(text: '${p.sku} · EXP. '),
                    TextSpan(
                      text: exp == null ? '-' : fmtDate(exp),
                      style: p.nearExpired
                          ? const TextStyle(color: AppColors.red, fontWeight: FontWeight.bold)
                          : null,
                    ),
                  ],
                ),
              ),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              width: 72,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.grey, borderRadius: BorderRadius.circular(8)),
              child: Text(
                out ? 'Out of stock' : '${p.stock} ${p.unit}',
                style: TextStyle(fontSize: out ? 10 : 13, fontWeight: FontWeight.bold, color: AppColors.black),
              ),
            ),
            const SizedBox(height: 4),
            Text(fmtRp(p.price),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.black)),
          ]),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(label, style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.bold))),
        Container(
          width: 32,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.glass, borderRadius: BorderRadius.circular(8)),
          child: Text('$value', style: const TextStyle(color: AppColors.white, fontSize: 11)),
        ),
      ]);
}