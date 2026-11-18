import 'package:sfa_mobile/data/models/order_item.dart';

enum OrderStatus { pending, accepted, rejected }

OrderStatus _parseStatus(String s) => switch (s) {
      'accepted' => OrderStatus.accepted,
      'rejected' => OrderStatus.rejected,
      _ => OrderStatus.pending,
    };

class Order {
  const Order({
    this.id,
    required this.storeName,
    required this.status,
    this.invoice,
    this.salesId,
    this.customerId,
    this.items = const [],
  }) : assert(
          (status == OrderStatus.accepted) == (invoice != null),
          'Invoice harus ada tepat pada order accepted',
        );

  final int? id;
  final String storeName;
  final String? invoice; // null selama masih pending
  final OrderStatus status;
  final int? salesId;
  final int? customerId;
  final List<OrderItem> items;

  int get total => items.fold(0, (sum, i) => sum + i.subtotal);

  factory Order.fromJson(Map<String, dynamic> j) {
    final customer = j['customer'] as Map<String, dynamic>?;
    final sales = j['sales'] as Map<String, dynamic>?;
    return Order(
      id: j['id'] as int?,
      storeName: (customer?['name'] ?? '').toString(),
      customerId: customer?['id'] as int?,
      salesId: sales?['id'] as int?,
      status: _parseStatus(j['status'] as String? ?? 'pending'),
      invoice: j['order_number'] as String?,
      items: (j['items'] as List? ?? [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}