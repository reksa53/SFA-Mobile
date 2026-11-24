import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sfa_mobile/data/models/dashboard.dart';
import 'package:sfa_mobile/data/services/api_client.dart';
import 'package:sfa_mobile/data/services/customer_service.dart';
import 'package:sfa_mobile/data/services/dashboard_service.dart';
import 'package:sfa_mobile/ui/manager/customer/customer_detail_screen.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/dashboard_widgets.dart';
import '../../core/widgets/styled_widgets.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka customer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final greeting = _firstName.isEmpty ? '' : 'Halo, $_firstName · ';

    return ThemedPage(
      child: Scaffold(
        backgroundColor: p.bg,
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
      ),
    );
  }

  Widget _body() {
    final d = _data;
    if (_loading && d == null) {
      return Center(child: CircularProgressIndicator(color: context.palette.text));
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
    final vm = d.visitsMonth;

    final blocks = <Widget>[
      _heroCard(d),
      StyledSection(
        icon: Icons.today_rounded,
        title: 'Kunjungan hari ini',
        child: _todayCard(d),
      ),
      StyledSection(
        icon: Icons.route_rounded,
        title: 'Kunjungan',
        trailing: month,
        child: DashTiles(
          children: [
            DashStat(value: '${vm.done}', label: 'Done', dot: kDone),
            DashStat(value: '${vm.pending}', label: 'Pending', hollow: true),
            DashStat(value: '${vm.overdue}', label: 'Overdue', dot: kOverdue),
            DashStat(value: '${vm.missed}', label: 'Missed', dot: kMissed),
          ],
        ),
      ),
      StyledSection(
        icon: Icons.receipt_long_rounded,
        title: 'Order',
        trailing: month,
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
      StyledSection(
        icon: Icons.notifications_active_rounded,
        title: 'Perlu follow-up',
        child: _inactiveCard(d),
      ),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 110),
      children: [
        for (var i = 0; i < blocks.length; i++)
          Reveal(
            index: i,
            child: Padding(
              padding: EdgeInsets.only(bottom: i == blocks.length - 1 ? 0 : 24),
              child: blocks[i],
            ),
          ),
      ],
    );
  }

  // ───────────────────────── Hero ─────────────────────────

  Widget _heroCard(SalesDashboard d) {
    final t = d.visitsToday;
    final int total = t.total;
    final int done = t.done;
    final double ratio = total > 0 ? (done / total).clamp(0.0, 1.0) : 0.0;
    final pct = (ratio * 100).round();
    final remaining = total - done;

    final String headline;
    if (total == 0) {
      headline = 'Tidak ada jadwal hari ini';
    } else if (remaining <= 0) {
      headline = 'Semua kunjungan selesai';
    } else {
      headline = '$remaining kunjungan tersisa';
    }

    return HeroShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: CircularProgressIndicator(
                        value: ratio,
                        strokeWidth: 7,
                        strokeCap: StrokeCap.round,
                        color: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kunjungan hari ini',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$done / $total selesai',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      headline,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _heroMetric('${d.customersTotal}', 'Customer saya'),
              _heroDivider(),
              _heroMetric('${d.orders.pending}', 'Order pending'),
              _heroDivider(),
              _heroMetric('${d.inactive.length}', 'Follow-up'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMetric(String value, String label) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.1,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );

  Widget _heroDivider() => Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 14),
        color: Colors.white.withValues(alpha: 0.22),
      );

  // ───────────────────────── Kunjungan hari ini ─────────────────────────

  Widget _todayCard(SalesDashboard d) {
    final p = context.palette;

    if (d.todayVisits.isEmpty) {
      return DashCard(
        child: Row(
          children: [
            Icon(Icons.event_available_rounded, color: p.textFaint, size: 20),
            const SizedBox(width: 10),
            Text(
              'Tidak ada kunjungan hari ini.',
              style: GoogleFonts.poppins(fontSize: 13, color: p.textFaint),
            ),
          ],
        ),
      );
    }

    final t = d.visitsToday;
    return DashCard(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SegmentBar(
              segments: [
                Seg(t.done, kDone),
                Seg(t.pending, p.textFaint.withValues(alpha: 0.45)),
                Seg(t.missed, kMissed),
              ],
            ),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < d.todayVisits.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 8,
                endIndent: 8,
                color: p.glassBorder.withValues(alpha: 0.6),
              ),
            _todayRow(d.todayVisits[i]),
          ],
        ],
      ),
    );
  }

  Widget _todayRow(TodayVisit v) {
    final p = context.palette;
    final (color, label) = switch (v.status) {
      'visited' => (kDone, 'Done'),
      'not_visited' => (kMissed, 'Missed'),
      _ => (p.textMuted, 'Pending'),
    };
    final address = v.customerAddress;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openCustomer(v.customerId),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            StyledAvatar(name: v.customerName, color: color),
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
                      color: p.text,
                    ),
                  ),
                  if (address != null && address.isNotEmpty)
                    Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 11, color: p.textFaint),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusChip(label: label, color: color),
            Icon(Icons.chevron_right, color: p.textGhost, size: 20),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Omzet ─────────────────────────

  Widget _revenueCard(int revenue) {
    final p = context.palette;

    return DashCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kDone.withValues(alpha: 0.28),
                  kDone.withValues(alpha: 0.10),
                ],
              ),
              border: Border.all(color: kDone.withValues(alpha: 0.30)),
            ),
            child: const Icon(Icons.payments_rounded, color: kDone),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Omzet (order accepted)',
                  style: GoogleFonts.poppins(fontSize: 12, color: p.textMuted),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    rupiah(revenue),
                    style: GoogleFonts.poppins(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: p.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Follow-up ─────────────────────────

  Widget _inactiveCard(SalesDashboard d) {
    final p = context.palette;

    if (d.inactive.isEmpty) {
      return DashCard(
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: kDone, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Semua customer sudah order dalam ${d.inactiveDays} hari terakhir.',
                style: GoogleFonts.poppins(fontSize: 13, color: p.textFaint),
              ),
            ),
          ],
        ),
      );
    }
    return DashCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < d.inactive.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 8,
                endIndent: 8,
                color: p.glassBorder.withValues(alpha: 0.6),
              ),
            _inactiveRow(d.inactive[i]),
          ],
        ],
      ),
    );
  }

  Widget _inactiveRow(dynamic c) {
    final p = context.palette;
    final int? days = c.daysSince;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openCustomer(c.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            StyledAvatar(name: c.name, color: kWarn),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                c.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: p.text,
                ),
              ),
            ),
            const SizedBox(width: 8),
            StatusChip(
              label: days == null ? 'Belum order' : '$days hari',
              color: kWarn,
            ),
            Icon(Icons.chevron_right, color: p.textGhost, size: 20),
          ],
        ),
      ),
    );
  }
}