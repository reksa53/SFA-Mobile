/// Nama hari kunjungan tetap: 1 = Senin ... 5 = Jumat.
const kVisitDayNames = <int, String>{
  1: 'Senin',
  2: 'Selasa',
  3: 'Rabu',
  4: 'Kamis',
  5: 'Jumat',
};

/// Model customer dari API (GET /customers).
class CustomerStore {
  const CustomerStore({
    this.id,
    this.code,
    required this.storeName,
    required this.ownerName,
    required this.phone,
    required this.address,
    this.notes,
    this.salesId,
    this.salesName,
    this.visitDay,
    this.photoUrl,
  });

  final int? id;
  final String? code;
  final String storeName;
  final String ownerName;
  final String phone;
  final String address;
  final String? notes;

  /// Null = toko belum ditugaskan ke sales mana pun.
  final int? salesId;
  final String? salesName;

  /// 1 = Senin ... 5 = Jumat. Null = tidak ada jadwal kunjungan tetap.
  final int? visitDay;
  final String? photoUrl;

  String? get visitDayName => kVisitDayNames[visitDay];

  factory CustomerStore.fromJson(Map<String, dynamic> j) {
    final sales = j['sales'] as Map<String, dynamic>?;
    final day = j['visit_day'];
    return CustomerStore(
      id: j['id'] as int?,
      code: j['code'] as String?,
      storeName: (j['name'] ?? '') as String,
      ownerName: (j['owner_name'] ?? '') as String,
      phone: (j['phone'] ?? '') as String,
      address: (j['address'] ?? '') as String,
      notes: j['notes'] as String?,
      salesId: (sales?['id'] ?? j['sales_id']) as int?,
      salesName: sales?['name'] as String?,
      visitDay: day is num ? day.toInt() : int.tryParse('${day ?? ''}'),
      photoUrl: j['photo_url'] as String?,
    );
  }
}
