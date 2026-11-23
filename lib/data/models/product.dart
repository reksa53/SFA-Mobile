const kNearExpiredDays = 730; // shortcut: aturan tebakan, samakan dengan NEAR_EXPIRED_DAYS di ProductController

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

  factory ProductBatch.fromJson(Map<String, dynamic> j) => ProductBatch(
        number: j['batch_number'],
        expiry: j['expiry_date'] == null ? null : DateTime.parse(j['expiry_date']),
        initialQty: j['initial_quantity'],
        qty: j['quantity'],
        receivedAt: DateTime.parse(j['received_at']),
      );

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
    this.photoUrl, 
    int? stock,
    DateTime? nearestExpiry,
    List<ProductBatch>? batches,
  })  : _stock = stock,
        _nearestExpiry = nearestExpiry,
        batches = batches ?? [];

  // List dari API tidak membawa batch, hanya stock + nearest_expiry. Batch terisi lewat GET /products/{id}.
  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'],
        sku: j['sku'],
        name: j['name'],
        brand: j['brand'],
        category: j['category'],
        photoUrl: j['photo_url'],
        unit: j['unit'] ?? 'pcs',
        price: (j['price'] as num).toInt(),
        isActive: j['is_active'] ?? true,
        stock: j['stock'],
        nearestExpiry: j['nearest_expiry'] == null ? null : DateTime.parse(j['nearest_expiry']),
        batches: (j['batches'] as List? ?? [])
            .map((b) => ProductBatch.fromJson(b))
            .toList(),
      );

  final int? id;
  final String sku;
  final String name;
  final String? brand;
  final String? category;
  final String unit;
  final int price; // Rupiah
  final bool isActive;
  final String? photoUrl; 
  final List<ProductBatch> batches;
  final int? _stock;
  final DateTime? _nearestExpiry;

  // urut FEFO: expired terdekat dulu, tanpa expired paling akhir
  List<ProductBatch> get fefo => [...batches]
    ..sort((a, b) {
      if (a.expiry == null && b.expiry == null) return 0;
      if (a.expiry == null) return 1;
      if (b.expiry == null) return -1;
      return a.expiry!.compareTo(b.expiry!);
    });

  // dari backend bila ada; kalau tidak, jumlah sisa batch yang belum expired
  int get stock =>
      _stock ?? batches.where((b) => !b.expired).fold(0, (s, b) => s + b.qty);

  DateTime? get nearestExpiry {
    if (_nearestExpiry != null) return _nearestExpiry;
    final d = batches
        .where((b) => !b.expired && b.qty > 0 && b.expiry != null)
        .map((b) => b.expiry!);
    return d.isEmpty ? null : d.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  bool get nearExpired {
    final d = nearestExpiry;
    return d != null && d.isBefore(today().add(const Duration(days: kNearExpiredDays)));
  }
}