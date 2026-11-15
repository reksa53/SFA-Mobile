import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/visit.dart';
import '../../../utils/date_id.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/manager_colors.dart';

/// Kartu satu kunjungan: blok tanggal di kiri, nama toko, dan pil status.
class VisitCard extends StatelessWidget {
  const VisitCard({super.key, required this.visit, this.onTap});

  final Visit visit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);

    return Material(
      color: ManagerColors.listCard,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: Colors.white10),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          child: Row(
            children: [
              _BlokTanggal(tanggal: visit.tanggal),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visit.tokoNama.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatTanggal(visit.tanggal),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              VisitStatusPill(status: visit.tampilan),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlokTanggal extends StatelessWidget {
  const _BlokTanggal({required this.tanggal});

  final DateTime tanggal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0x38000000),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${tanggal.day}',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.05,
              color: AppColors.white,
            ),
          ),
          Text(
            singkatBulan(tanggal.month),
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

/// Titik kecil penanda status di latar gelap (kotak ringkasan dan kalender).
/// Done = hijau, Pending = lingkaran kosong, Terlewat = merah,
/// Tidak dikunjungi = abu-abu.
class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.status, this.size = 7});

  final VisitTampilan status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tebal = size >= 7 ? 1.5 : 1.2;
    final BoxDecoration dekor = switch (status) {
      VisitTampilan.done => BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF22C55E),
          border: Border.all(color: Colors.white, width: 1),
        ),
      VisitTampilan.terlewat => BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.red,
          border: Border.all(color: Colors.white, width: 1),
        ),
      VisitTampilan.pending => BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white70, width: tebal),
        ),
      VisitTampilan.tidak => const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white38,
        ),
    };
    return Container(width: size, height: size, decoration: dekor);
  }
}

/// Pil status: Done putih, Terlewat merah, Pending garis tepi, Tidak
/// dikunjungi abu-abu.
class VisitStatusPill extends StatelessWidget {
  const VisitStatusPill({super.key, required this.status});

  final VisitTampilan status;

  @override
  Widget build(BuildContext context) {
    final Color latar = switch (status) {
      VisitTampilan.done => AppColors.white,
      VisitTampilan.terlewat => AppColors.red,
      VisitTampilan.pending => Colors.transparent,
      VisitTampilan.tidak => const Color(0x33FFFFFF),
    };
    final Color teks =
        status == VisitTampilan.done ? AppColors.black : AppColors.white;
    final Color titik = status == VisitTampilan.done
        ? const Color(0xFF16A34A)
        : (status == VisitTampilan.tidak ? Colors.white54 : AppColors.white);

    return Container(
      height: 26,
      padding: const EdgeInsets.only(left: 9, right: 11),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(13),
        border: status == VisitTampilan.pending
            ? Border.all(color: Colors.white54, width: 1.5)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: status == VisitTampilan.pending ? null : titik,
              border: status == VisitTampilan.pending
                  ? Border.all(color: Colors.white70, width: 1.5)
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: teks,
            ),
          ),
        ],
      ),
    );
  }
}
