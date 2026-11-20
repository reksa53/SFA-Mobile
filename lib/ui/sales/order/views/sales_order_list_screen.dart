import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sfa_mobile/data/models/customer_store.dart';
import 'package:sfa_mobile/data/models/order.dart';
import 'package:sfa_mobile/data/services/customer_service.dart';
import 'package:sfa_mobile/data/services/order_service.dart';
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
  final _orderService = OrderService();
  final _customerService = CustomerService();
  bool _loading = true;
  String? _error;
  List<Order> _orders = const [];
   OrderSummaryCount _summary = OrderSummaryCount.zero;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _orderService.fetch();
      if (!mounted) return;
      setState(() {
        _orders = result.orders;
        _summary = result.summary;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(()  {
        _error = OrderService.errorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _addOrder() async {
    List<CustomerStore> stores;
    try {
      stores = await _customerService.fetchAll();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(CustomerService.errorMessage(e))));
      }
      return;
    }
    if (!mounted) return;

    final store = await showStorePicker(context, stores);
    if (store == null || store.id == null || !mounted) return;

    final created = await Navigator.of(context).push<Order>(
      MaterialPageRoute(builder: (_) => OrderCartScreen(store: store)),
    );
    if (created == null || !mounted) return;

    _load();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order terkirim')));
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
                Text('Sales Order', style: AppTextStyles.cardTitle.copyWith(fontSize: 28, color: AppColors.white)),
                SearchIconButton(onTap: () {}),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.white))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, style: const TextStyle(color: AppColors.white)),
                            const SizedBox(height: 8),
                            TextButton(onPressed: _load, child: const Text('Coba lagi')),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(24)),
                              clipBehavior: Clip.antiAlias,
                              child: ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: _orders.length,
                                separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFEDEDED)),
                                itemBuilder: (_, i) => OrderTile(number: i + 1, order: _orders[i]),
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
                                    OrderStat(label: 'Semua order', value: _summary.all),
                                    const SizedBox(height: 8),
                                    OrderStat(label: 'disetujui', value: _summary.accepted),
                                  ],
                                ),
                                FilledButton(
                                  onPressed: _addOrder,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: Text('Add Order',
                                      style: AppTextStyles.navLabel.copyWith(fontSize: 14, color: AppColors.red)),
                                ),
                              ],
                            ),
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