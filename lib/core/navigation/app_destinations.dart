import '../../features/toko/presentation/toko_page.dart';
import '../constants/app_assets.dart';
import '../widgets/placeholder_page.dart';
import 'nav_destination.dart';

/// Urutan di sini = urutan tombol di navbar.
/// Untuk memasang halaman baru: ganti PlaceholderPage dengan halaman aslinya.
final List<NavDestination> appDestinations = [
  NavDestination(
    label: 'Toko',
    iconAsset: AppAssets.iconToko,
    builder: (_) => const TokoPage(),
  ),
  NavDestination(
    label: 'Produk',
    iconAsset: AppAssets.iconProduk,
    builder: (_) => const PlaceholderPage(title: 'Produk'),
  ),
  NavDestination(
    label: 'Visit',
    iconAsset: AppAssets.iconVisit,
    builder: (_) => const PlaceholderPage(title: 'Visit'),
  ),
  NavDestination(
    label: 'Order',
    iconAsset: AppAssets.iconOrder,
    builder: (_) => const PlaceholderPage(title: 'Order'),
  ),
];