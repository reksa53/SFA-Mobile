import 'dart:typed_data';

class Sales {
  const Sales({
    required this.id,
    required this.nama,
    this.fotoUrl,
    this.fotoBytes,
  });

  final int id;
  final String nama;

  /// Foto dari server (alamat URL).
  final String? fotoUrl;

  /// Foto yang baru dipilih dari kamera/galeri di aplikasi (belum diunggah).
  final Uint8List? fotoBytes;

  /// ASUMSI nama field API: id, name, photo. Sesuaikan dengan response Laravel.
  factory Sales.fromJson(Map<String, dynamic> json) => Sales(
        id: (json['id'] as num).toInt(),
        nama: (json['name'] ?? json['nama'] ?? '').toString(),
        fotoUrl: (json['photo'] ?? json['foto'] ?? json['avatar'])?.toString(),
      );

  /// Huruf awal untuk avatar kalau belum ada foto.
  String get inisial {
    final kata =
        nama.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (kata.isEmpty) return '?';
    if (kata.length == 1) return kata.first[0].toUpperCase();
    return (kata[0][0] + kata[1][0]).toUpperCase();
  }
}
