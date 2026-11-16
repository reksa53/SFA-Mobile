import 'package:flutter/material.dart';
import 'package:sfa_mobile/data/models/order_item.dart';
import 'package:sfa_mobile/data/repositories/order_repository.dart';
import 'package:sfa_mobile/ui/core/theme/app_colors.dart';
import 'package:sfa_mobile/ui/core/theme/app_text_styles.dart';
import 'package:sfa_mobile/ui/sales/order/widgets/cart_product_tile.dart';
import 'package:sfa_mobile/utils/rupiah.dart';

class OrderCartScreen extends StatefulWidget {
  const OrderCartScreen({super.key, required this.store});

  final StoreOption store;

  @override
  State<OrderCartScreen> createState() => _OrderCartScreenState();
}

class _OrderCartScreenState extends State<OrderCartScreen> {
  final _catalog = OrderRepository.instance.catalog();
  final _qty = <String, int>{}; // nama produk -> jumlah (hanya yang > 0)
  String _query = '';
  bool _onlySelected = false;

  int _qtyOf(CatalogItem c) => _qty[c.product.name] ?? 0;

  int get _total => _catalog.fold(0, (sum, c) => sum + c.price * _qtyOf(c));

  void _setQty(CatalogItem c, int value) {
    setState(() {
      if (value <= 0) {
        _qty.remove(c.product.name);
        if (_qty.isEmpty) _onlySelected = false;
      } else {
        _qty[c.product.name] = value;
      }
    });
  }

  void _submit() {
    final items = [
      for (final c in _catalog)
        if (_qtyOf(c) > 0)
          OrderItem(
            productName: c.product.name,
            unitPrice: c.price,
            quantity: _qtyOf(c),
          ),
    ];
    final order = OrderRepository.instance.submit(
      storeName: widget.store.name,
      salesId: OrderRepository.currentSalesId,
      items: items,
    );
    Navigator.of(context).pop(order);
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buang order ini?'),
        content: const Text('Produk yang sudah dipilih tidak akan disimpan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Lanjut pilih'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Buang'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.toLowerCase();
    final visible = _catalog.where((c) {
      final matches = c.product.name.toLowerCase().contains(query);
      return matches && (!_onlySelected || _qtyOf(c) > 0);
    }).toList();

    final searchBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.grey),
    );

    return PopScope(
      canPop: _qty.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.storefront_outlined,
                          color: AppColors.black),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.store.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle
                            .copyWith(fontSize: 22, color: AppColors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        style: AppTextStyles.cardBody.copyWith(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Cari produk',
                          prefixIcon:
                              const Icon(Icons.search, color: AppColors.black),
                          filled: true,
                          fillColor: AppColors.white,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                          border: searchBorder,
                          enabledBorder: searchBorder,
                          focusedBorder: searchBorder,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _CartButton(
                      count: _qty.length,
                      active: _onlySelected,
                      onTap: _qty.isEmpty
                          ? null
                          : () => setState(() => _onlySelected = !_onlySelected),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: visible.isEmpty
                      ? Center(
                          child: Text(
                            'Produk tidak ditemukan',
                            style: AppTextStyles.cardBody.copyWith(
                              fontSize: 14,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: visible.length,
                          separatorBuilder: (_, _) => const Divider(
                              height: 1, color: Color(0xFFEDEDED)),
                          itemBuilder: (_, i) {
                            final c = visible[i];
                            return CartProductTile(
                              item: c,
                              quantity: _qtyOf(c),
                              onChanged: (v) => _setQty(c, v),
                            );
                          },
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 110,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.black,
                            minimumSize: const Size(0, 48),
                            side: const BorderSide(color: Color(0xFF9B9B9B)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text('Back',
                              style: AppTextStyles.button.copyWith(fontSize: 15)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: _total > 0 ? _submit : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.red,
                            foregroundColor: AppColors.white,
                            disabledBackgroundColor: AppColors.grey,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text('Order ${formatRupiah(_total)}',
                              style: AppTextStyles.button.copyWith(fontSize: 15)),
                        ),
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

class _CartButton extends StatelessWidget {
  const _CartButton({
    required this.count,
    required this.active,
    required this.onTap,
  });

  final int count;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                active ? Icons.shopping_cart : Icons.shopping_cart_outlined,
                color: active ? AppColors.red : AppColors.black,
              ),
            ),
          ),
        ),
        if (count > 0)
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: AppColors.red,
                shape: BoxShape.circle,
              ),
              child: Text('$count',
                  style: AppTextStyles.navLabel
                      .copyWith(color: AppColors.white)),
            ),
          ),
      ],
    );
  }
}