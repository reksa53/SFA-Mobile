class Product {
  const Product(this.name, this.expiry, this.stock);
  final String name;
  final DateTime expiry;
  final int stock; // 0 = out of stock
}

// shortcut: data dummy, ganti dengan data API nanti
final dummyProducts = [
  Product('Indomie Goreng', DateTime(2030, 5, 28), 265),
  Product('Teh Botol Sosro', DateTime(2030, 2, 7), 0),
  Product('Beras Premium 5 kg', DateTime(2028, 3, 12), 0),
  Product('Minyak Goreng Bimoli 2 L', DateTime(2028, 9, 30), 55),
  Product('Gula Pasir Gulaku 1 kg', DateTime(2029, 6, 18), 155),
  Product('Kecap Manis Bango 600 ml', DateTime(2028, 2, 5), 63),
  Product('Garam Dapur Refina 500 gr', DateTime(2030, 4, 14), 46),
  Product('Kopi Kapal Api 165 gr', DateTime(2028, 7, 9), 89),
  Product('Susu Kental Manis Frisian Flag', DateTime(2028, 10, 27), 25),
  Product('Ultra Milk Coklat 250 ml', DateTime(2027, 12, 3), 570),
];