import 'package:flutter/foundation.dart';

import '../models/product.dart';

// shortcut: data dummy di memori, ganti dengan panggilan API (ApiClient) saat backend siap
class ProductService extends ChangeNotifier {
  ProductService._();
  static final instance = ProductService._();

  final List<Product> _items = _seed();

  List<Product> get active => _items.where((p) => p.isActive).toList();

  List<String> get brands => _distinct(active.map((p) => p.brand));
  List<String> get categories => _distinct(active.map((p) => p.category));

  List<String> categoriesFor(Iterable<String> brands) => brands.isEmpty
      ? categories
      : _distinct(active.where((p) => brands.contains(p.brand)).map((p) => p.category));

  bool knowsBrand(String b) => brands.contains(b);

  bool skuExists(String sku) =>
      _items.any((p) => p.sku.toLowerCase() == sku.toLowerCase());

  // pakai ejaan yang sudah ada: "indomie" -> "Indomie"; kosong -> null
  String? canon(String? value, List<String> existing) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    return existing.firstWhere((e) => e.toLowerCase() == v.toLowerCase(), orElse: () => v);
  }

  void add(Product p) {
    _items.add(p);
    notifyListeners();
  }

  void addBatch(Product p, ProductBatch b) {
    p.batches.add(b);
    notifyListeners();
  }

  static List<String> _distinct(Iterable<String?> v) =>
      v.whereType<String>().toSet().toList()..sort();
}

ProductBatch _b(String n, String? exp, int init, int qty, String recv) => ProductBatch(
      number: n,
      expiry: exp == null ? null : DateTime.parse(exp),
      initialQty: init,
      qty: qty,
      receivedAt: DateTime.parse(recv),
    );

List<Product> _seed() => [
      Product(sku: 'IDM-001', name: 'Indomie Goreng', brand: 'Indomie', category: 'Mie Instan', unit: 'box', price: 115000, batches: [
        _b('B-2509', '2027-10-12', 100, 40, '2025-09-05'),
        _b('B-2603', '2030-05-28', 150, 125, '2026-03-10'),
        _b('B-2610', '2031-01-14', 100, 100, '2026-10-20'),
      ]),
      Product(sku: 'SSR-001', name: 'Teh Botol Sosro', brand: 'Sosro', category: 'Minuman', unit: 'box', price: 72000, batches: [_b('B-2602', '2030-02-07', 60, 0, '2026-02-01')]),
      Product(sku: 'BRS-005', name: 'Beras Premium 5 kg', category: 'Sembako', unit: 'sak', price: 68000, batches: [_b('B-2601', '2028-03-12', 40, 0, '2026-01-15')]),
      Product(sku: 'BML-002', name: 'Minyak Goreng Bimoli 2 L', brand: 'Bimoli', category: 'Sembako', unit: 'box', price: 215000, batches: [_b('B-2604', '2028-09-30', 80, 55, '2026-04-02')]),
      Product(sku: 'GLK-001', name: 'Gula Pasir Gulaku 1 kg', brand: 'Gulaku', category: 'Sembako', unit: 'box', price: 165000, batches: [_b('B-2605', '2029-06-18', 200, 155, '2026-05-06')]),
      Product(sku: 'BNG-600', name: 'Kecap Manis Bango 600 ml', brand: 'Bango', category: 'Bumbu', unit: 'box', price: 148000, batches: [_b('B-2606', '2028-02-05', 80, 63, '2026-05-20')]),
      Product(sku: 'RFN-500', name: 'Garam Dapur Refina 500 gr', brand: 'Refina', category: 'Bumbu', unit: 'box', price: 54000, batches: [_b('B-2607', '2030-04-14', 60, 46, '2026-06-03')]),
      Product(sku: 'KPA-165', name: 'Kopi Kapal Api 165 gr', brand: 'Kapal Api', category: 'Kopi', unit: 'box', price: 94000, batches: [_b('B-2608', '2028-07-09', 100, 89, '2026-06-18')]),
      Product(sku: 'FRF-001', name: 'Susu Kental Manis Frisian Flag', brand: 'Frisian Flag', category: 'Susu', unit: 'box', price: 290000, batches: [_b('B-2609', '2028-10-27', 50, 25, '2026-07-01')]),
      Product(sku: 'ULT-250', name: 'Ultra Milk Coklat 250 ml', brand: 'Ultra Milk', category: 'Susu', unit: 'box', price: 140000, batches: [_b('B-2611', '2027-12-03', 600, 570, '2026-07-15')]),
    ];