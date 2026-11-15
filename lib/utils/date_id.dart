const _namaBulan = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const _singkatBulan = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

/// [bulan] 1..12
String namaBulan(int bulan) => _namaBulan[bulan - 1];

/// Contoh: OKT. [bulan] 1..12
String singkatBulan(int bulan) => _singkatBulan[bulan - 1];

/// Contoh: 23 Oktober 2026
String formatTanggal(DateTime d) => '${d.day} ${namaBulan(d.month)} ${d.year}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
