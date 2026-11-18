import 'package:dio/dio.dart';

import '../models/order.dart';
import '../models/order_item.dart';
import 'api_client.dart';

class OrderSummaryCount {
  const OrderSummaryCount({required this.all, required this.pending, required this.accepted, required this.rejected});
  final int all, pending, accepted, rejected;
}

class OrderResult {
  const OrderResult(this.orders, this.summary);
  final List<Order> orders;
  final OrderSummaryCount summary;
}

class OrderService {
  final _dio = ApiClient.instance.dio;

  Future<OrderResult> fetch({String? status, String? period, String? search}) async {
    final res = await _dio.get('/orders', queryParameters: {
      if (status != null) 'status': status,
      if (period != null) 'period': period,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final body = res.data as Map<String, dynamic>;
    final orders = (body['data'] as List).map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    final s = body['summary'] as Map<String, dynamic>? ?? {};
    return OrderResult(
      orders,
      OrderSummaryCount(
        all: s['all'] as int? ?? orders.length,
        pending: s['pending'] as int? ?? 0,
        accepted: s['accepted'] as int? ?? 0,
        rejected: s['rejected'] as int? ?? 0,
      ),
    );
  }

  Future<Order> create({required int customerId, required List<OrderItem> items}) async {
    final res = await _dio.post('/orders', data: {
      'customer_id': customerId,
      'items': items.map((i) => i.toJson()).toList(),
    });
    return Order.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> cancel(int orderId) => _dio.delete('/orders/$orderId');

  static String errorMessage(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    if (status == 422 && data is Map && data['message'] is String) return data['message'] as String;
    if (status == 422 && data is Map && data['errors'] is Map) {
      final first = (data['errors'] as Map).values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
    switch (status) {
      case 401: return 'Sesi habis, silakan login ulang';
      case 403: return 'Kamu tidak punya akses';
      case 404: return 'Order tidak ditemukan';
      case 409: return (data is Map ? data['message'] as String? : null) ?? 'Order sudah diproses';
      case null: return 'Tidak bisa terhubung ke server';
      default: return 'Server error ($status)';
    }
  }
}