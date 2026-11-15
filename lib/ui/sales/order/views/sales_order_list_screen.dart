import 'package:flutter/material.dart';
import 'package:sfa_mobile/data/models/order.dart';
import 'package:sfa_mobile/data/repositories/order_repository.dart';
import 'package:sfa_mobile/ui/core/theme/app_colors.dart';
import 'package:sfa_mobile/ui/core/theme/app_text_styles.dart';
import 'package:sfa_mobile/ui/core/widgets/search_icon_button.dart';
import 'package:sfa_mobile/ui/manager/order/widgets/order_summary.dart';
import 'package:sfa_mobile/ui/manager/order/widgets/order_tile.dart';
import 'package:sfa_mobile/ui/sales/order/views/order_cart_screen.dart';
import 'package:sfa_mobile/ui/sales/order/widgets/store_picker_dialog.dart';

class SalesOrderListScreen extends StatefulWidget {
  const SalesOrderListScreen({super.key});

  @override
  State<SalesOrderListScreen> createState() => _SalesOrderListScreenState();
}

class _SalesOrderListScreenState extends State<SalesOrderListScreen> {
  final _repo = OrderRepository.instance;
  late List<Order> _orders;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() =>
      _orders = _repo.ordersForSales(OrderRepository.currentSalesId);

  int _count(OrderStatus s) => _orders.where((o) => o.status == s).length;

  Future<void> _addOrder() async {
    final stores = _repo.storesForSales(OrderRepository.currentSalesId);
    final store = await showStorePicker(context, stores);
    if (store == null || !mounted) return;

    final created = await Navigator.of(context).push<Order>(
      MaterialPageRoute(builder: (_) => OrderCartScreen(store: store)),
    );
    if (created == null || !mounted) return;

    setState(_load);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Order terkirim')));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sales Order',
                    style: AppTextStyles.cardTitle
                        .copyWith(fontSize: 28, color: AppColors.white)),
                SearchIconButton(onTap: () {}),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                OrderStat(label: 'Semua order', value: _orders.length),
                const Spacer(),
                InkWell(
                  onTap: () {}, // TODO: filter status
                  child: Row(
                    children: [
                      const Icon(Icons.tune, size: 18, color: AppColors.white),
                      const SizedBox(width: 6),
                      Text('Status',
                          style: AppTextStyles.navLabel.copyWith(
                            fontSize: 13,
                            color: AppColors.white,
                          )),
                    ],
                  ),
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
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _orders.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: Color(0xFFEDEDED)),
                itemBuilder: (_, i) =>
                    OrderTile(number: i + 1, order: _orders[i]),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  children: [
                    OrderStat(label: 'Semua order', value: _orders.length),
                    const SizedBox(height: 8),
                    OrderStat(
                        label: 'disetujui',
                        value: _count(OrderStatus.accepted)),
                  ],
                ),
                FilledButton(
                  onPressed: _addOrder,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Add Order',
                      style: AppTextStyles.navLabel
                          .copyWith(fontSize: 14, color: AppColors.red)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}