import 'package:dio/dio.dart';

import '../services/api_client.dart';
import '../models/sales.dart';
import '../models/visit.dart';

abstract class SalesVisitRepository {
  Future<List<Sales>> getSales();
  Future<List<Visit>> getVisits(int salesId);
}

/// Data sementara (isi dari frame Figma). Dipakai selama endpoint Laravel
/// belum siap. Untuk pindah ke API, ganti default `repository` di
/// SalesVisitScreen menjadi ApiSalesVisitRepository().
class DummySalesVisitRepository implements SalesVisitRepository {
  const DummySalesVisitRepository();

  @override
  Future<List<Sales>> getSales() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _sales;
  }

  @override
  Future<List<Visit>> getVisits(int salesId) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _visits; // data dummy sama untuk semua sales
  }

  static const _sales = [
    Sales(id: 1, nama: 'Icha Clowy'),
    Sales(id: 2, nama: 'Bagus Subekti'),
    Sales(id: 3, nama: 'Nanang Jajargenjang'),
    Sales(id: 4, nama: 'Agus Prikitiw'),
    Sales(id: 5, nama: 'Dadang Berdendang'),
    Sales(id: 6, nama: 'Jajang Kejang Kejang'),
    Sales(id: 7, nama: 'Nanda Srintil'),
    Sales(id: 8, nama: 'Sulastri Ayu'),
    Sales(id: 9, nama: 'Heru Semeru'),
  ];

  static final _visits = [
    Visit(id: 1, tokoNama: 'TOKO AKBAR AMIRUL', tanggal: DateTime(2026, 10, 23), status: VisitStatus.done),
    Visit(id: 2, tokoNama: 'TOKO AKBAR AMIRUL', tanggal: DateTime(2026, 10, 23), status: VisitStatus.done),
    Visit(id: 3, tokoNama: 'TOKO AKBAR AMIRUL', tanggal: DateTime(2026, 10, 23), status: VisitStatus.process),
    Visit(id: 4, tokoNama: 'TOKO AKBAR AMIRUL', tanggal: DateTime(2026, 10, 23), status: VisitStatus.done),
    Visit(id: 5, tokoNama: 'TOKO PURNAMA ABADI SENTOSA', tanggal: DateTime(2026, 11, 3), status: VisitStatus.done),
    Visit(id: 6, tokoNama: 'TOKO JAYA AGUNG MANDIRI', tanggal: DateTime(2026, 11, 5), status: VisitStatus.process),
    Visit(id: 7, tokoNama: 'TOKO KEMBALI DJAYA', tanggal: DateTime(2026, 11, 12), status: VisitStatus.pending),
  ];
}

/// Implementasi ke Laravel.
///
/// ASUMSI endpoint (belum dicocokkan dengan repo backend):
///   GET /api/sales                -> {"data": [ {id, name, photo}, ... ]}
///   GET /api/sales/{id}/visits    -> {"data": [ {id, store_name, visit_date, status}, ... ]}
/// Ubah path dan bentuk response di sini kalau di backend berbeda.
class ApiSalesVisitRepository implements SalesVisitRepository {
  ApiSalesVisitRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  @override
  Future<List<Sales>> getSales() async {
    final res = await _dio.get('/sales');
    final list = res.data['data'] as List;
    return list
        .map((e) => Sales.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Visit>> getVisits(int salesId) async {
    final res = await _dio.get('/sales/$salesId/visits');
    final list = res.data['data'] as List;
    return list
        .map((e) => Visit.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
