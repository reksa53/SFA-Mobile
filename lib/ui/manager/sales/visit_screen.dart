import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/sales.dart';
import '../../../data/models/visit.dart';
import '../../../data/repositories/sales_visit_repository.dart';
import '../../../utils/date_id.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/manager_colors.dart';
import '../../core/widgets/manager_header.dart';
import 'visit_calendar.dart';
import 'visit_card.dart';
import 'edit_visit_screen.dart';

/// Layar "Visit": kalender + daftar kunjungan satu sales.
/// Dibuka dari SalesVisitScreen dan menutupi navbar (sesuai Figma).
class VisitScreen extends StatefulWidget {
  const VisitScreen({
    super.key,
    required this.sales,
    this.repository = const DummySalesVisitRepository(),
  });

  final Sales sales;
  final SalesVisitRepository repository;

  @override
  State<VisitScreen> createState() => _VisitScreenState();
}

class _VisitScreenState extends State<VisitScreen> {
  late DateTime _month;
  DateTime? _selected; // null = tampilkan semua kunjungan
  List<Visit> _visits = const [];
  bool _loading = true;
  bool _failed = false;
  bool _searching = false;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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

  void _toggleSearch() => setState(() {
        _searching = !_searching;
        if (!_searching) _search.clear();
      });

  void _changeMonth(int delta) => setState(() {
        _month = DateTime(_month.year, _month.month + delta);
        _selected = null;
      });

  void _selectDay(DateTime day) => setState(() {
        if (_selected != null && isSameDay(_selected!, day)) {
          _selected = null; // ketuk lagi = batal pilih
        } else {
          _selected = day;
          // hari dari bulan lain (di ujung kalender) -> pindah bulan
          _month = DateTime(day.year, day.month);
        }
      });

  List<Visit> get _shown {
    var list = _visits;
    final day = _selected;
    if (day != null) {
      list = list.where((v) => isSameDay(v.tanggal, day)).toList();
    }
    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((v) => v.tokoNama.toLowerCase().contains(q)).toList();
    }
    return list;
  }

    Future<void> _onEdit() async {
    final hasil = await Navigator.of(context).push<List<Visit>>(
      MaterialPageRoute(
        builder: (_) =>
            EditVisitScreen(sales: widget.sales, visits: _visits),
      ),
    );
    if (hasil == null || !mounted) return;
    // TODO: kirim perubahan ke API; sementara hanya disimpan di layar.
    setState(() => _visits = hasil);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Jadwal kunjungan disimpan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final marked = {for (final v in _visits) dateOnly(v.tanggal)};

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ManagerHeader(
              title: 'Visit',
              searchOpen: _searching,
              searchController: _search,
              onSearchToggle: _toggleSearch,
              onSearchChanged: (_) => setState(() {}),
              searchHint: 'Cari toko...',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: VisitCalendar(
                month: _month,
                selected: _selected,
                markedDays: marked,
                onPrevMonth: () => _changeMonth(-1),
                onNextMonth: () => _changeMonth(1),
                onSelect: _selectDay,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildList()),
            _BottomBar(
              onBack: () => Navigator.of(context).maybePop(),
              onEdit: _onEdit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    const putih = TextStyle(color: AppColors.white);

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
            const Text('Gagal memuat data kunjungan', style: putih),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _retry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }
    final list = _shown;
    if (list.isEmpty) {
      return Center(
        child: Text(
          _selected == null
              ? 'Belum ada kunjungan'
              : 'Tidak ada kunjungan pada ${formatTanggal(_selected!)}',
          style: putih,
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => VisitCard(visit: list[i]),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.onBack, required this.onEdit});

  final VoidCallback onBack;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onBack,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chevron_left,
                      size: 24, color: AppColors.white),
                  Text(
                    'back',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 183,
            height: 40,
            child: FilledButton(
              onPressed: onEdit,
              style: FilledButton.styleFrom(
                backgroundColor: ManagerColors.editButton,
                foregroundColor: AppColors.white,
                shape: const StadiumBorder(),
              ),
              child: Text(
                'Edit',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
