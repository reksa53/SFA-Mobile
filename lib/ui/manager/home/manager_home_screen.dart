import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sfa_mobile/data/models/dashboard.dart';
import 'package:sfa_mobile/data/services/api_client.dart';
import 'package:sfa_mobile/data/services/dashboard_service.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
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

    final blocks = <Widget>[
      _heroCard(d, month),
      _Section(
        icon: Icons.bolt_rounded,
        title: 'Perlu tindakan',
        child: _pendingCard(d),
      ),
      _Section(
        icon: Icons.receipt_long_rounded,
        title: 'Order',
        trailing: month,
        child: DashTiles(
          children: [
            DashStat(value: '${d.orders.pending}', label: 'Pending', dot: kWarn),
            DashStat(value: '${d.orders.accepted}', label: 'Accepted', dot: kDone),
            DashStat(value: '${d.orders.rejected}', label: 'Rejected', dot: kOverdue),
            DashStat(value: '${d.orders.all}', label: 'Total'),
          ],
        ),
      ),
      _Section(
        icon: Icons.route_rounded,
        title: 'Kunjungan',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _todayVisitCard(today),
            const SizedBox(height: 14),
            DashLabel('Bulan ini · $month'),
            DashTiles(
              children: [
                DashStat(value: '${vm.done}', label: 'Done', dot: kDone),
                DashStat(value: '${vm.pending}', label: 'Pending', hollow: true),
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
                  children: [
                    for (var i = 0; i < d.behindSales.length; i++) ...[
                      if (i > 0) _hairline(),
                      _behindRow(d.behindSales[i]),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      _Section(
        icon: Icons.inventory_2_rounded,
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
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      // Ruang bawah supaya tidak tertutup navbar melayang.
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 110),
      children: [
        for (var i = 0; i < blocks.length; i++)
          _Reveal(
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

  Widget _heroCard(ManagerDashboard d, String month) {
    final o = d.orders;
    final rate = o.all > 0 ? (o.accepted / o.all * 100).round() : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE53935), Color(0xFF7F0F14)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.red.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Lingkaran dekoratif halus.
          Positioned(
            right: -40,
            top: -50,
            child: _circle(150, 0.08),
          ),
          Positioned(
            right: 30,
            bottom: -60,
            child: _circle(110, 0.06),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.payments_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Omzet · $month',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  _heroPill('$rate% accepted'),
                ],
              ),
              const SizedBox(height: 16),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  rupiah(o.revenue),
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'dari order yang sudah di-accept',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _heroMetric('${o.all}', 'Order'),
                  _heroDivider(),
                  _heroMetric('${o.accepted}', 'Accepted'),
                  _heroDivider(),
                  _heroMetric('${o.pending}', 'Pending'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      );

  Widget _heroPill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );

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

  Widget _todayVisitCard(dynamic today) {
    final p = context.palette;
    final int total = today.total;
    final int done = today.done;
    final int pend = today.pending;
    final int missed = today.missed;
    final pct = total > 0 ? (done / total * 100).round() : 0;

    return DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hari ini',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: p.textMuted,
                      ),
                    ),
                    Text(
                      '$total kunjungan',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$pct%',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: kDone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SegmentBar(
            segments: [
              _Seg(done, kDone),
              _Seg(pend, p.textFaint.withValues(alpha: 0.45)),
              _Seg(missed, kMissed),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _legend('Done', done, kDone),
              _legend('Pending', pend, p.textFaint),
              _legend('Missed', missed, kMissed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(String label, int value, Color color) {
    final p = context.palette;
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$label $value',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 11.5, color: p.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Perlu tindakan ─────────────────────────

  Widget _pendingCard(ManagerDashboard d) {
    final p = context.palette;
    final more = d.pendingTotal - d.pendingList.length;

    return DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      kWarn.withValues(alpha: 0.30),
                      kWarn.withValues(alpha: 0.12),
                    ],
                  ),
                  border: Border.all(color: kWarn.withValues(alpha: 0.35)),
                ),
                child: const Icon(Icons.hourglass_top_rounded, color: kWarn),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${d.pendingTotal}',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Order menunggu persetujuan',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: p.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (d.pendingList.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: kDone, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Semua order sudah diproses.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: p.textFaint,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Divider(height: 28, color: p.glassBorder),
            for (var i = 0; i < d.pendingList.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _pendingRow(d.pendingList[i]),
            ],
            if (more > 0)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: p.glassBorder.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+ $more order lainnya di tab Order',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: p.textMuted,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _pendingRow(PendingOrder o) {
    final p = context.palette;

    return Row(
      children: [
        _Avatar(name: o.customer, color: kWarn),
        const SizedBox(width: 12),
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
                  color: p.text,
                ),
              ),
              Text(
                '${o.sales} · ${timeAgoId(o.createdAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 11, color: p.textFaint),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          rupiah(o.total),
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: p.text,
          ),
        ),
      ],
    );
  }

  // ───────────────────────── Sales terlewat ─────────────────────────

  Widget _hairline() => Divider(
        height: 1,
        thickness: 1,
        color: context.palette.glassBorder.withValues(alpha: 0.6),
      );

  Widget _behindRow(BehindSales s) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _Avatar(name: s.name, color: kOverdue, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              s.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: p.text,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: kOverdue.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kOverdue.withValues(alpha: 0.30)),
            ),
            child: Text(
              '${s.overdue} terlewat',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: p.isDark
                    ? const Color(0xFFFF8A80)
                    : const Color(0xFFC62828),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════ Reusable pieces ═════════════════════════

/// Judul section: aksen vertikal + ikon + judul (+ keterangan di kanan).
class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 18, color: p.textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: p.text,
                ),
              ),
            ),
            if (trailing != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: p.glassBorder.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  trailing!,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: p.textMuted,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

/// Avatar inisial berwarna lembut.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.color, this.size = 38});

  final String name;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        initial,
        style: GoogleFonts.poppins(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _Seg {
  const _Seg(this.value, this.color);
  final int value;
  final Color color;
}

/// Bar proporsi bersegmen (done / pending / missed).
class _SegmentBar extends StatelessWidget {
  const _SegmentBar({required this.segments});

  final List<_Seg> segments;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final active = segments.where((s) => s.value > 0).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 8,
        child: active.isEmpty
            ? ColoredBox(color: p.glassBorder.withValues(alpha: 0.5))
            : Row(
                children: [
                  for (var i = 0; i < active.length; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      flex: active[i].value,
                      child: ColoredBox(color: active[i].color),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Animasi masuk bertahap (fade + geser halus) per blok.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (_, t, c) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 18), child: c),
      ),
      child: child,
    );
  }
}