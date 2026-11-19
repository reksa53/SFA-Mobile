enum CustomerVisitStatus { scheduled, visited, notVisited }

/// Satu kunjungan ke customer (dari GET /customers/{id}/visits).
class CustomerVisit {
  const CustomerVisit({
    required this.id,
    required this.salesId,
    required this.date,
    required this.status,
    this.salesName,
    this.note,
    this.reportedAt,
  });

  final int id;
  final int salesId;
  final String? salesName;

  /// Tanggal saja (jam 00:00 waktu lokal).
  final DateTime date;
  final CustomerVisitStatus status;
  final String? note;
  final DateTime? reportedAt;

  bool get isScheduled => status == CustomerVisitStatus.scheduled;

  /// Jadwal yang tanggalnya sudah lewat tapi belum dilaporkan.
  bool get isOverdue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return isScheduled && date.isBefore(today);
  }

  factory CustomerVisit.fromJson(Map<String, dynamic> j) {
    final sales = j['sales'] as Map<String, dynamic>?;
    final reported = j['reported_at'] as String?;
    return CustomerVisit(
      id: j['id'] as int,
      salesId: j['sales_id'] as int,
      salesName: sales?['name'] as String?,
      date: DateTime.parse(j['visit_date'] as String),
      status: switch (j['status']) {
        'visited' => CustomerVisitStatus.visited,
        'not_visited' => CustomerVisitStatus.notVisited,
        _ => CustomerVisitStatus.scheduled,
      },
      note: j['note'] as String?,
      reportedAt: reported == null ? null : DateTime.parse(reported).toLocal(),
    );
  }
}
