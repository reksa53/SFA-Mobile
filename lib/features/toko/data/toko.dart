class Toko {
  const Toko({
    required this.id,
    required this.nama,
    required this.pemilik,
    required this.telepon,
    required this.alamat,
  });

  final int id;
  final String nama;
  final String pemilik;
  final String telepon;
  final String alamat;

  // fromJson ditambahkan nanti, setelah nama field API Laravel disepakati.
}