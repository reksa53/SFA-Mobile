import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/customer_store.dart';
import 'api_client.dart';

class CustomerService {
  final _dio = ApiClient.instance.dio;

  /// Ambil semua customer (menelusuri seluruh halaman paginasi).
  Future<List<CustomerStore>> fetchAll() async {
    final result = <CustomerStore>[];
    var page = 1;
    var lastPage = 1;
    do {
      final res = await _dio.get('/customers', queryParameters: {'page': page});
      final body = res.data as Map<String, dynamic>;
      result.addAll(
        (body['data'] as List).map(
          (e) => CustomerStore.fromJson(e as Map<String, dynamic>),
        ),
      );
      lastPage = ((body['meta'] as Map?)?['last_page'] as int?) ?? 1;
      page++;
    } while (page <= lastPage);
    return result;
  }

  /// Tambah customer (POST /customers, khusus manager).
  /// Kode customer dibuat otomatis oleh server.
  Future<void> create({
    required int salesId,
    required String name,
    required String address,
    String? ownerName,
    String? phone,
    String? notes,
    Uint8List? photoBytes,
  }) async {
    final form = FormData.fromMap({
      'assigned_sales_id': salesId,
      'name': name,
      'address': address,
      if (ownerName != null && ownerName.isNotEmpty) 'owner_name': ownerName,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (photoBytes != null)
        'photo': MultipartFile.fromBytes(photoBytes, filename: 'photo.jpg'),
    });
    await _dio.post('/customers', data: form);
  }

  /// Ambil pesan error pertama dari response 422 Laravel.
  static String errorMessage(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    if (status == 422 && data is Map && data['errors'] is Map) {
      final first = (data['errors'] as Map).values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
    switch (status) {
      case 401:
        return 'Sesi habis, silakan login ulang';
      case 403:
        return 'Kamu tidak punya akses';
      case null:
        return 'Tidak bisa terhubung ke server';
      default:
        return 'Server error ($status)';
    }
  }
}
