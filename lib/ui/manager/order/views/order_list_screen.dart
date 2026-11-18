import 'package:flutter/material.dart';
import 'package:sfa_mobile/data/models/order.dart';
import 'package:sfa_mobile/ui/core/theme/app_colors.dart';
import 'package:sfa_mobile/ui/core/theme/app_text_styles.dart';
import 'package:sfa_mobile/ui/manager/order/widgets/order_filter_bar.dart';
import 'package:sfa_mobile/ui/manager/order/widgets/order_summary.dart';
import 'package:sfa_mobile/ui/manager/order/widgets/order_tile.dart';

// Data dummy sementara, ganti dengan data dari API nanti.
const _dummyOrders = [
  Order(storeName: 'TOKO JAYA TERBUKA ABADI', status: OrderStatus.rejected),
  Order(storeName: 'TOKO JAYA TERBUKA ABADI', status: OrderStatus.pending),
  Order(storeName: 'TOKO JAYA TERBUKA ABADI', invoice: 'KAJA0817968BHV', status: OrderStatus.accepted),
  Order(storeName: 'TOKO JAYA TERBUKA ABADI', status: OrderStatus.rejected),
  Order(storeName: 'TOKO JAYA TERBUKA ABADI', invoice: 'KAJA0817968BHV', status: OrderStatus.accepted),
  Order(storeName: 'TOKO JAYA TERBUKA ABADI', status: OrderStatus.pending),
  Order(storeName: 'TOKO JAYA TERBUKA ABADI', status: OrderStatus.pending),
  Order(storeName: 'TOKO JAYA TERBUKA ABADI', status: OrderStatus.pending),
  Order(storeName: 'TOKO JAYA TERBUKA ABADI', status: OrderStatus.rejected),
  Order(storeName: 'TOKO JAYA TERBUKA ABADI', invoice: 'KAJA0817968BHV', status: OrderStatus.accepted),
  Order(storeName: 'TOKO JAYA TERBUKA ABADI', status: OrderStatus.pending),
];
class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  int _period = 0;

  int _count(OrderStatus s) =>
      _dummyOrders.where((o) => o.status == s).length;

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
                Text('Order',
                    style: AppTextStyles.cardTitle
                        .copyWith(fontSize: 28, color: AppColors.white)),
                _SearchButton(onTap: () {}),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: OrderFilterBar(
              selected: _period,
              onSelected: (i) => setState(() => _period = i),
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
                itemCount: _dummyOrders.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: Color(0xFFEDEDED)),
                itemBuilder: (_, i) =>
                    OrderTile(number: i + 1, order: _dummyOrders[i]),
              ),
            ),
          ),
          const SizedBox(height: 14),
          OrderSummary(
            all: _dummyOrders.length,
            pending: _count(OrderStatus.pending),
            accepted: _count(OrderStatus.accepted),
            rejected: _count(OrderStatus.rejected),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  const _SearchButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.search, color: AppColors.black),
        ),
      ),
    );
  }
}