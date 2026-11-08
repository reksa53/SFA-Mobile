import '../../utils/date_id.dart';

enum VisitStatus {
  pending('Pending'),
  process('Process'),
  done('Done');

  const VisitStatus(this.label);
  final String label;

  static VisitStatus parse(Object? raw) {
    switch (raw?.toString().toLowerCase()) {
      case 'done':
      case 'selesai':
      case 'completed':
        return VisitStatus.done;
      case 'process':
      case 'proses':
      case 'processing':
      case 'in_progress':
        return VisitStatus.process;
      default:
        return VisitStatus.pending;
    }
  }
}

class Visit {
  const Visit({
    required this.id,
    required this.tokoNama,
    required this.tanggal,
    required this.status,
  });

  final int id;
  final String tokoNama;
  final DateTime tanggal; // hanya tanggal, tanpa jam
  final VisitStatus status;

  /// ASUMSI nama field API: id, store_name (atau toko.name), visit_date, status.
  /// Sesuaikan dengan response Laravel.
  factory Visit.fromJson(Map<String, dynamic> json) {
    final toko = json['toko'] ?? json['store'];
    final nama = json['store_name'] ??
        json['toko_name'] ??
        (toko is Map ? (toko['name'] ?? toko['nama']) : null);
    final tanggal = json['visit_date'] ?? json['date'] ?? json['tanggal'];

    return Visit(
      id: (json['id'] as num).toInt(),
      tokoNama: (nama ?? '').toString(),
      tanggal: dateOnly(DateTime.parse(tanggal.toString())),
      status: VisitStatus.parse(json['status']),
    );
  }
}
