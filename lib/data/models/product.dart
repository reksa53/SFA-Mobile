const kNearExpiredDays = 730; // shortcut: aturan tebakan, samakan dengan backend

DateTime today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

class ProductBatch {
  const ProductBatch({
    required this.number,
    this.expiry,
    required this.initialQty,
    required this.qty,
    required this.receivedAt,
  });

  final String number;
  final DateTime? expiry; // null = tanpa masa kedaluwarsa
  final int initialQty;
  final int qty; // sisa
  final DateTime receivedAt;

  bool get expired => expiry != null && expiry!.isBefore(today());

  bool get nearExpired =>
      expiry != null &&
      !expired &&
      expiry!.isBefore(today().add(const Duration(days: kNearExpiredDays)));
}

class Product {
  Product({
    this.id, 
    required this.sku,
    required this.name,
    this.brand,
    this.category,
    this.unit = 'pcs',
    required this.price,
    this.isActive = true,
    List<ProductBatch>? batches,
  }) : batches = batches ?? [];

  final int? id;
  final String sku;
  final String name;
  final String? brand;
  final String? category;
  final String unit;
  final int price; // Rupiah
  final bool isActive;
  final List<ProductBatch> batches;

  // urut FEFO: expired terdekat dulu, tanpa expired paling akhir
  List<ProductBatch> get fefo => [...batches]
    ..sort((a, b) {
      if (a.expiry == null && b.expiry == null) return 0;
      if (a.expiry == null) return 1;
      if (b.expiry == null) return -1;
      return a.expiry!.compareTo(b.expiry!);
    });

  // stok = jumlah sisa batch yang belum expired (tidak ada kolom stock)
  int get stock => batches.where((b) => !b.expired).fold(0, (s, b) => s + b.qty);

  DateTime? get nearestExpiry {
    final d = batches
        .where((b) => !b.expired && b.qty > 0 && b.expiry != null)
        .map((b) => b.expiry!);
    return d.isEmpty ? null : d.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  bool get nearExpired => batches.any((b) => b.qty > 0 && b.nearExpired);
}