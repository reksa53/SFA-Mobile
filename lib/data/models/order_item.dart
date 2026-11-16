class OrderItem {
  const OrderItem({
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  final String productName;
  final int unitPrice; // rupiah, integer
  final int quantity;

  int get subtotal => unitPrice * quantity;
}