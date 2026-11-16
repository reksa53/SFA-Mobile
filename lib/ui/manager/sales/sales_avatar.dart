import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/sales.dart';

/// Pasangan warna untuk avatar berinisial (dipilih dari id sales).
const _nada = <List<Color>>[
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

/// Avatar sales: foto (dari galeri/kamera atau URL) kalau ada, kalau tidak
/// lingkaran berwarna dengan inisial.
class SalesAvatar extends StatelessWidget {
  const SalesAvatar({super.key, required this.sales, this.size = 52});

  final Sales sales;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bytes = sales.fotoBytes;
    final url = sales.fotoUrl;
    final ImageProvider? gambar = bytes != null
        ? MemoryImage(bytes)
        : (url != null && url.isNotEmpty ? NetworkImage(url) : null);
    final warna = _nada[sales.id.abs() % _nada.length];

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gambar == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: warna,
              )
            : null,
        image: gambar == null
            ? null
            : DecorationImage(image: gambar, fit: BoxFit.cover),
        border: Border.all(color: Colors.white38, width: 2),
      ),
      child: gambar != null
          ? null
          : Text(
              sales.inisial,
              style: GoogleFonts.poppins(
                fontSize: size * 0.33,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF222222),
              ),
            ),
    );
  }
}
