import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/sales.dart';
import '../../../data/repositories/sales_visit_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/manager_header.dart';
import 'visit_screen.dart';

/// Tab "Sales & Visit" milik Manager: daftar sales.
/// Ketuk satu sales -> VisitScreen (kalender + daftar kunjungan).
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
  List<Sales> _sales = const [];
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

  Future<void> _load() async {
    try {
      final data = await widget.repository.getSales();
      if (!mounted) return;
      setState(() {
        _sales = data;
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

  List<Sales> get _shown {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _sales;
    return _sales.where((s) => s.nama.toLowerCase().contains(q)).toList();
  }

  void _open(Sales sales) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            VisitScreen(sales: sales, repository: widget.repository),
      ),
    );
  }

  void _addSales() {
    // TODO: tambah sales = register role staff dari modul Manager.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur tambah sales belum dibuat')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              searchHint: 'Cari sales...',
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Material(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  clipBehavior: Clip.antiAlias,
                  child: _buildList(),
                ),
              ),
            ),
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
                            horizontal: 8, vertical: 1),
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
              'Gagal memuat data sales',
              style: GoogleFonts.poppins(color: AppColors.black),
            ),
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
          'Sales tidak ditemukan',
          style: GoogleFonts.poppins(color: AppColors.black),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: list.length,
      itemBuilder: (_, i) =>
          _SalesRow(sales: list[i], onTap: () => _open(list[i])),
    );
  }
}

class _SalesRow extends StatelessWidget {
  const _SalesRow({required this.sales, required this.onTap});

  final Sales sales;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foto = sales.fotoUrl;
    final adaFoto = foto != null && foto.isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.grey,
              backgroundImage: adaFoto ? NetworkImage(foto) : null,
              child: adaFoto
                  ? null
                  : Text(
                      sales.inisial,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                sales.nama,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.black),
          ],
        ),
      ),
    );
  }
}
