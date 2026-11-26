import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Header halaman Manager: judul di kiri, tombol cari di kanan.
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
    this.searchHint = 'Search...',
  });

  final String title;
  final bool searchOpen;
  final TextEditingController searchController;
  final VoidCallback onSearchToggle;
  final ValueChanged<String>? onSearchChanged;
  final String searchHint;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

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
                      cursorColor: p.text,
                      style: GoogleFonts.poppins(fontSize: 16, color: p.text),
                      decoration: InputDecoration(
                        hintText: searchHint,
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 16,
                          color: p.textFaint,
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
                          color: p.text,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Tooltip(
              message: searchOpen ? 'Close search' : 'Search',
              child: Material(
                color: p.surface,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onSearchToggle,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: p.surfaceBorder,
                    ),
                    child: Icon(
                      searchOpen ? Icons.close : Icons.search,
                      color: p.onSurface,
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
