import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/visit.dart';
import '../../../utils/date_id.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/manager_colors.dart';
import 'visit_card.dart';

const _hari = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/// Kalender bulanan (minggu mulai Minggu). Hari ini diberi lingkaran putih,
/// hari terpilih lingkaran merah, dan titik di bawah angka menunjukkan status
/// kunjungan pada hari itu.
class VisitCalendar extends StatelessWidget {
  const VisitCalendar({
    super.key,
    required this.month,
    required this.selected,
    required this.statusPerHari,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onSelect,
    this.cellHeight = 46,
    this.compact = false,
  });

  /// Tanggal 1 bulan yang ditampilkan.
  final DateTime month;
  final DateTime? selected;

  /// Kunci = tanggal (tanpa jam), isi = status kunjungan di hari itu.
  final Map<DateTime, Set<VisitTampilan>> statusPerHari;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelect;

  /// Tinggi satu baris tanggal. Bawaan 46; layar Sales memakai 31 + compact.
  final double cellHeight;

  /// Mode rapat (layar Sales): padding, judul, dan lingkaran tanggal diperkecil.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hariIni = dateOnly(DateTime.now());
    final awal = DateTime(month.year, month.month, 1);
    final offset = awal.weekday % 7; // Minggu = 0
    final jumlahHari = DateTime(month.year, month.month + 1, 0).day;
    final baris = ((offset + jumlahHari) / 7).ceil();

    DateTime tanggalKe(int i) =>
        DateTime(month.year, month.month, 1 - offset + i);

    return Container(
      padding: compact
          ? const EdgeInsets.fromLTRB(10, 6, 10, 4)
          : const EdgeInsets.fromLTRB(10, 12, 10, 8),
      decoration: BoxDecoration(
        color: ManagerColors.calendar,
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, compact ? 2 : 6),
            child: Row(
              children: [
                _NavBulan(
                    icon: Icons.chevron_left,
                    onTap: onPrevMonth,
                    compact: compact),
                Expanded(
                  child: Center(
                    child: Text(
                      '${namaBulan(month.month)} ${month.year}',
                      style: GoogleFonts.poppins(
                        fontSize: compact ? 15 : 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
                _NavBulan(
                    icon: Icons.chevron_right,
                    onTap: onNextMonth,
                    compact: compact),
              ],
            ),
          ),
          Row(
            children: [
              for (final h in _hari)
                Expanded(
                  child: Padding(
                    padding: compact
                        ? const EdgeInsets.symmetric(vertical: 2)
                        : const EdgeInsets.only(top: 4, bottom: 6),
                    child: Center(
                      child: Text(
                        h,
                        style: GoogleFonts.poppins(
                          fontSize: compact ? 10 : 10.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          for (var r = 0; r < baris; r++)
            Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: _Hari(
                      tanggal: tanggalKe(r * 7 + c),
                      bulanIni: month.month,
                      hariIni: hariIni,
                      dipilih: selected != null &&
                          isSameDay(selected!, tanggalKe(r * 7 + c)),
                      status:
                          statusPerHari[tanggalKe(r * 7 + c)] ?? const {},
                      onTap: onSelect,
                      cellHeight: cellHeight,
                      compact: compact,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _NavBulan extends StatelessWidget {
  const _NavBulan({
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x1AFFFFFF),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: compact ? 30 : 34,
          height: compact ? 30 : 34,
          child: Icon(icon, size: compact ? 20 : 22, color: AppColors.white),
        ),
      ),
    );
  }
}

class _Hari extends StatelessWidget {
  const _Hari({
    required this.tanggal,
    required this.bulanIni,
    required this.hariIni,
    required this.dipilih,
    required this.status,
    required this.onTap,
    required this.cellHeight,
    required this.compact,
  });

  final DateTime tanggal;
  final int bulanIni;
  final DateTime hariIni;
  final bool dipilih;
  final Set<VisitTampilan> status;
  final ValueChanged<DateTime> onTap;
  final double cellHeight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final lingkar = compact ? 23.0 : (cellHeight >= 44 ? 30.0 : 28.0);
    final luar = tanggal.month != bulanIni;
    final adalahHariIni = isSameDay(tanggal, hariIni);
    // Urutan titik tetap sesuai urutan enum (maksimal 3).
    final titik = VisitTampilan.values.where(status.contains).take(3);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onTap(tanggal),
      child: SizedBox(
        height: cellHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: lingkar,
              height: lingkar,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dipilih ? AppColors.red : null,
                border: (adalahHariIni && !dipilih)
                    ? Border.all(color: AppColors.white, width: 1.5)
                    : null,
              ),
              child: Text(
                '${tanggal.day}',
                style: GoogleFonts.poppins(
                  fontSize: compact ? 13 : 14,
                  fontWeight: luar ? FontWeight.w500 : FontWeight.w600,
                  color: luar ? Colors.white38 : AppColors.white,
                ),
              ),
            ),
            SizedBox(height: compact ? 0 : 2),
            SizedBox(
              height: compact ? 5 : 7,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final s in titik)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: StatusDot(status: s, size: compact ? 4 : 5),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
