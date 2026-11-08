import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/manager_colors.dart';
import '../../../utils/date_id.dart';

/// Kalender bulanan (minggu mulai Minggu, tanpa nama hari — sesuai Figma).
/// Hari di luar bulan ditampilkan sama seperti desain; kalau diketuk, kalender
/// pindah ke bulan tersebut.
class VisitCalendar extends StatelessWidget {
  const VisitCalendar({
    super.key,
    required this.month,
    required this.selected,
    required this.markedDays,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onSelect,
  });

  final DateTime month; // tanggal 1 pada bulan yang ditampilkan
  final DateTime? selected;
  final Set<DateTime> markedDays; // hari yang punya kunjungan (dateOnly)
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final leading = first.weekday % 7; // Minggu = 0
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final rows = ((leading + daysInMonth) / 7).ceil();
    final yearSuffix =
        month.year == DateTime.now().year ? '' : ' ${month.year}';

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: BoxDecoration(
        color: ManagerColors.calendar,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Bulan sebelumnya',
                onPressed: onPrevMonth,
                icon: const Icon(Icons.chevron_left,
                    size: 30, color: AppColors.white),
              ),
              SizedBox(
                width: 160,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${namaBulan(month.month).toUpperCase()}$yearSuffix',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Bulan berikutnya',
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right,
                    size: 30, color: AppColors.white),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (var r = 0; r < rows; r++)
            Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: _DayCell(
                      date: _dateAt(leading, r, c),
                      selected: selected != null &&
                          isSameDay(selected!, _dateAt(leading, r, c)),
                      marked: markedDays.contains(_dateAt(leading, r, c)),
                      onTap: onSelect,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  DateTime _dateAt(int leading, int r, int c) =>
      DateTime(month.year, month.month, 1 - leading + r * 7 + c);
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.selected,
    required this.marked,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool marked;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => onTap(date),
        child: Center(
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.red : Colors.transparent,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                if (marked)
                  Positioned(
                    bottom: 3,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? AppColors.white : AppColors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
