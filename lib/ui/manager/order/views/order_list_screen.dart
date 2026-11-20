import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sfa_mobile/data/models/order.dart';
import 'package:sfa_mobile/data/services/order_service.dart';
import 'package:sfa_mobile/ui/core/theme/app_colors.dart';
import 'package:sfa_mobile/ui/core/theme/app_text_styles.dart';
import 'package:sfa_mobile/ui/core/widgets/search_icon_button.dart';
import 'package:sfa_mobile/ui/manager/order/widgets/order_detail_sheet.dart';
import 'package:sfa_mobile/ui/manager/order/widgets/order_filter_bar.dart';
import 'package:sfa_mobile/ui/manager/order/widgets/order_summary.dart';
import 'package:sfa_mobile/ui/manager/order/widgets/order_tile.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  static const _white = TextStyle(color: AppColors.white);
  final _service = OrderService();
  List<Order> _orders = const [];
  OrderSummaryCount _summary = OrderSummaryCount.zero;
  bool _loading = true;
  String? _error;
  String? _period; // kunci periode di OrderFilterBar, null = semua waktu
  OrderStatus? _status; // null = semua status

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
    OrderResult? result;
    String? error;
    try {
      result = await _service.fetch(period: _period, status: _status?.name);
    } on DioException catch (e) {
      error = OrderService.errorMessage(e);
    } catch (e) {
      debugPrint('$e');
      error = 'Data order tidak terbaca';
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
      _orders = result?.orders ?? _orders;
      _summary = result?.summary ?? _summary;
    });
  }

  void _setFilter(VoidCallback change) {
    change();
    _load();
  }

  /// Mengembalikan pesan error, atau null kalau berhasil.
  Future<String?> _review(Future<void> Function() action) async {
    try {
      await action();
      _load();
      return null;
    } on DioException catch (e) {
      return OrderService.errorMessage(e);
    }
  }

  void _pickStatus() => showModalBottomSheet(
        context: context,
        builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
          for (final s in [null, ...OrderStatus.values])
            ListTile(
              title: Text(s?.label ?? 'Semua'),
              selected: s == _status,
              onTap: () {
                Navigator.pop(ctx);
                _setFilter(() => _status = s);
              },
            ),
        ]),
      );

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.white));
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, style: _white),
          TextButton(onPressed: _load, child: const Text('Coba lagi')),
        ]),
      );
    }
    if (_orders.isEmpty) return const Center(child: Text('Belum ada order', style: _white));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: _orders.length,
          separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFEDEDED)),
          itemBuilder: (_, i) {
            final o = _orders[i];
            return InkWell(
              onTap: () => showOrderDetail(
                context,
                o,
                onAccept: () => _review(() => _service.accept(o.id!)),
                onReject: (reason) => _review(() => _service.reject(o.id!, reason)),
              ),
              child: OrderTile(number: i + 1, order: o, showSales: true),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order', style: AppTextStyles.cardTitle.copyWith(fontSize: 28, color: AppColors.white)),
                SearchIconButton(onTap: () {}),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: OrderFilterBar(
              selected: _period,
              onSelected: (p) => _setFilter(() => _period = _period == p ? null : p),
              onStatusTap: _pickStatus,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: _body()),
          const SizedBox(height: 14),
          OrderSummary(
            all: _summary.all,
            pending: _summary.pending,
            accepted: _summary.accepted,
            rejected: _summary.rejected,
          ),
          const SizedBox(height: 12),
        ]),
      );
}