import 'package:sfa_mobile/data/models/order_item.dart';

enum OrderStatus { pending, accepted, rejected }

class Order {
  const Order({
    required this.storeName,
    required this.status,
    this.invoice,
    this.salesId,
    this.items = const [],
  });

  final String storeName;
  final String? invoice; // null selama masih pending (belum ada invoice)
  final OrderStatus status;
  final String? salesId; // Sales yang menangani order ini
  final List<OrderItem> items;

  int get total => items.fold(0, (sum, i) => sum + i.subtotal);
}