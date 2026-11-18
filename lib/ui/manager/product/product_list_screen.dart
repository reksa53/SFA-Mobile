import 'package:flutter/material.dart';

import '../../../data/models/product.dart';
import '../../../data/services/product_service.dart';
import '/utils/format.dart';
import '../../core/theme/app_colors.dart';
import '/ui/core/widgets/common.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';

enum _Status { available, outOfStock, nearExpired }

const _statusLabel = {
  _Status.available: 'Available',
  _Status.outOfStock: 'Out of stock',
  _Status.nearExpired: 'Near expired',
};

const _statusIcon = {
  _Status.available: Icons.check_circle_outline,
  _Status.outOfStock: Icons.remove_shopping_cart_outlined,
  _Status.nearExpired: Icons.schedule,
};

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, this.canEdit = true});

  final bool canEdit; // sales = false (hanya baca)

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _svc = ProductService.instance;
  final _search = TextEditingController();
  bool _searching = false;
  final _brands = <String>{};
  final _cats = <String>{};
  _Status? _status;

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

  bool get _filtered =>
      _brands.isNotEmpty || _cats.isNotEmpty || _status != null;

  bool _match(Product p) {
    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty &&
        !p.name.toLowerCase().contains(q) &&
        !p.sku.toLowerCase().contains(q)) {
      return false;
    }
    if (_brands.isNotEmpty && !_brands.contains(p.brand)) return false;
    if (_cats.isNotEmpty && !_cats.contains(p.category)) return false;
    return switch (_status) {
      null => true,
      _Status.available => p.stock > 0,
      _Status.outOfStock => p.stock == 0,
      _Status.nearExpired => p.nearExpired,
    };
  }

  void _flipBrand(String b) {
    if (!_brands.remove(b)) _brands.add(b);
    _cats.retainAll(_svc.categoriesFor(_brands)); // kategori ikut menyempit
  }

  void _flipCat(String c) {
    if (!_cats.remove(c)) _cats.add(c);
  }

  void _toggleSearch() => setState(() {
    _searching = !_searching;
    if (!_searching) _search.clear();
  });

  void _openAdd() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ProductFormScreen()),
  );

  void _openFilter() => showAppSheet<void>(
    context,
    (_) => StatefulBuilder(
      builder: (ctx, setSheet) {
        void upd(VoidCallback f) {
          setState(f);
          setSheet(() {});
        }

        return SheetFrame(
          title: 'Filter',
          action: 'Reset',
          onAction: () => upd(() {
            _brands.clear();
            _cats.clear();
            _status = null;
          }),
          child: Column(
            children: [
              SheetBox(
                title: 'Brand',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final b in _svc.brands)
                      PillChip(
                        label: b,
                        selected: _brands.contains(b),
                        showClose: true,
                        onTap: () => upd(() => _flipBrand(b)),
                      ),
                  ],
                ),
              ),
              SheetBox(
                title: 'Kategori',
                caption: 'sesuai brand terpilih',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in _svc.categoriesFor(_brands))
                      PillChip(
                        label: c,
                        icon: categoryIcon(c),
                        selected: _cats.contains(c),
                        showClose: true,
                        onTap: () => upd(() => _flipCat(c)),
                      ),
                  ],
                ),
              ),
              SheetBox(
                title: 'Status',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in _Status.values)
                      PillChip(
                        label: _statusLabel[s]!,
                        icon: _statusIcon[s],
                        selected: _status == s,
                        showClose: true,
                        onTap: () =>
                            upd(() => _status = _status == s ? null : s),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _svc,
    builder: (context, _) {
      final all = _svc.active;
      final shown = all.where(_match).toList();
      final outOf = all.where((p) => p.stock == 0).length;

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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
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
                    const SizedBox(width: 10),
                    _IconBtn(
                      icon: _searching ? Icons.close : Icons.search,
                      bg: AppColors.white,
                      fg: AppColors.black,
                      onTap: _toggleSearch,
                    ),
                    if (widget.canEdit) ...[
                      const SizedBox(width: 10),
                      _IconBtn(
                        icon: Icons.add,
                        bg: AppColors.red,
                        fg: AppColors.white,
                        onTap: _openAdd,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final b in _svc.brands)
                              GestureDetector(
                                onTap: () => setState(() => _flipBrand(b)),
                                child: Container(
                                  height: 26,
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _brands.contains(b)
                                        ? AppColors.red
                                        : AppColors.grey,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Text(
                                    b,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _brands.contains(b)
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
                          if (_filtered) ...[
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
                          ? Center(
                              child: _svc.loading
                                  ? const CircularProgressIndicator(
                                      color: AppColors.red,
                                    )
                                  : Text(
                                      _svc.error ?? 'Produk tidak ditemukan',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.black,
                                      ),
                                    ),
                            )
                          : ScrollConfiguration(
                              behavior: ScrollConfiguration.of(context)
                                  .copyWith(overscroll: false),
                              child: Scrollbar(
                                thickness: 3,
                                radius: const Radius.circular(8),
                                child: ListView.separated(
                                  physics: const ClampingScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  itemCount: shown.length,
                                  separatorBuilder: (_, _) => const Divider(
                                    height: 1,
                                    indent: 14,
                                    endIndent: 14,
                                  ),
                                  itemBuilder: (_, i) => _Row(
                                    product: shown[i],
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailScreen(
                                          product: shown[i],
                                          canEdit: widget.canEdit,
                                        ),
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
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _Stat('All Product', all.length),
                          const SizedBox(height: 8),
                          _Stat(
                            'Near Expired',
                            all.where((p) => p.nearExpired).length,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [
                          _Stat('Available', all.length - outOf),
                          const SizedBox(height: 8),
                          _Stat('Out of Stock', outOf),
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
    },
  );
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: fg),
    ),
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
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: kTextMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${p.sku} · EXP. ${exp == null ? '-' : fmtDate(exp)}',
                    style: const TextStyle(fontSize: 11, color: kTextMuted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 72,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    out ? 'Out of stock' : '${p.stock} ${p.unit}',
                    style: TextStyle(
                      fontSize: out ? 10 : 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fmtRp(p.price),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
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
        width: 32,
        height: 22,
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
