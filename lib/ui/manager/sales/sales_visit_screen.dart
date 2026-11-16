import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sfa_mobile/data/services/sales_service.dart';

import '../../../data/models/sales.dart';
import '../../../data/models/visit.dart';
import '../../../data/repositories/sales_visit_repository.dart';
import '../../../utils/date_id.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/manager_header.dart';
import 'add_sales_screen.dart';
import 'sales_avatar.dart';
import 'visit_screen.dart';

/// Ringkasan kunjungan satu sales pada bulan berjalan.
class _Ringkasan {
  const _Ringkasan({required this.total, required this.selesai});

  final int total;
  final int selesai;

  double get persen => total == 0 ? 0 : selesai / total;
}

/// Tab "Sales & Visit" milik Manager: daftar sales beserta progres kunjungan
/// bulan ini. Ketuk satu sales -> VisitScreen.
///
/// Daftar sales diambil dari API (GET /sales). Data kunjungan masih lewat
/// repository.
class SalesVisitScreen extends StatefulWidget {
  const SalesVisitScreen({
    super.key,
    this.repository = const DummySalesVisitRepository(),
  });

  final SalesVisitRepository repository;

  @override
  State<SalesVisitScreen> createState() => _SalesVisitScreenState();
}

class _SalesVisitScreenState extends State<SalesVisitScreen> {
  final _salesService = SalesService();
  List<Sales> _sales = const [];
  final Map<int, _Ringkasan> _ringkasan = {};
  bool _loading = true;
  bool _failed = false;
  bool _searching = false;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  _Ringkasan _hitung(List<Visit> visits) {
    final now = DateTime.now();
    final bulan = visits
        .where(
          (v) => v.tanggal.year == now.year && v.tanggal.month == now.month,
        )
        .toList();
    final selesai = bulan.where((v) => v.status == VisitStatus.visited).length;
    return _Ringkasan(total: bulan.length, selesai: selesai);
  }

  /// Kunjungan satu sales. Kalau gagal, anggap kosong supaya daftar sales
  /// tetap tampil (kunjungan belum terhubung ke API).
  Future<List<Visit>> _visitsOf(int salesId) async {
    try {
      return await widget.repository.getVisits(salesId);
    } catch (_) {
      return const <Visit>[];
    }
  }

  Future<void> _load() async {
    try {
      final data = await _salesService.fetchAll();
      final hasil = await Future.wait(data.map((s) => _visitsOf(s.id)));
      if (!mounted) return;
      setState(() {
        _sales = data;
        _ringkasan
          ..clear()
          ..addEntries([
            for (var i = 0; i < data.length; i++)
              MapEntry(data[i].id, _hitung(hasil[i])),
          ]);
        _loading = false;
        _failed = false;
      });
    } catch (e) {
      debugPrint('LOAD SALES ERROR: $e');
      if (e is DioException) {
        debugPrint(
          'status: ${e.response?.statusCode} | body: ${e.response?.data}',
        );
      }
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

  List<Sales> get _shown {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _sales;
    return _sales.where((s) => s.nama.toLowerCase().contains(q)).toList();
  }

  void _open(Sales sales) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VisitScreen(
          sales: sales,
          repository: widget.repository,
          onVisitsChanged: (visits) =>
              setState(() => _ringkasan[sales.id] = _hitung(visits)),
        ),
      ),
    );
  }

  Future<void> _addSales() async {
    final baru = await Navigator.of(context).push<Sales>(
      MaterialPageRoute(builder: (_) => const AddSalesScreen()),
    );
    if (baru == null || !mounted) return;
    // Ambil ulang dari server supaya daftar selalu sama dengan database.
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${baru.nama} added')));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // SafeArea ikut menyisakan ruang untuk navbar melayang (extendBody di
    // TabShell), jadi footer berhenti tepat di atas navbar.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ManagerHeader(
              title: 'Sales & Visit',
              searchOpen: _searching,
              searchController: _search,
              onSearchToggle: _toggleSearch,
              onSearchChanged: (_) => setState(() {}),
              searchHint: 'Search sales...',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_sales.length} sales · ${namaBulan(now.month)} ${now.year}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
            Expanded(child: _buildList()),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'All Sales',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.glass,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_sales.length}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 32,
                    child: FilledButton(
                      onPressed: _addSales,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.red,
                        foregroundColor: AppColors.white,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: const StadiumBorder(),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Add Sales',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.add_circle, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
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
              'Failed to load sales',
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
    final list = _shown;
    if (list.isEmpty) {
      return Center(
        child: Text(
          _sales.isEmpty ? 'No sales yet' : 'No sales found',
          style: GoogleFonts.poppins(color: AppColors.white),
        ),
      );
    }
    // Daftar berada di satu kotak putih, sama seperti tab Customer, Product,
    // dan Order. Align + shrinkWrap: kotak setinggi isinya kalau sales sedikit,
    // dan berhenti di atas footer (lalu isinya bisa digulir) kalau sales banyak.
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        child: Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: RefreshIndicator(
            color: AppColors.red,
            onRefresh: _load,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFECECEC),
              ),
              itemBuilder: (_, i) => _SalesRow(
                sales: list[i],
                ringkasan:
                    _ringkasan[list[i].id] ??
                    const _Ringkasan(total: 0, selesai: 0),
                onTap: () => _open(list[i]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Satu baris sales di dalam kotak putih.
class _SalesRow extends StatelessWidget {
  const _SalesRow({
    required this.sales,
    required this.ringkasan,
    required this.onTap,
  });

  final Sales sales;
  final _Ringkasan ringkasan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kosong = ringkasan.total == 0;
    const abu = Color(0xFF777777);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            SalesAvatar(sales: sales, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sales.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          kosong
                              ? 'No visits this month'
                              : '${ringkasan.total} visits this month',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: abu,
                          ),
                        ),
                      ),
                      if (!kosong)
                        Text(
                          '${ringkasan.selesai}/${ringkasan.total} done',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: abu,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: ringkasan.persen,
                      minHeight: 5,
                      color: AppColors.red,
                      backgroundColor: const Color(0xFFE6E6E6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Color(0xFFB5B5B5)),
          ],
        ),
      ),
    );
  }
}