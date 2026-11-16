import '../../utils/date_id.dart';

/// Status kunjungan seperti di database (kolom visits.status).
enum VisitStatus {
  scheduled('Pending'), // dijadwalkan, belum ada hasil
  visited('Done'), // sudah dikunjungi
  notVisited('Not visited'); // tidak jadi dikunjungi

  const VisitStatus(this.label);
  final String label;

  static VisitStatus parse(Object? raw) {
    switch (raw?.toString().toLowerCase()) {
      case 'visited':
      case 'done':
      case 'selesai':
      case 'completed':
        return VisitStatus.visited;
      case 'not_visited':
      case 'notvisited':
      case 'tidak_dikunjungi':
        return VisitStatus.notVisited;
      default:
        return VisitStatus.scheduled;
    }
  }
}

/// Status yang DITAMPILKAN di UI. "Terlewat" tidak ada di database: itu
/// jadwal yang masih `scheduled` tetapi tanggalnya sudah lewat.
enum VisitTampilan {
  done('Done', 'Done'),
  pending('Pending', 'Pending'),
  terlewat('Overdue', 'Overdue'),
  tidak('Not visited', 'Missed');

  const VisitTampilan(this.label, this.singkat);

  /// Teks lengkap (dipakai di pil status kartu).
  final String label;

  /// Teks pendek (dipakai di kotak ringkasan).
  final String singkat;
}

class Visit {
  const Visit({
    required this.id,
    required this.tokoNama,
    required this.tanggal,
    this.status = VisitStatus.scheduled,
    this.catatan = '',
  });

  final int id;
  final String tokoNama;
  final DateTime tanggal; // hanya tanggal, tanpa jam
  final VisitStatus status;
  final String catatan; // catatan hasil kunjungan (diisi Sales)

  /// Status untuk ditampilkan; menghitung "Terlewat" dari tanggal.
  VisitTampilan get tampilan {
    switch (status) {
      case VisitStatus.visited:
        return VisitTampilan.done;
      case VisitStatus.notVisited:
        return VisitTampilan.tidak;
      case VisitStatus.scheduled:
        final hariIni = dateOnly(DateTime.now());
        return tanggal.isBefore(hariIni)
            ? VisitTampilan.terlewat
            : VisitTampilan.pending;
    }
  }

  /// ASUMSI nama field API: id, customer.name (atau store_name),
  /// scheduled_date, status, notes. Sesuaikan dengan response Laravel.
  factory Visit.fromJson(Map<String, dynamic> json) {
    final toko = json['customer'] ?? json['toko'] ?? json['store'];
    final nama = json['store_name'] ??
        json['customer_name'] ??
        (toko is Map ? (toko['name'] ?? toko['nama']) : null);
    final tanggal = json['scheduled_date'] ??
        json['visit_date'] ??
        json['date'] ??
        json['tanggal'];

    return Visit(
      id: (json['id'] as num).toInt(),
      tokoNama: (nama ?? '').toString(),
      tanggal: dateOnly(DateTime.parse(tanggal.toString())),
      status: VisitStatus.parse(json['status']),
      catatan: (json['notes'] ?? json['note'] ?? json['catatan'] ?? '')
          .toString(),
    );
  }

  Visit copyWith({
    String? tokoNama,
    DateTime? tanggal,
    VisitStatus? status,
    String? catatan,
  }) =>
      Visit(
        id: id,
        tokoNama: tokoNama ?? this.tokoNama,
        tanggal: tanggal ?? this.tanggal,
        status: status ?? this.status,
        catatan: catatan ?? this.catatan,
      );
}
