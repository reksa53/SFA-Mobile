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

  /// Daftar toko (customer) untuk dropdown di form Edit Visit.
  Future<List<TokoPilihan>> getTokoPilihan();

  /// Manager menyimpan jadwal satu sales: membandingkan [awal] dengan [baru],
  /// lalu menghapus / mengubah / menambah ke server. Mengembalikan daftar
  /// terbaru dari server.
  Future<List<Visit>> saveVisits(
    int salesId,
    List<Visit> awal,
    List<Visit> baru,
  );
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
    return _kunjunganSaya().map((v) => _laporan[v.id] ?? v).toList();
  }

  /// Kunjungan contoh untuk Sales yang login: selalu ada Done, Overdue,
  /// Pending, dan Not visited di sekitar hari ini (tanggal relatif).
  static List<Visit> _kunjunganSaya() {
    final now = DateTime.now();
    final hariIni = DateTime(now.year, now.month, now.day);
    Visit v(int id, int geser, String toko, VisitStatus st, [String cat = '']) =>
        Visit(
          id: 9000 + id,
          tokoNama: toko,
          tanggal: DateTime(hariIni.year, hariIni.month, hariIni.day + geser),
          status: st,
          catatan: cat,
        );
    return [
      v(1, -9, 'TOKO AKBAR AMIRUL', VisitStatus.visited,
          'Stok lengkap, order bulan depan.'),
      v(2, -7, 'TOKO SINAR JAYA', VisitStatus.visited),
      v(3, -6, 'TOKO KEMBALI DJAYA', VisitStatus.notVisited,
          'Toko tutup (libur keluarga).'),
      v(4, -4, 'TOKO MAKMUR SENTOSA', VisitStatus.visited,
          'Pemilik minta katalog baru.'),
      v(5, -2, 'TOKO BERKAH ABADI', VisitStatus.scheduled),
      v(6, 0, 'TOKO PURNAMA ABADI SENTOSA', VisitStatus.scheduled),
      v(7, 0, 'TOKO SINAR JAYA', VisitStatus.scheduled),
      v(8, 2, 'TOKO AKBAR AMIRUL', VisitStatus.scheduled),
      v(9, 5, 'TOKO BERKAH ABADI', VisitStatus.scheduled),
      v(10, 8, 'TOKO MAKMUR SENTOSA', VisitStatus.scheduled),
    ];
  }

  @override
  Future<Visit> reportVisit(
      Visit visit, VisitStatus status, String catatan) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final baru = visit.copyWith(status: status, catatan: catatan);
    _laporan[visit.id] = baru;
    return baru;
  }

  @override
  Future<List<TokoPilihan>> getTokoPilihan() async => [
        for (var i = 0; i < _toko.length; i++)
          TokoPilihan(id: i + 1, nama: _toko[i], salesId: (i % 3) + 1),
      ];

  @override
  Future<List<Visit>> saveVisits(
    int salesId,
    List<Visit> awal,
    List<Visit> baru,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
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
///   GET    /sales/{id}/visits       (Manager)
///   POST   /visits                  (Manager: sales_id, customer_id, visit_date)
///   PUT    /visits/{id}             (Manager: customer_id, visit_date)
///   DELETE /visits/{id}             (Manager)
///   GET    /customers               (daftar toko, berhalaman)
///   GET    /my-visits               (Sales)
///   PATCH  /visits/{id}/report      (Sales: status + note)
class ApiSalesVisitRepository implements SalesVisitRepository {
  const ApiSalesVisitRepository();

  Dio get _dio => ApiClient.instance.dio;

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
    final res = await _dio.patch('/visits/${visit.id}/report', data: {
      'status': status == VisitStatus.visited ? 'visited' : 'not_visited',
      'note': catatan,
    });
    return Visit.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<TokoPilihan>> getTokoPilihan() async {
    final hasil = <TokoPilihan>[];
    var page = 1;
    var terakhir = 1;
    do {
      final res = await _dio.get('/customers', queryParameters: {'page': page});
      final body = res.data as Map<String, dynamic>;
      for (final e in body['data'] as List) {
        final m = e as Map<String, dynamic>;
        hasil.add(
          TokoPilihan(
            id: (m['id'] as num).toInt(),
            nama: m['name'].toString(),
            // Dua field ini diisi modul Customer; kalau belum ada, bernilai null.
            salesId: (m['sales_id'] as num?)?.toInt(),
            hariKunjungan: (m['visit_day'] as num?)?.toInt(),
          ),
        );
      }
      terakhir = ((body['meta'] as Map?)?['last_page'] as num?)?.toInt() ?? 1;
      page++;
    } while (page <= terakhir);
    return hasil;
  }

  @override
  Future<List<Visit>> saveVisits(
    int salesId,
    List<Visit> awal,
    List<Visit> baru,
  ) async {
    final idAwal = {for (final v in awal) v.id};
    final idBaru = {for (final v in baru) v.id};

    // 1. Dihapus: ada di awal, tidak ada di baru (hanya yang masih scheduled).
    for (final v in awal) {
      if (!idBaru.contains(v.id) && v.status == VisitStatus.scheduled) {
        await _dio.delete('/visits/${v.id}');
      }
    }

    // 2. Diubah: toko atau tanggalnya berbeda dari yang awal.
    for (final v in baru) {
      if (!idAwal.contains(v.id) || v.customerId == null) continue;
      final lama = awal.firstWhere((x) => x.id == v.id);
      if (lama.customerId != v.customerId || lama.tanggal != v.tanggal) {
        await _dio.put('/visits/${v.id}', data: {
          'customer_id': v.customerId,
          'visit_date': _tgl(v.tanggal),
        });
      }
    }

    // 3. Ditambah: id belum ada di server.
    for (final v in baru) {
      if (idAwal.contains(v.id) || v.customerId == null) continue;
      await _dio.post('/visits', data: {
        'sales_id': salesId,
        'customer_id': v.customerId,
        'visit_date': _tgl(v.tanggal),
      });
    }

    return getVisits(salesId);
  }

  /// yyyy-MM-dd, format yang diminta Laravel.
  static String _tgl(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
