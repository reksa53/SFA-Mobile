import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/sales.dart';
import 'api_client.dart';

class SalesService {
  final _dio = ApiClient.instance.dio;

  /// Daftar sales aktif dari server (GET /sales, khusus manager).
  Future<List<Sales>> fetchAll() async {
    final res = await _dio.get('/sales');
    final list = res.data['data'] as List;
    return list
        .map(
          (e) => Sales(
            id: e['id'] as int,
            nama: e['name'] as String,
            fotoUrl: e['photo_url'] as String?,
          ),
        )
        .toList();
  }

  /// Tambah sales baru (POST /sales, khusus manager).
  Future<Sales> create({
    required String name,
    required String email,
    required String phone,
    required String password,
    Uint8List? photoBytes,
  }) async {
    final form = FormData.fromMap({
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      if (photoBytes != null)
        'photo': MultipartFile.fromBytes(photoBytes, filename: 'photo.jpg'),
    });

    final res = await _dio.post('/sales', data: form);
    final data = res.data['data'];

    return Sales(
      id: data['id'] as int,
      nama: data['name'] as String,
      fotoBytes: photoBytes,
    );
  }

  /// Ganti atau hapus foto sales (POST /sales/{id}/photo, khusus manager).
  /// Mengembalikan alamat foto baru, atau null kalau fotonya dihapus.
  Future<String?> updatePhoto(
    int id, {
    Uint8List? bytes,
    bool remove = false,
  }) async {
    final form = FormData.fromMap({
      if (remove) 'remove': '1',
      if (bytes != null)
        'photo': MultipartFile.fromBytes(bytes, filename: 'photo.jpg'),
    });
    final res = await _dio.post('/sales/$id/photo', data: form);
    return res.data['data']['photo_url'] as String?;
  }

  /// Hapus (nonaktifkan) sales (DELETE /sales/{id}, khusus manager).
  Future<void> delete(int id) async {
    await _dio.delete('/sales/$id');
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
