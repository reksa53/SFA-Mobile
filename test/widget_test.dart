import 'package:flutter_test/flutter_test.dart';
import 'package:sfa_mobile/app.dart';

void main() {
  testWidgets('halaman Toko menampilkan daftar toko', (tester) async {
    await tester.pumpWidget(const SfaApp());

    // Tunggu data dummy selesai dimuat (repository menunda 400 ms).
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('CENTRAL SINN'), findsOneWidget);
    expect(find.text('TOKO PURNAMA ABADI SENTOSA'), findsOneWidget);
  });
}