import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/services/api_client.dart';
import '../../../data/models/sales.dart';
import '../../../data/models/visit.dart';
import '../../../data/repositories/sales_visit_repository.dart';
import '../../../utils/date_id.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/manager_colors.dart';
import '../../manager/sales/sales_avatar.dart';
import '../../manager/sales/visit_calendar.dart';
import '../../manager/sales/visit_card.dart' show StatusDot;
import 'visit_detail_screen.dart';
import 'visit_status_chip.dart';

/// Tab "Visit" untuk role Sales: ringkasan, kalender, dan daftar kunjungan.
/// Tidak ada navbar di sini; navbar dipasang oleh TabShell di SalesShell.
class SalesVisitScreen extends StatefulWidget {
  const SalesVisitScreen({
    super.key,
    this.salesName = 'Sales',
    this.repository = const ApiSalesVisitRepository(),
  });

  /// Nama Sales yang login (nanti ambil dari data login).
  final String salesName;
  final SalesVisitRepository repository;

  @override
  State<SalesVisitScreen> createState() => _SalesVisitScreenState();
}

class _SalesVisitScreenState extends State<SalesVisitScreen> {
  late DateTime _month;
  DateTime? _selected;
  VisitTampilan? _filter;
  List<Visit> _visits = const [];
  bool _loading = true;
  bool _failed = false;
    String? _nama;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _load();
        ApiClient.instance.getName().then((n) {
      if (mounted && n != null) setState(() => _nama = n);
    });
  }

  // Tab yang tidak sedang tampil "dimatikan" (TickerMode = false) tapi tetap
  // hidup. Saat tab dibuka lagi, ambil ulang data supaya perubahan dari tab
  // lain (mis. Customer) langsung terlihat.
  bool _tabAktif = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final aktif = TickerMode.of(context);
    if (aktif && !_tabAktif && !_loading) _load();
    _tabAktif = aktif;
  }

  Future<void> _load() async {
    try {
      final data = await widget.repository.getMyVisits();
      if (!mounted) return;
      setState(() {
        _visits = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _failed = false;
    });
    _load();
  }

  void _changeMonth(int delta) => setState(() {
        _month = DateTime(_month.year, _month.month + delta);
        _selected = null;
      });

  void _selectDay(DateTime day) => setState(() {
        if (_selected != null && isSameDay(_selected!, day)) {
          _selected = null;
        } else {
          _selected = dateOnly(day);
          _month = DateTime(day.year, day.month);
        }
      });

  void _toggleFilter(VisitTampilan s) =>
      setState(() => _filter = _filter == s ? null : s);

  void _showAll() => setState(() {
        _selected = null;
        _filter = null;
      });

  List<Visit> get _bulanIni => _visits
      .where((v) =>
          v.tanggal.year == _month.year && v.tanggal.month == _month.month)
      .toList();

  List<Visit> get _tampil {
    var list = _selected != null
        ? _visits.where((v) => isSameDay(v.tanggal, _selected!)).toList()
        : _bulanIni;
    if (_filter != null) {
      list = list.where((v) => v.tampilan == _filter).toList();
    }
    list.sort((a, b) => a.tanggal.compareTo(b.tanggal));
    return list;
  }

  Map<DateTime, Set<VisitTampilan>> get _statusPerHari {
    final peta = <DateTime, Set<VisitTampilan>>{};
    for (final v in _visits) {
      peta
          .putIfAbsent(dateOnly(v.tanggal), () => <VisitTampilan>{})
          .add(v.tampilan);
    }
    return peta;
  }

  Future<void> _open(Visit v) async {
    final hasil = await Navigator.of(context).push<Visit>(
      MaterialPageRoute(
        builder: (_) =>
            VisitDetailScreen(visit: v, repository: widget.repository),
      ),
    );
    if (hasil == null || !mounted) return;
    setState(() {
      _visits = [for (final x in _visits) x.id == hasil.id ? hasil : x];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(hasil.status == VisitStatus.visited
            ? 'Visit marked as done'
            : 'Visit marked as not visited'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    Text(
                      'Visit',
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    const Spacer(),
                    // Nama Sales yang login (seperti chip nama di layar Manager).
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 170),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                        decoration: BoxDecoration(
                          color: const Color(0x1AFFFFFF),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SalesAvatar(
                              sales: Sales(
                                id: 0,
                                nama: _nama ?? widget.salesName,
                              ),
                              size: 36,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _nama ?? widget.salesName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.red),
      );
    }
    if (_failed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Failed to load visits',
              style: GoogleFonts.poppins(color: AppColors.white),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _retry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    final bulan = _bulanIni;
    int hitung(VisitTampilan s) => bulan.where((v) => v.tampilan == s).length;
    final list = _tampil;
    final judul = _selected != null
        ? formatTanggal(_selected!)
        : 'All visits · ${namaBulan(_month.month)}';
    final adaFilter = _selected != null || _filter != null;

    // Halaman tidak bergulir. Ringkasan, kalender, dan judul tetap di tempat;
    // daftar ada di dalam kotak putih yang tingginya maksimal sekitar 3 baris.
    // Isi lebih dari itu bisa digulir di dalam kotak. Kalau hanya 1-2 kunjungan,
    // kotak pendek dan tidak bergulir.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              _TodayCard(
                visits: _visits,
                onOpen: _open,
                onShowToday: () => setState(() {
                  final h = dateOnly(DateTime.now());
                  _selected = h;
                  _month = DateTime(h.year, h.month);
                  _filter = null;
                }),
                onShowOverdue: () => setState(() {
                  final h = dateOnly(DateTime.now());
                  _selected = null;
                  _month = DateTime(h.year, h.month);
                  _filter = VisitTampilan.terlewat;
                }),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final s in VisitTampilan.values) ...[
                    if (s != VisitTampilan.values.first)
                      const SizedBox(width: 8),
                    Expanded(
                      child: _StatTile(
                        status: s,
                        jumlah: hitung(s),
                        dipilih: _filter == s,
                        onTap: () => _toggleFilter(s),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              VisitCalendar(
                month: _month,
                selected: _selected,
                statusPerHari: _statusPerHari,
                onPrevMonth: () => _changeMonth(-1),
                onNextMonth: () => _changeMonth(1),
                onSelect: _selectDay,
                cellHeight: 31,
                compact: true,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
          child: SizedBox(
            height: 26, // tetap, dengan atau tanpa tombol Show all
            child: Row(
            children: [
              Expanded(
                child: Text(
                  judul,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
              if (adaFilter)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _showAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.glass,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Show all',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          ),
        ),
        // Sisa layar (di atas navbar melayang). Kotak setinggi isinya, tapi
        // tidak lebih dari ~3 baris dan tidak lebih dari ruang yang tersedia.
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, _ruangNavbar),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: _tinggiMaks),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  clipBehavior: Clip.antiAlias,
                  child: list.isEmpty
                      ? SizedBox(
                          height: 86, // sama dengan kotak berisi satu kunjungan
                          child: Center(
                            child: Text(
                              'No visits',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF777777),
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: list.length,
                          separatorBuilder: (_, _) => const Divider(
                              height: 1, color: Color(0xFFECECEC)),
                          itemBuilder: (_, i) => _VisitRow(
                              visit: list[i], onTap: () => _open(list[i])),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Tinggi ruang navbar melayang di bagian bawah layar.
  static const double _ruangNavbar = 104;

  /// Tinggi maksimal kotak: 3 baris (tiap baris 78 px) + 2 garis + padding.
  static const double _tinggiMaks = 4 * 78 + 3 + 8;
}

class _VisitRow extends StatelessWidget {
  const _VisitRow({required this.visit, required this.onTap});

  final Visit visit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: const Color(0x14000000),
      highlightColor: const Color(0x0D000000),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${visit.tanggal.day}',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                      color: AppColors.black,
                    ),
                  ),
                  Text(
                    singkatBulan(visit.tanggal.month),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: const Color(0xFF777777),
                    ),
                  ),
                ],
              ),
            ),
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
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: AppColors.black,
                    ),
                  ),
                  Text(
                    formatTanggal(visit.tanggal),
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: const Color(0xFF777777),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            VisitStatusChipLight(status: visit.tampilan),
            const SizedBox(width: 8),
            // Tanda bahwa baris ini bisa diketuk.
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF1F1F1),
              ),
              child: const Icon(
                Icons.chevron_right,
                size: 18,
                color: Color(0xFF8A8A8A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.status,
    required this.jumlah,
    required this.dipilih,
    required this.onTap,
  });

  final VisitTampilan status;
  final int jumlah;
  final bool dipilih;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Material(
      color: ManagerColors.calendar,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: dipilih ? AppColors.red : Colors.white10,
          width: dipilih ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text(
                '$jumlah',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StatusDot(status: status),
                  const SizedBox(width: 6),
                  Text(
                    status.singkat,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _hariPendek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Kartu "Today": info toko yang harus dikunjungi hari ini. Ketuk: kalau tinggal
/// satu toko langsung buka detailnya, kalau lebih dari satu tampilkan daftar
/// hari ini. Pil "overdue" menyaring kunjungan yang terlewat.
class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.visits,
    required this.onOpen,
    required this.onShowToday,
    required this.onShowOverdue,
  });

  final List<Visit> visits;
  final ValueChanged<Visit> onOpen;
  final VoidCallback onShowToday;
  final VoidCallback onShowOverdue;

  @override
  Widget build(BuildContext context) {
    final hariIni = dateOnly(DateTime.now());
    final hariIniList =
        visits.where((v) => isSameDay(v.tanggal, hariIni)).toList();
    final sisa =
        hariIniList.where((v) => v.status == VisitStatus.scheduled).toList();
    final terlewat = visits
        .where((v) =>
            v.status == VisitStatus.scheduled && v.tanggal.isBefore(hariIni))
        .length;

    final Color titik;
    final String label;
    final Widget baris2;
    VoidCallback? onTap;

    if (hariIniList.isEmpty) {
      final berikut = visits
          .where((v) =>
              v.status == VisitStatus.scheduled && v.tanggal.isAfter(hariIni))
          .toList()
        ..sort((a, b) => a.tanggal.compareTo(b.tanggal));
      titik = Colors.white38;
      label = 'Today · No visits';
      if (berikut.isEmpty) {
        baris2 = const _Baris2Redup('No upcoming visits');
      } else {
        final d = berikut.first.tanggal;
        baris2 = _Baris2Redup(
          'Next: ${_hariPendek[d.weekday - 1]}, ${d.day} '
          '${namaBulan(d.month).substring(0, 3)} · ${berikut.first.tokoNama}',
        );
      }
      onTap = null;
    } else if (sisa.isEmpty) {
      titik = const Color(0xFF22C55E);
      label = 'Today · All done';
      baris2 = _Baris2Redup(
        '${hariIniList.length} of ${hariIniList.length} visits reported',
      );
      onTap = onShowToday;
    } else {
      titik = AppColors.red;
      label = hariIniList.length > sisa.length
          ? 'Today · ${sisa.length} of ${hariIniList.length} left'
          : 'Today · ${sisa.length} to visit';
      baris2 = Row(
        children: [
          Expanded(
            child: Text(
              sisa.first.tokoNama.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
          if (sisa.length > 1) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0x29FFFFFF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '+${sisa.length - 1} more',
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ],
      );
      onTap = sisa.length == 1 ? () => onOpen(sisa.first) : onShowToday;
    }

    return Material(
      color: const Color(0xFF565656),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Colors.white10),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0x3D000000),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _hariPendek[hariIni.weekday - 1].toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '${hariIni.day}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 18,
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: titik,
                              shape: BoxShape.circle,
                              boxShadow: titik == AppColors.red
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x47C80000),
                                        spreadRadius: 3,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              label.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.7,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          if (terlewat > 0)
                            InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: onShowOverdue,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0x59C80000),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '$terlewat overdue',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFFFD2D2),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20, child: baris2),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x24FFFFFF),
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Baris2Redup extends StatelessWidget {
  const _Baris2Redup(this.teks);

  final String teks;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        teks,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.white70),
      ),
    );
  }
}
