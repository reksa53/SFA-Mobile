import 'package:sfa_mobile/data/models/order.dart';
import 'package:sfa_mobile/data/models/order_item.dart';
import 'package:sfa_mobile/data/models/product.dart';

/// Pilihan toko di pop-up Add Order.
/// Sementara, ganti dengan model Customer saat API siap.
class StoreOption {
  const StoreOption({required this.name, required this.address});

  final String name;
  final String address;
}

/// Produk + harga untuk layar cart.
/// Sementara, harga nanti datang dari API bersama Product.
class CatalogItem {
  const CatalogItem({required this.product, required this.price});

  final Product product;
  final int price;

  bool get available =>
      product.stock > 0 && product.expiry.isAfter(DateTime.now());
}

/// Data dummy yang meniru perilaku server: Sales hanya menerima
/// order miliknya sendiri. Saat API siap, ganti isi class ini.
class OrderRepository {
  OrderRepository._();
  static final OrderRepository instance = OrderRepository._();

  // TODO: ganti dengan id user yang login (response /login -> data.id).
  static const currentSalesId = 'S-001';

  static const _seed = <Order>[
    Order(storeName: 'TOKO JAYA TERBUKA ABADI', invoice: 'KAJA0817968BHV', status: OrderStatus.rejected, salesId: 'S-001'),
    Order(storeName: 'TOKO SURYA KARYA', status: OrderStatus.pending, salesId: 'S-001'),
    Order(storeName: 'TOKO REMBULAN PURNAMA', invoice: 'KAJA0817968BHV', status: OrderStatus.accepted, salesId: 'S-001'),
    Order(storeName: 'TOKO ADI JAYA MAKMUR', invoice: 'KAJA0817968BHV', status: OrderStatus.rejected, salesId: 'S-001'),
    Order(storeName: 'TOKO SURYA MENTARI', invoice: 'KAJA0817968BHV', status: OrderStatus.accepted, salesId: 'S-001'),
    Order(storeName: 'TOKO NANDA JAYA', status: OrderStatus.pending, salesId: 'S-001'),
    Order(storeName: 'TOKO KARYA MUSTIKA', invoice: 'KAJA0817968BHV', status: OrderStatus.rejected, salesId: 'S-001'),
    Order(storeName: 'TOKO JAYA PAK HAMBALI', status: OrderStatus.pending, salesId: 'S-001'),
    Order(storeName: 'TOKO SURYA AMBATUKAM', invoice: 'KAJA0817968BHV', status: OrderStatus.accepted, salesId: 'S-001'),
    Order(storeName: 'TOKO PITIPIWPIW WIW WIW', status: OrderStatus.pending, salesId: 'S-001'),
    Order(storeName: 'TOKO SINAR BARU', invoice: 'KAJA0817968BHV', status: OrderStatus.accepted, salesId: 'S-001'),
    // Milik Sales lain: tidak boleh muncul di layar Sales S-001.
    Order(storeName: 'TOKO MILIK SALES LAIN', invoice: 'KAJA0817968BHV', status: OrderStatus.accepted, salesId: 'S-002'),
    Order(storeName: 'TOKO MILIK SALES LAIN 2', status: OrderStatus.pending, salesId: 'S-002'),
  ];

  final List<Order> _orders = [..._seed];

  static const _prices = {
    'Indomie Goreng': 3500,
    'Teh Botol Sosro': 5000,
    'Beras Premium 5 kg': 68000,
    'Minyak Goreng Bimoli 2 L': 38000,
    'Gula Pasir Gulaku 1 kg': 17000,
    'Kecap Manis Bango 600 ml': 24000,
    'Garam Dapur Refina 500 gr': 4000,
    'Kopi Kapal Api 165 gr': 12000,
    'Susu Kental Manis Frisian Flag': 11000,
    'Ultra Milk Coklat 250 ml': 6500,
  };

  List<Order> ordersForSales(String salesId) =>
      _orders.where((o) => o.salesId == salesId).toList(growable: false);

  // TODO: server hanya mengembalikan customer yang di-assign ke salesId.
  List<StoreOption> storesForSales(String salesId) => const [
        StoreOption(name: 'TOKO JAYA TERBUKA ABADI', address: 'Alamat toko'),
        StoreOption(name: 'TOKO SURYA KARYA', address: 'Alamat toko'),
        StoreOption(name: 'TOKO REMBULAN PURNAMA', address: 'Alamat toko'),
        StoreOption(name: 'TOKO ADI JAYA MAKMUR', address: 'Alamat toko'),
        StoreOption(name: 'TOKO NANDA JAYA', address: 'Alamat toko'),
      ];

  List<CatalogItem> catalog() => [
        for (final p in dummyProducts)
          CatalogItem(product: p, price: _prices[p.name] ?? 0),
      ];

  Order submit({
    required String storeName,
    required String salesId,
    required List<OrderItem> items,
  }) {
    final order = Order(
      storeName: storeName,
      status: OrderStatus.pending, // belum ada invoice sampai Manager memproses
      salesId: salesId,
      items: items,
    );
    _orders.insert(0, order);
    return order;
  }
}