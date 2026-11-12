enum OrderStatus { pending, accepted, rejected }

class Order {
  const Order({required this.storeName, required this.status, this.invoice});

  final String storeName;
  final String? invoice; // null selama masih pending (belum ada invoice)
  final OrderStatus status;
}