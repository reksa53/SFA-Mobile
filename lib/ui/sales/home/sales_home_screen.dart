import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sfa_mobile/data/models/dashboard.dart';
import 'package:sfa_mobile/data/services/api_client.dart';
import 'package:sfa_mobile/data/services/customer_service.dart';
import 'package:sfa_mobile/data/services/dashboard_service.dart';
import 'package:sfa_mobile/ui/manager/customer/customer_detail_screen.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/dashboard_widgets.dart';

/// Home Sales: ringkasan khusus customer yang ditugaskan ke sales ini.
class SalesHomeScreen extends StatefulWidget {
  const SalesHomeScreen({super.key});

  @override
  State<SalesHomeScreen> createState() => _SalesHomeScreenState();
}

class _SalesHomeScreenState extends State<SalesHomeScreen> {
  final _service = DashboardService();
  SalesDashboard? _data;
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

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }
    try {
      final d = await _service.fetchSales();
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

  /// Buka detail customer (read-only untuk sales).
  Future<void> _openCustomer(int? id) async {
    if (id == null) return;
    try {
      final store = await CustomerService().fetchOne(id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CustomerDetailScreen(store: store, canEdit: false),
        ),
      );
      if (mounted) _load(silent: true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal membuka customer')));
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
              title: 'Home',
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
            child: DashMessage(text: 'Gagal memuat data', onRetry: _load),
          ),
        ],
      );
    }
    return _content(d);
  }

  Widget _content(SalesDashboard d) {
    final month = monthLabelId(DateTime.now());
    final today = d.visitsToday;
    final vm = d.visitsMonth;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 110),
      children: [
        DashTiles(
          children: [
            DashStat(value: '${d.customersTotal}', label: 'Customer saya'),
            DashStat(
              value: '${today.done}/${today.total}',
              label: 'Visit hari ini',
              dot: kDone,
            ),
          ],
        ),
        const SizedBox(height: 22),
        DashSection(title: 'Kunjungan hari ini', child: _todayCard(d)),
        const SizedBox(height: 22),
        DashSection(
          title: 'Kunjungan · $month',
          child: DashTiles(
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
        ),
        const SizedBox(height: 22),
        DashSection(
          title: 'Order · $month',
          child: Column(
            children: [
              DashTiles(
                children: [
                  DashStat(
                    value: '${d.orders.pending}',
                    label: 'Pending',
                    dot: kWarn,
                  ),
                  DashStat(
                    value: '${d.orders.accepted}',
                    label: 'Accepted',
                    dot: kDone,
                  ),
                  DashStat(
                    value: '${d.orders.rejected}',
                    label: 'Rejected',
                    dot: kOverdue,
                  ),
                  DashStat(value: '${d.orders.all}', label: 'Total'),
                ],
              ),
              const SizedBox(height: 10),
              DashCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Omzet (order accepted)',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rupiah(d.orders.revenue),
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
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        DashSection(title: 'Perlu follow-up', child: _inactiveCard(d)),
      ],
    );
  }

  Widget _todayCard(SalesDashboard d) {
    if (d.todayVisits.isEmpty) {
      return DashCard(
        child: Text(
          'Tidak ada kunjungan hari ini.',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.white60),
        ),
      );
    }
    return DashCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Column(children: [for (final v in d.todayVisits) _todayRow(v)]),
    );
  }

  Widget _todayRow(TodayVisit v) {
    final (color, hollow, label) = switch (v.status) {
      'visited' => (kDone, false, 'Done'),
      'not_visited' => (kMissed, false, 'Missed'),
      _ => (Colors.white, true, 'Pending'),
    };
    final address = v.customerAddress;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openCustomer(v.customerId),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            DashDot(color: color, hollow: hollow),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                  if (address != null && address.isNotEmpty)
                    Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white60,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.white70),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _inactiveCard(SalesDashboard d) {
    if (d.inactive.isEmpty) {
      return DashCard(
        child: Text(
          'Semua customer sudah order dalam ${d.inactiveDays} hari terakhir.',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.white60),
        ),
      );
    }
    return DashCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Column(
        children: [
          for (final c in d.inactive)
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openCustomer(c.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                          Text(
                            c.daysSince == null
                                ? 'Belum pernah order'
                                : '${c.daysSince} hari tidak order',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: kWarn,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white38,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
