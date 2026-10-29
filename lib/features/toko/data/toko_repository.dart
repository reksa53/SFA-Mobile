import 'toko.dart';

abstract class TokoRepository {
  Future<List<Toko>> getTokoSales();
}

/// Data sementara. Nanti diganti implementasi yang memanggil API Laravel;
/// UI tidak perlu diubah.
class DummyTokoRepository implements TokoRepository {
  const DummyTokoRepository();

  @override
  Future<List<Toko>> getTokoSales() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _data;
  }

  static const _data = [
    Toko(id: 1, nama: 'TOKO PURNAMA ABADI SENTOSA', pemilik: 'BAMBANG SUTRISNO', telepon: '085876543210', alamat: 'JL. JEND. SOEDIRMAN, KABUPATEN KLATEN'),
    Toko(id: 2, nama: 'TOKO JAYA AGUNG MANDIRI', pemilik: 'BAMBANG SUTRISNO', telepon: '085876543210', alamat: 'JL. JEND. SOEDIRMAN, KABUPATEN KLATEN'),
    Toko(id: 3, nama: 'TOKO KEMBALI DJAYA', pemilik: 'BAMBANG SUTRISNO', telepon: '085876543210', alamat: 'JL. JEND. SOEDIRMAN, KABUPATEN KLATEN'),
    Toko(id: 4, nama: 'TOKO SELAMAT SEJAHTERA', pemilik: 'BAMBANG SUTRISNO', telepon: '085876543210', alamat: 'JL. JEND. SOEDIRMAN, KABUPATEN KLATEN'),
    Toko(id: 5, nama: 'TOKO DJAYA AGUNG SENTOSA', pemilik: 'BAMBANG SUTRISNO', telepon: '085876543210', alamat: 'JL. JEND. SOEDIRMAN, KABUPATEN KLATEN'),
    Toko(id: 6, nama: 'TOKO HAMBA ALLAH', pemilik: 'BAMBANG SUTRISNO', telepon: '085876543210', alamat: 'JL. JEND. SOEDIRMAN, KABUPATEN KLATEN'),
  ];
}