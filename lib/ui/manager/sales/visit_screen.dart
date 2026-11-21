import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/sales.dart';
import '../../../data/models/visit.dart';
import '../../../data/repositories/sales_visit_repository.dart';
import '../../../data/services/sales_service.dart';
import '../../../utils/date_id.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/manager_colors.dart';
import 'edit_visit_screen.dart';
import 'sales_avatar.dart';
import 'visit_calendar.dart';
import '../../sales/visit/visit_status_chip.dart';
import 'visit_card.dart' show StatusDot;

/// Layar "Visit": ringkasan, kalender, dan daftar kunjungan satu sales.
class VisitScreen extends StatefulWidget {
  const VisitScreen({
    super.key,
    required this.sales,
    this.repository = const ApiSalesVisitRepository(),
    this.onVisitsChanged,
  });

  final Sales sales;
  final SalesVisitRepository repository;

  /// Dipanggil setelah Manager menyimpan perubahan jadwal di layar Edit.
  final ValueChanged<List<Visit>>? onVisitsChanged;

  @override
  State<VisitScreen> createState() => _VisitScreenState();
}

class _VisitScreenState extends State<VisitScreen> {
  late DateTime _month;
  DateTime? _selected; // null = tidak memilih hari tertentu
  VisitTampilan? _filter; // null = semua status
  List<Visit> _visits = const [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.repository.getVisits(widget.sales.id);
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
          _selected = null; // ketuk lagi = batal pilih
        } else {
          _selected = dateOnly(day);
          // hari dari bulan lain (di ujung kalender) -> pindah bulan
          _month = DateTime(day.year, day.month);
        }
      });

  void _toggleFilter(VisitTampilan s) =>
      setState(() => _filter = _filter == s ? null : s);

  void _tampilkanSemua() => setState(() {
        _selected = null;
        _filter = null;
      });

  List<Visit> get _bulanIni => _visits
      .where((v) => v.tanggal.year == _month.year && v.tanggal.month == _month.month)
      .toList();

  List<Visit> get _tampil {
    var list = _selected != null
        ? _visits.where((v) => isSameDay(v.tanggal, _selected!)).toList()
        : _bulanIni;
    if (_filter != null) {
      list = list.where((v) => v.tampilan == _filter).toList();
    }
    return list;
  }

  Map<DateTime, Set<VisitTampilan>> get _statusPerHari {
    final peta = <DateTime, Set<VisitTampilan>>{};
    for (final v in _visits) {
      peta.putIfAbsent(dateOnly(v.tanggal), () => <VisitTampilan>{}).add(v.tampilan);
    }
    return peta;
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  /// Pesan error dari server (422 / abort Laravel) kalau ada.
  String _pesanError(Object e, String cadangan) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
        }
        final pesan = data['message'];
        if (pesan is String && pesan.isNotEmpty) return pesan;
      }
      if (e.response == null) return 'Cannot reach the server';
    }
    return cadangan;
  }

  Future<void> _onEdit() async {
    // Daftar toko diambil dulu supaya dropdown di form berisi customer asli.
    final List<TokoPilihan> toko;
    try {
      toko = await widget.repository.getTokoPilihan();
    } catch (e) {
      if (!mounted) return;
      _pesan(_pesanError(e, 'Failed to load stores'));
      return;
    }
    if (!mounted) return;

    final hasil = await Navigator.of(context).push<List<Visit>>(
      MaterialPageRoute(
        builder: (_) => EditVisitScreen(
          sales: widget.sales,
          visits: _visits,
          toko: toko,
        ),
      ),
    );
    if (hasil == null || !mounted) return;

    try {
      final tersimpan = await widget.repository.saveVisits(
        widget.sales.id,
        _visits,
        hasil,
      );
      if (!mounted) return;
      setState(() => _visits = tersimpan);
      widget.onVisitsChanged?.call(tersimpan);
      _pesan('Visit schedule saved');
    } catch (e) {
      if (!mounted) return;
      _pesan(_pesanError(e, 'Failed to save schedule'));
      _load(); // sinkronkan lagi dengan isi server
    }
  }

  /// Hapus (nonaktifkan) sales ini setelah konfirmasi, lalu kembali ke daftar.
  Future<void> _hapusSales() async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF565656),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete sales?',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        content: Text(
          '${widget.sales.nama} will be removed and can no longer log in. '
          'Their stores become unassigned and upcoming scheduled visits are '
          'deleted. Past visit history is kept.',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: AppColors.white,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (ya != true || !mounted) return;

    try {
      await SalesService().delete(widget.sales.id);
      if (!mounted) return;
      _pesan('${widget.sales.nama} deleted');
      Navigator.of(context).pop(); // daftar sales memuat ulang saat tampil lagi
    } catch (e) {
      if (!mounted) return;
      _pesan(_pesanError(e, 'Failed to delete sales'));
    }
  }

  /// Detail kunjungan (hanya baca): toko, alamat, tanggal, status, catatan.
  void _detail(Visit v) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF565656),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => _VisitInfoSheet(visit: v),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(sales: widget.sales, onDelete: _hapusSales),
            Expanded(child: _buildBody()),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _loading || _failed ? null : _onEdit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.red,
                    foregroundColor: AppColors.white,
                    minimumSize: Size.zero,
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text(
                    'EDIT',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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

    // Halaman tetap. Ringkasan, kalender, dan judul tidak bergulir; daftar ada
    // di kotak putih setinggi maksimal 3 baris. Lebih dari itu bisa digulir di
    // dalam kotak. Kalau hanya 1-2 kunjungan, kotak pendek dan tidak bergulir.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
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
                cellHeight: 38,
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
                    onTap: _tampilkanSemua,
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
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
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
                              visit: list[i], onTap: () => _detail(list[i])),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Tinggi maksimal kotak: 3 baris (tiap baris 78 px) + 2 garis + padding.
  static const double _tinggiMaks = 4 * 78 + 3 + 8;
}

/// Satu baris kunjungan di dalam kotak putih.
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

/// Lembar detail kunjungan untuk Manager (hanya baca).
class _VisitInfoSheet extends StatelessWidget {
  const _VisitInfoSheet({required this.visit});

  final Visit visit;

  @override
  Widget build(BuildContext context) {
    final label = GoogleFonts.poppins(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: Colors.white70,
    );
    final catatan = visit.catatan.trim();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              visit.tokoNama.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                height: 1.25,
                color: AppColors.white,
              ),
            ),
            if (visit.alamat.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(Icons.location_on_outlined,
                        size: 17, color: Colors.white60),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      visit.alamat,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 17, color: Colors.white60),
                const SizedBox(width: 8),
                Text(
                  formatTanggal(visit.tanggal),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            VisitStatusChipDark(status: visit.tampilan),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: Colors.white12),
            ),
            Text('Notes from Sales', style: label),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF3F3F3F),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                catatan.isEmpty ? '—' : catatan,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.sales, required this.onDelete});

  final Sales sales;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Material(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(context).pop(),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.chevron_left,
                      size: 28, color: AppColors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Visit',
              style: GoogleFonts.poppins(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            const Spacer(),
            Flexible(
              child: ConstrainedBox(
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
                    SalesAvatar(sales: sales, size: 36),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        sales.nama,
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
            ),
            const SizedBox(width: 8),
            Material(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onDelete,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.delete_outline,
                      size: 24, color: AppColors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kotak ringkasan: jumlah kunjungan per status bulan ini. Ketuk = filter.
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
