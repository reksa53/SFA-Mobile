import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/customer_store.dart';
import '../models/customer_visit.dart';
import 'api_client.dart';

class CustomerService {
  final _dio = ApiClient.instance.dio;

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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

  /// Satu customer (GET /customers/{id}).
  Future<CustomerStore> fetchOne(int id) async {
    final res = await _dio.get('/customers/$id');
    return CustomerStore.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// Tambah customer (POST /customers, khusus manager).
  /// Kode customer dibuat otomatis oleh server.
  /// [salesId] dan [visitDay] boleh kosong (visitDay: 1 = Senin ... 5 = Jumat).
  Future<void> create({
    required String name,
    required String address,
    int? salesId,
    int? visitDay,
    String? ownerName,
    String? phone,
    String? notes,
    Uint8List? photoBytes,
  }) async {
    final form = FormData.fromMap({
      if (salesId != null) 'assigned_sales_id': salesId,
      if (visitDay != null) 'visit_day': visitDay,
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

  /// Ubah customer (POST /customers/{id}, khusus manager).
  /// Memakai POST karena request multipart. Field kosong mengosongkan data,
  /// termasuk [salesId] dan [visitDay] (dikirim sebagai string kosong).
  Future<void> update(
    int id, {
    required String name,
    required String address,
    int? salesId,
    int? visitDay,
    String? ownerName,
    String? phone,
    String? notes,
  }) async {
    final form = FormData.fromMap({
      'assigned_sales_id': salesId?.toString() ?? '',
      'visit_day': visitDay?.toString() ?? '',
      'name': name,
      'address': address,
      'owner_name': ownerName ?? '',
      'phone': phone ?? '',
      'notes': notes ?? '',
    });
    await _dio.post('/customers/$id', data: form);
  }

  // ───────────── Kunjungan ─────────────

  Future<List<CustomerVisit>> fetchVisits(int customerId) async {
    final res = await _dio.get('/customers/$customerId/visits');
    return (res.data['data'] as List)
        .map((e) => CustomerVisit.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createVisit({
    required int salesId,
    required int customerId,
    required DateTime date,
  }) async {
    await _dio.post(
      '/visits',
      data: {
        'sales_id': salesId,
        'customer_id': customerId,
        'visit_date': _ymd(date),
      },
    );
  }

  /// Ubah tanggal jadwal. [salesId] diisi hanya kalau sales-nya dipindah.
  Future<void> updateVisit(
    int id, {
    required int customerId,
    required DateTime date,
    int? salesId,
  }) async {
    await _dio.put(
      '/visits/$id',
      data: {
        'customer_id': customerId,
        'visit_date': _ymd(date),
        if (salesId != null) 'sales_id': salesId,
      },
    );
  }

  Future<void> deleteVisit(int id) async {
    await _dio.delete('/visits/$id');
  }

  /// Ambil pesan error dari response Laravel.
  static String errorMessage(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    if (status == 422 && data is Map) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    switch (status) {
      case 401:
        return 'Sesi habis, silakan login ulang';
      case 403:
        return 'Kamu tidak punya akses';
      case 404:
        return 'Data tidak ditemukan';
      case null:
        return 'Tidak bisa terhubung ke server';
      default:
        return 'Server error ($status)';
    }
  }
}
