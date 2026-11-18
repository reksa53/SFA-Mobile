import 'package:flutter/foundation.dart';

import '../models/product.dart';
import 'api_client.dart';

class ProductService extends ChangeNotifier {
  ProductService._();
  static final instance = ProductService._();

  List<Product> _items = [];
  bool loading = false;
  String? error;

  List<Product> get active => _items.where((p) => p.isActive).toList();

  List<String> get brands => _distinct(active.map((p) => p.brand));
  List<String> get categories => _distinct(active.map((p) => p.category));

  List<String> categoriesFor(Iterable<String> brands) => brands.isEmpty
      ? categories
      : _distinct(active.where((p) => brands.contains(p.brand)).map((p) => p.category));

  // shortcut: ambil semua halaman sekaligus, cukup untuk ratusan produk; ganti ke infinite scroll bila ribuan
  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final items = <Product>[];
      var page = 1;
      int last;
      do {
        final res = await ApiClient.instance.dio.get('/products', queryParameters: {'page': page});
        items.addAll((res.data['data'] as List).map((j) => Product.fromJson(j)));
        last = res.data['meta']['last_page'];
      } while (page++ < last);
      _items = items;
    } catch (_) {
      error = 'Gagal memuat produk';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // detail lengkap dengan batch (urut FEFO dari backend)
  Future<Product> fetch(int id) async {
    final res = await ApiClient.instance.dio.get('/products/$id');
    return Product.fromJson(res.data['data']);
  }

  // Masih lokal sampai product_form_screen / product_detail_screen disambung ke API.
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