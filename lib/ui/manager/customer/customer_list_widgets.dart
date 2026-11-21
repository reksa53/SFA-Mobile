import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sfa_mobile/data/models/customer_store.dart';

import '../../core/theme/app_colors.dart';

/// Potongan tampilan daftar Customer yang dipakai bersama oleh layar
/// Manager dan Sales. Bentuknya disamakan dengan daftar Sales & Visit:
/// satu kotak putih, baris dengan avatar bulat, pemisah tipis, dan panah.

/// Warna avatar toko tanpa foto (dipilih dari id toko).
const _tones = <List<Color>>[
  [Color(0xFFF1C7B0), Color(0xFFE2A387)],
  [Color(0xFFB7D6F0), Color(0xFF8FBAE0)],
  [Color(0xFFF3DD9A), Color(0xFFE2C26C)],
  [Color(0xFFBEE2C4), Color(0xFF92CC9D)],
  [Color(0xFFD4C4F0), Color(0xFFB3A0DE)],
  [Color(0xFFF2B9CB), Color(0xFFE394AF)],
  [Color(0xFFB2E2E2), Color(0xFF86CDCD)],
  [Color(0xFFE6D2B4), Color(0xFFD2B88F)],
  [Color(0xFFC3CAF0), Color(0xFF9FA9E0)],
];

/// Baris ringkasan di bawah judul, mis. "50 stores".
class CustomerSubtitle extends StatelessWidget {
  const CustomerSubtitle({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$count ${count == 1 ? 'store' : 'stores'}',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
        ),
      ),
    );
  }
}

/// Kotak putih berisi daftar toko (bisa di-refresh dengan tarik ke bawah).
class CustomerListCard extends StatelessWidget {
  const CustomerListCard({
    super.key,
    required this.stores,
    required this.onRefresh,
    required this.onTap,
  });

  final List<CustomerStore> stores;
  final Future<void> Function() onRefresh;
  final void Function(CustomerStore store) onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        child: Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: RefreshIndicator(
            color: AppColors.red,
            onRefresh: onRefresh,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: stores.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFECECEC),
              ),
              itemBuilder: (_, i) => CustomerStoreRow(
                store: stores[i],
                onTap: () => onTap(stores[i]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreAvatar extends StatelessWidget {
    const _StoreAvatar({required this.store});

  final CustomerStore store;
  final double size = 48;

  @override
  Widget build(BuildContext context) {
    final photo = store.photoUrl;
    final hasPhoto = photo != null && photo.isNotEmpty;
    final tone = _tones[(store.id ?? 0).abs() % _tones.length];

    final placeholder = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tone,
        ),
      ),
      child: Icon(
        Icons.storefront_outlined,
        size: size * 0.45,
        color: const Color(0xFF222222),
      ),
    );

    if (!hasPhoto) return placeholder;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          photo,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => placeholder,
        ),
      ),
    );
  }
}

/// Satu baris toko di dalam kotak putih.
class CustomerStoreRow extends StatelessWidget {
  const CustomerStoreRow({super.key, required this.store, required this.onTap});

  final CustomerStore store;
  final VoidCallback onTap;

  static TextStyle get _grey =>
      GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF777777));

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            _StoreAvatar(store: store),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          store.ownerName.isEmpty ? '-' : store.ownerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _grey,
                        ),
                      ),
                      if (store.phone.isNotEmpty)
                        Text(store.phone, style: _grey),
                    ],
                  ),
                  Text(
                    store.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _grey,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Color(0xFFB5B5B5)),
          ],
        ),
      ),
    );
  }
}

/// Bilah bawah: jumlah toko + tombol Add Store (null = disembunyikan).
class CustomerBottomBar extends StatelessWidget {
  const CustomerBottomBar({
    super.key,
    required this.count,
    required this.label,
    required this.onAddStore,
  });

  final int count;
  final String label;
  final VoidCallback? onAddStore;

  @override
  Widget build(BuildContext context) {
    final add = onAddStore;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.glass,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          if (add != null)
            SizedBox(
              height: 32,
              child: FilledButton(
                onPressed: add,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: AppColors.white,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: const StadiumBorder(),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Add Store',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.add_circle, size: 16),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Teks status di tengah (gagal memuat / kosong).
Widget customerListMessage(String text) => Center(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(fontSize: 13.5, color: AppColors.white),
    ),
  ),
);
