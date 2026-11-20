import 'package:sfa_mobile/data/models/order_item.dart';

enum OrderStatus {
  pending('Pending'),
  accepted('Accepted'),
  rejected('Rejected');

  const OrderStatus(this.label);
  final String label;
}

class Order {
  const Order({
    this.id,
    required this.storeName,
    required this.status,
    this.invoice,
    this.salesId,
    this.salesName,
    this.customerId,
    this.createdAt,
    this.items = const [],
  }) : assert(
          (status == OrderStatus.accepted) == (invoice != null),
          'Invoice harus ada tepat pada order accepted',
        );

  final int? id;
  final String storeName;
  final String? invoice;
  final OrderStatus status;
  final int? salesId;
  final String? salesName;
  final int? customerId;
  final DateTime? createdAt;
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
      salesName: sales?['name'] as String?,
      status: OrderStatus.values.asNameMap()[j['status']] ?? OrderStatus.pending,
      invoice: j['order_number'] as String?,
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? '')?.toLocal(),
      items: [for (final e in j['items'] as List? ?? []) OrderItem.fromJson(e as Map<String, dynamic>)],
    );
  }
}