import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sfa_mobile/data/models/dashboard.dart';
import 'package:sfa_mobile/data/services/api_client.dart';
import 'package:sfa_mobile/data/services/dashboard_service.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/dashboard_widgets.dart';

/// Home Manager: gambaran keseluruhan (order, kunjungan, customer, stok).
class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  final _service = DashboardService();
  ManagerDashboard? _data;
  bool _loading = true;
  bool _failed = false;
  String _firstName = '';

  @override
  void initState() {
    super.initState();
    _load();
    ApiClient.instance.getProfile().then((p) {
      final first = p.name.trim().split(RegExp(r'\s+')).first;
      if (mounted) setState(() => _firstName = first);
    });
  }

  /// [silent]: muat ulang tanpa menutup konten yang sudah tampil.
  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }
    try {
      final d = await _service.fetchManager();
      if (!mounted) return;
      setState(() {
        _data = d;
        _loading = false;
        _failed = false;
      });
    } catch (e) {
      debugPrint('LOAD DASHBOARD ERROR: $e');
      if (e is DioException) {
        debugPrint('status: ${e.response?.statusCode} | ${e.response?.data}');
      }
      if (!mounted) return;
      setState(() {
        _failed = _data == null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _firstName.isEmpty ? '' : 'Halo, $_firstName · ';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DashHeader(
              title: 'Dashboard',
              subtitle: '$greeting${dateLabelId(DateTime.now())}',
              onMenu: () => showAppDrawer(context),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.red,
                onRefresh: () => _load(silent: true),
                child: _body(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    final d = _data;
    if (_loading && d == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.white),
      );
    }
    if (d == null || _failed) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 300,
            child: DashMessage(text: 'Gagal memuat dashboard', onRetry: _load),
          ),
        ],
      );
    }
    return _content(d);
  }

  Widget _content(ManagerDashboard d) {
    final month = monthLabelId(DateTime.now());
    final today = d.visitsToday;
    final vm = d.visitsMonth;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      // Ruang bawah supaya tidak tertutup navbar melayang.
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 110),
      children: [
        DashSection(title: 'Perlu tindakan', child: _pendingCard(d)),
        const SizedBox(height: 22),
        DashSection(
          title: 'Order · $month',
          child: Column(
            children: [
              DashTiles(
                children: [
                  DashStat(value: '${d.orders.pending}', label: 'Pending', dot: kWarn),
                  DashStat(value: '${d.orders.accepted}', label: 'Accepted', dot: kDone),
                  DashStat(value: '${d.orders.rejected}', label: 'Rejected', dot: kOverdue),
                  DashStat(value: '${d.orders.all}', label: 'Total'),
                ],
              ),
              const SizedBox(height: 10),
              _revenueCard(d.orders.revenue),
            ],
          ),
        ),
        const SizedBox(height: 22),
        DashSection(
          title: 'Kunjungan',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashLabel('Hari ini · ${today.total} kunjungan'),
              DashTiles(
                children: [
                  DashStat(value: '${today.done}', label: 'Done', dot: kDone),
                  DashStat(
                    value: '${today.pending}',
                    label: 'Pending',
                    dot: Colors.white,
                    hollow: true,
                  ),
                  DashStat(value: '${today.missed}', label: 'Missed', dot: kMissed),
                ],
              ),
              const SizedBox(height: 14),
              DashLabel('Bulan ini · $month'),
              DashTiles(
                children: [
                  DashStat(value: '${vm.done}', label: 'Done', dot: kDone),
                  DashStat(
                    value: '${vm.pending}',
                    label: 'Pending',
                    dot: Colors.white,
                    hollow: true,
                  ),
                  DashStat(value: '${vm.overdue}', label: 'Overdue', dot: kOverdue),
                  DashStat(value: '${vm.missed}', label: 'Missed', dot: kMissed),
                ],
              ),
              if (d.behindSales.isNotEmpty) ...[
                const SizedBox(height: 14),
                const DashLabel('Sales dengan kunjungan terlewat'),
                DashCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Column(
                    children: [for (final s in d.behindSales) _behindRow(s)],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        DashSection(
          title: 'Customer & stok',
          child: Column(
            children: [
              DashTiles(
                children: [
                  DashStat(value: '${d.customersTotal}', label: 'Customer'),
                  DashStat(value: '${d.salesTotal}', label: 'Sales aktif'),
                  DashStat(
                    value: '${d.customersUnassigned}',
                    label: 'Tanpa sales',
                    dot: d.customersUnassigned > 0 ? kWarn : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DashTiles(
                children: [
                  DashStat(
                    value: '${d.outOfStock}',
                    label: 'Stok habis',
                    dot: d.outOfStock > 0 ? kOverdue : null,
                  ),
                  DashStat(
                    value: '${d.nearExpiredBatches}',
                    label: 'Exp ≤ ${d.nearExpiryDays} hari',
                    dot: d.nearExpiredBatches > 0 ? kWarn : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pendingCard(ManagerDashboard d) {
    final more = d.pendingTotal - d.pendingList.length;

    return DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kWarn.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded, color: kWarn),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${d.pendingTotal}',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Order menunggu persetujuan',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (d.pendingList.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Semua order sudah diproses.',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white60),
              ),
            )
          else ...[
            const Divider(height: 24, color: Colors.white12),
            for (final o in d.pendingList) _pendingRow(o),
            if (more > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'dan $more order lainnya di tab Order',
                  style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.white54),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _pendingRow(PendingOrder o) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                o.customer,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
              Text(
                '${o.sales} · ${timeAgoId(o.createdAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.white60),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          rupiah(o.total),
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
      ],
    ),
  );

  Widget _revenueCard(int revenue) => DashCard(
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Omzet (order accepted)',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 2),
              Text(
                rupiah(revenue),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.payments_outlined, color: Colors.white54),
      ],
    ),
  );

  Widget _behindRow(BehindSales s) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            s.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: kOverdue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${s.overdue} terlewat',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFF8A80),
            ),
          ),
        ),
      ],
    ),
  );
}