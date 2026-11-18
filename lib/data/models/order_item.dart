class OrderItem {
  const OrderItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  final int productId;
  final String productName;
  final int unitPrice;
  final int quantity;

  int get subtotal => unitPrice * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        productId: j['product_id'] as int,
        productName: (j['product_name'] ?? '').toString(),
        unitPrice: j['unit_price'] as int,
        quantity: j['quantity'] as int,
      );

  Map<String, dynamic> toJson() => {'product_id': productId, 'quantity': quantity};
}