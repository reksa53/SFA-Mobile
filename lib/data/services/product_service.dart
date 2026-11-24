import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

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
      : _distinct(
          active.where((p) => brands.contains(p.brand)).map((p) => p.category),
        );

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
        final res = await ApiClient.instance.dio.get(
          '/products',
          queryParameters: {'page': page},
        );
        items.addAll(
          (res.data['data'] as List).map((j) => Product.fromJson(j)),
        );
        last = res.data['meta']['last_page'];
      } while (page++ < last);
      _items = items;
    } on DioException catch (e) {
      debugPrint('GET /products gagal: ${e.response?.statusCode} ${e.message}');
      error = e.response == null
          ? 'Tidak bisa terhubung ke server'
          : 'Gagal memuat produk (${e.response!.statusCode})';
    } catch (e) {
      debugPrint('Data produk gagal dibaca: $e');
      error = 'Gagal membaca data produk';
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

  bool knowsBrand(String b) => brands.contains(b);

  bool skuExists(String sku) =>
      _items.any((p) => p.sku.toLowerCase() == sku.toLowerCase());

  // pakai ejaan yang sudah ada: "indomie" -> "Indomie"; kosong -> null
  String? canon(String? value, List<String> existing) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    return existing.firstWhere(
      (e) => e.toLowerCase() == v.toLowerCase(),
      orElse: () => v,
    );
  }

  void add(Product p) {
    _items.add(p);
    notifyListeners();
  }

  // produk terbaru dari daftar, supaya layar detail ikut berubah
  Product current(Product p) =>
      _items.firstWhere((x) => x.id != null && x.id == p.id, orElse: () => p);

  // ambil detail (dengan batch) lalu simpan ke daftar
  Future<void> loadDetail(Product p) async {
    if (p.id == null) return;
    try {
      _replace(await fetch(p.id!));
    } catch (_) {} // gagal: tetap tampilkan data dari list
  }

  void _replace(Product fresh) {
    final i = _items.indexWhere((x) => x.id == fresh.id);
    if (i >= 0) _items[i] = fresh;
    notifyListeners();
  }

  // kirim ke server; balasannya produk lengkap (stok dan batch terbaru)
  Future<void> addBatch(Product p, ProductBatch b) async {
    if (p.id == null) {
      p.batches.add(b);
      notifyListeners();
      return;
    }
    final res = await ApiClient.instance.dio.post(
      '/products/${p.id}/batches',
      data: {
        'batch_number': b.number,
        'expiry_date': b.expiry?.toIso8601String().substring(0, 10),
        'quantity': b.initialQty,
        'received_at': b.receivedAt.toIso8601String().substring(0, 10),
      },
    );
    _replace(Product.fromJson(res.data['data']));
  }

  static List<String> _distinct(Iterable<String?> v) =>
      v.whereType<String>().toSet().toList()..sort();

  String _d(DateTime d) => d.toIso8601String().substring(0, 10);

  MediaType _imageMediaType(String path) {
    final ext = path.toLowerCase();
    if (ext.endsWith('.png')) return MediaType('image', 'png');
    if (ext.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg');
  }

  Future<void> create({
    required String sku,
    required String name,
    String? brand,
    String? category,
    required String unit,
    required int price,
    required bool active,
    required String batchNumber,
    DateTime? expiry,
    required int qty,
    required DateTime received,
    XFile? photo,
  }) async {
    final form = FormData.fromMap({
      'sku': sku,
      'name': name,
      if (brand != null) 'brand': brand,
      if (category != null) 'category': category,
      'unit': unit,
      'price': price,
      'is_active': active ? 1 : 0,
      'batch[batch_number]': batchNumber,
      if (expiry != null) 'batch[expiry_date]': _d(expiry),
      'batch[quantity]': qty,
      'batch[received_at]': _d(received),
      if (photo != null)
        'photo': await MultipartFile.fromFile(
          photo.path,
          filename: photo.name,
          contentType: _imageMediaType(photo.path),
        ),
    });
    final res = await ApiClient.instance.dio.post('/products', data: form);
    _items.add(Product.fromJson(res.data['data']));
    notifyListeners();
  }

  Future<void> delete(Product p) async {
    await ApiClient.instance.dio.delete('/products/${p.id}');
    _items.removeWhere((x) => x.id == p.id);
    notifyListeners();
  }

  // Laravel tidak membaca multipart lewat PUT, jadi POST dengan _method=PUT.
  // sku, name, price wajib karena aturan validasi update.
  Future<Product> updatePhoto(Product p, String path) async {
    try {
      debugPrint('UPLOAD START: id=${p.id}, path=$path');
      await ApiClient.instance.dio.post(
        '/products/${p.id}',
        data: FormData.fromMap({
          'sku': p.sku,
          'name': p.name,
          if (p.brand != null) 'brand': p.brand,
          if (p.category != null) 'category': p.category,
          'unit': p.unit,
          'price': p.price,
          'is_active': p.isActive ? 1 : 0,
          'photo': await MultipartFile.fromFile(
            path,
            filename: path.split('/').last,
            contentType: _imageMediaType(path),
          ),
        }),
      );
      final res = await ApiClient.instance.dio.get('/products/${p.id}');
      final full = Product.fromJson(res.data['data']);
      final i = _items.indexWhere((x) => x.id == p.id);
      if (i >= 0) _items[i] = full;
      notifyListeners();
      return full;
    } on DioException catch (e) {
      debugPrint('UPDATE PHOTO DIO ERROR: ${e.response?.statusCode} -> ${e.response?.data}');
      rethrow;
    } catch (e, s) {
      debugPrint('UPDATE PHOTO OTHER ERROR: $e\n$s');
      rethrow;
    }
  }
}