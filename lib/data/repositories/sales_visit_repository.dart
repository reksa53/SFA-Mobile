import 'dart:math' as math;

import 'package:dio/dio.dart';

import '../services/api_client.dart';
import '../models/sales.dart';
import '../models/visit.dart';

abstract class SalesVisitRepository {
  Future<List<Sales>> getSales();
  Future<List<Visit>> getVisits(int salesId);

  /// Kunjungan milik Sales yang sedang login (dipakai layar Sales).
  Future<List<Visit>> getMyVisits();

  /// Sales melaporkan hasil kunjungan: status visited / notVisited + catatan.
  Future<Visit> reportVisit(Visit visit, VisitStatus status, String catatan);
}

/// Data sementara. Dipakai selama endpoint Laravel belum siap. Untuk pindah ke
/// API, ganti default `repository` di SalesVisitScreen menjadi
/// ApiSalesVisitRepository().
///
/// Kunjungan dibuat otomatis di sekitar tanggal hari ini (dan berbeda untuk
/// tiap sales), jadi kalender dan ringkasan bulan ini selalu ada isinya.
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
    // Sales yang baru ditambahkan dari layar Add Sales belum punya kunjungan.
    if (!_sales.any((s) => s.id == salesId)) return [];
    return _bangkitkan(salesId);
  }

  // Sales yang login sementara = Icha Clowy (id 1).
  static const _meId = 1;

  // Hasil laporan disimpan di sini agar tidak hilang saat pindah tab.
  static final Map<int, Visit> _laporan = {};

  @override
  Future<List<Visit>> getMyVisits() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _bangkitkan(_meId).map((v) => _laporan[v.id] ?? v).toList();
  }

  @override
  Future<Visit> reportVisit(
      Visit visit, VisitStatus status, String catatan) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final baru = visit.copyWith(status: status, catatan: catatan);
    _laporan[visit.id] = baru;
    return baru;
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

  static const _toko = [
    'TOKO AKBAR AMIRUL',
    'TOKO PURNAMA ABADI SENTOSA',
    'TOKO JAYA AGUNG MANDIRI',
    'TOKO KEMBALI DJAYA',
    'TOKO SINAR JAYA',
    'TOKO MAKMUR SENTOSA',
    'TOKO BERKAH ABADI',
  ];

  static List<Visit> _bangkitkan(int salesId) {
    final r = math.Random(salesId * 7919 + 13); // hasil sama tiap dibuka
    final now = DateTime.now();
    final hariIni = DateTime(now.year, now.month, now.day);
    final jumlah = 8 + r.nextInt(6);
    final hasil = <Visit>[];

    for (var i = 0; i < jumlah; i++) {
      // Sales bernomor genap punya satu kunjungan hari ini.
      final geser = (i == 0 && salesId.isEven) ? 0 : r.nextInt(46) - 25;
      final tanggal =
          DateTime(hariIni.year, hariIni.month, hariIni.day + geser);
      // Jadwal lampau: sebagian besar sudah dikunjungi, sebagian tidak jadi,
      // dan sedikit yang dibiarkan scheduled (tampil sebagai "Terlewat").
      // Hari ini dan ke depan: scheduled (tampil sebagai "Pending").
      final VisitStatus status;
      if (tanggal.isBefore(hariIni)) {
        final x = r.nextInt(10);
        status = x < 7
            ? VisitStatus.visited
            : (x < 9 ? VisitStatus.notVisited : VisitStatus.scheduled);
      } else {
        status = VisitStatus.scheduled;
      }
      hasil.add(
        Visit(
          id: salesId * 100 + i + 1,
          tokoNama: _toko[r.nextInt(_toko.length)],
          tanggal: tanggal,
          status: status,
        ),
      );
    }
    hasil.sort((a, b) => a.tanggal.compareTo(b.tanggal));
    return hasil;
  }
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

  /// ASUMSI: GET /api/my-visits  dan  PATCH /api/visits/{id}
  /// dengan body {status: visited|not_visited, notes: "..."}.
  @override
  Future<List<Visit>> getMyVisits() async {
    final res = await _dio.get('/my-visits');
    final list = res.data['data'] as List;
    return list
        .map((e) => Visit.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Visit> reportVisit(
      Visit visit, VisitStatus status, String catatan) async {
    await _dio.patch('/visits/${visit.id}', data: {
      'status': status == VisitStatus.visited ? 'visited' : 'not_visited',
      'notes': catatan,
    });
    return visit.copyWith(status: status, catatan: catatan);
  }
}
