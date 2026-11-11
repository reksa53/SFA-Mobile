import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Header halaman Manager: judul di kiri, tombol cari putih di kanan.
/// Saat tombol cari ditekan, judul berganti menjadi kolom pencarian.
/// SafeArea dipasang oleh layar yang memakainya.
class ManagerHeader extends StatelessWidget {
  const ManagerHeader({
    super.key,
    required this.title,
    required this.searchOpen,
    required this.searchController,
    required this.onSearchToggle,
    this.onSearchChanged,
    this.searchHint = 'Cari...',
  });

  final String title;
  final bool searchOpen;
  final TextEditingController searchController;
  final VoidCallback onSearchToggle;
  final ValueChanged<String>? onSearchChanged;
  final String searchHint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Expanded(
              child: searchOpen
                  ? TextField(
                      controller: searchController,
                      autofocus: true,
                      onChanged: onSearchChanged,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppColors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: searchHint,
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white54,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    )
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Tooltip(
              message: searchOpen ? 'Tutup pencarian' : 'Cari',
              child: Material(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onSearchToggle,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      searchOpen ? Icons.close : Icons.search,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
