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
    this.photoUrl,
  });

  final int? id;
  final String? code;
  final String storeName;
  final String ownerName;
  final String phone;
  final String address;
  final String? notes;
  final int? salesId;
  final String? salesName;
  final String? photoUrl;

  factory CustomerStore.fromJson(Map<String, dynamic> j) {
    final sales = j['sales'] as Map<String, dynamic>?;
    return CustomerStore(
      id: j['id'] as int?,
      code: j['code'] as String?,
      storeName: (j['name'] ?? '') as String,
      ownerName: (j['owner_name'] ?? '') as String,
      phone: (j['phone'] ?? '') as String,
      address: (j['address'] ?? '') as String,
      notes: j['notes'] as String?,
      salesId: sales?['id'] as int?,
      salesName: sales?['name'] as String?,
      photoUrl: j['photo_url'] as String?,
    );
  }
}