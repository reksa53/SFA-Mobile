import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/visit.dart';

/// Pil status untuk latar PUTIH (daftar kunjungan Sales).
class VisitStatusChipLight extends StatelessWidget {
  const VisitStatusChipLight({super.key, required this.status});

  final VisitTampilan status;

  @override
  Widget build(BuildContext context) {
    return _Chip(
      status: status,
      latar: switch (status) {
        VisitTampilan.done => const Color(0xFFDCFCE7),
        VisitTampilan.terlewat => const Color(0xFFFDE2E2),
        VisitTampilan.pending => Colors.transparent,
        VisitTampilan.tidak => const Color(0xFFEAEAEA),
      },
      teks: switch (status) {
        VisitTampilan.done => const Color(0xFF166534),
        VisitTampilan.terlewat => const Color(0xFF9B1C1C),
        _ => const Color(0xFF555555),
      },
      garis: const Color(0xFFBDBDBD),
      titikPending: const Color(0xFF888888),
    );
  }
}

/// Pil status untuk latar GELAP (panel detail).
class VisitStatusChipDark extends StatelessWidget {
  const VisitStatusChipDark({super.key, required this.status});

  final VisitTampilan status;

  @override
  Widget build(BuildContext context) {
    return _Chip(
      status: status,
      latar: switch (status) {
        VisitTampilan.done => const Color(0x3822C55E),
        VisitTampilan.terlewat => const Color(0x59C80000),
        VisitTampilan.pending => Colors.transparent,
        VisitTampilan.tidak => const Color(0x2EFFFFFF),
      },
      teks: switch (status) {
        VisitTampilan.done => const Color(0xFFB7F5CC),
        VisitTampilan.terlewat => const Color(0xFFFFD2D2),
        _ => Colors.white,
      },
      garis: Colors.white70,
      titikPending: Colors.white,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.status,
    required this.latar,
    required this.teks,
    required this.garis,
    required this.titikPending,
  });

  final VisitTampilan status;
  final Color latar;
  final Color teks;
  final Color garis;
  final Color titikPending;

  @override
  Widget build(BuildContext context) {
    final pending = status == VisitTampilan.pending;
    final Color titik = switch (status) {
      VisitTampilan.done => const Color(0xFF22C55E),
      VisitTampilan.terlewat => const Color(0xFFC80000),
      VisitTampilan.tidak => const Color(0xFF999999),
      VisitTampilan.pending => titikPending,
    };

    return Container(
      height: 24,
      padding: const EdgeInsets.only(left: 8, right: 10),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(12),
        border: pending ? Border.all(color: garis, width: 1.5) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pending ? null : titik,
              border: pending ? Border.all(color: titik, width: 1.5) : null,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: teks,
            ),
          ),
        ],
      ),
    );
  }
}
