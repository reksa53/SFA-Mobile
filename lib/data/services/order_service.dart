import 'package:dio/dio.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import 'api_client.dart';

class OrderSummaryCount {
  const OrderSummaryCount({required this.all, required this.pending, required this.accepted, required this.rejected});
  static const zero = OrderSummaryCount(all: 0, pending: 0, accepted: 0, rejected: 0);
  final int all, pending, accepted, rejected;
}

class OrderResult {
  const OrderResult(this.orders, this.summary);
  final List<Order> orders;
  final OrderSummaryCount summary;
}

class OrderService {
  final _dio = ApiClient.instance.dio;

  Future<OrderResult> fetch({String? status, String? period, String? search, int? customerId, int? perPage}) async {
    final res = await _dio.get('/orders', queryParameters: {
      'status': ?status,
      'period': ?period,
      if (search != null && search.isNotEmpty) 'search': search,
      'customer_id': ?customerId,
      'per_page': ?perPage,
    });
    final body = res.data as Map<String, dynamic>;
    final orders = [for (final e in body['data'] as List) Order.fromJson(e as Map<String, dynamic>)];
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
  Future<void> accept(int orderId) => _dio.post('/orders/$orderId/accept');
  Future<void> reject(int orderId, String reason) => _dio.post('/orders/$orderId/reject', data: {'reason': reason});

  static String errorMessage(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    final message = switch (data) {
      {'message': String m} => m,
      _ => null,
    };
    if (status == 422) {
      if (message != null) return message;
      final errors = data is Map ? data['errors'] : null;
      final first = errors is Map && errors.isNotEmpty ? errors.values.first : null;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
    return switch (status) {
      401 => 'Sesi habis, silakan login ulang',
      403 => 'Kamu tidak punya akses',
      404 => 'Order tidak ditemukan',
      409 => message ?? 'Order sudah diproses',
      null => 'Tidak bisa terhubung ke server',
      _ => 'Server error ($status)',
    };
  }
}