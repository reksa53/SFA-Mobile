import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sfa_mobile/data/models/customer_visit.dart';
import 'package:sfa_mobile/data/models/sales.dart';
import 'package:sfa_mobile/data/services/customer_service.dart';
import 'package:sfa_mobile/data/services/sales_service.dart';
import 'package:sfa_mobile/data/models/order.dart';
import 'package:sfa_mobile/data/services/order_service.dart';

import '../../core/theme/app_colors.dart';
import 'customer_list_screen.dart';
import 'customer_style.dart';

const _months = _monthsEn;

const _monthsEn = [
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

String _fmtLong(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';
String _fmtDate(DateTime d) => '${d.day} - ${_months[d.month - 1]} - ${d.year}';
String _pad2(int n) => n.toString().padLeft(2, '0');
String _rupiah(num v) {
  final s = v.round().abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return 'Rp $b';
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

const _colorScheduled = Color(0xFF3B82F6);
const _colorOverdue = Color(0xFFF59E0B);
const _colorVisited = Color(0xFF2ECC40);
const _colorNotVisited = Color(0xFFE53935);

String _statusLabel(CustomerVisit v) => switch (v.status) {
  CustomerVisitStatus.visited => 'Visited',
  CustomerVisitStatus.notVisited => 'Not visited',
  CustomerVisitStatus.scheduled => v.isOverdue ? 'Overdue' : 'Scheduled',
};

Color _statusColor(CustomerVisit v) => switch (v.status) {
  CustomerVisitStatus.visited => _colorVisited,
  CustomerVisitStatus.notVisited => _colorNotVisited,
  CustomerVisitStatus.scheduled =>
    v.isOverdue ? _colorOverdue : _colorScheduled,
};

const _cardBg = kCustPanel;

BoxDecoration _cardDeco(double radius) => BoxDecoration(
  color: _cardBg,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: const Color(0x1FFFFFFF)),
);

/// Tombol kotak kecil (back & panah kalender).
class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.icon,
    required this.onTap,
    this.size = 38,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF5A5A5A),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({
    super.key,
    required this.store,
    this.canEdit = true,
  });

  final CustomerStore store;
  final bool canEdit;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
    final _service = CustomerService();
  final _orderService = OrderService();
  List<Order> _orders = const [];
  bool _loadingOrders = true;
  bool _ordersFailed = false;

  late CustomerStore _store = widget.store;
  List<CustomerVisit> _visits = const [];
  bool _loadingVisits = true;
  bool _visitsFailed = false;

  /// True kalau data customer mungkin berubah, supaya daftar di layar
  /// sebelumnya dimuat ulang.
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _loadVisits();
    _loadOrders();
  }

  Future<void> _loadVisits() async {
    final id = _store.id;
    if (id == null) {
      setState(() => _loadingVisits = false);
      return;
    }
    setState(() {
      _loadingVisits = true;
      _visitsFailed = false;
    });
    try {
      final data = await _service.fetchVisits(id);
      if (!mounted) return;
      setState(() {
        _visits = data;
        _loadingVisits = false;
      });
    } catch (e) {
      debugPrint('LOAD VISITS ERROR: $e');
      if (e is DioException) {
        debugPrint('status: ${e.response?.statusCode} | ${e.response?.data}');
      }
      if (!mounted) return;
      setState(() {
        _visitsFailed = true;
        _loadingVisits = false;
      });
    }
  }

  Future<void> _refresh() async {
    final id = _store.id;
    if (id == null) return;
    try {
      final fresh = await _service.fetchOne(id);
      if (mounted) setState(() => _store = fresh);
    } catch (_) {
      // header tetap memakai data lama
    }
    await _loadVisits();
  }

  Future<void> _loadOrders() async {
    final id = _store.id;
    if (id == null) {
      setState(() => _loadingOrders = false);
      return;
    }
    setState(() {
      _loadingOrders = true;
      _ordersFailed = false;
    });
    try {
      final res = await _orderService.fetch(
        status: 'accepted',
        customerId: id,
        perPage: 50,
      );
      if (!mounted) return;
      setState(() {
        _orders = res.orders;
        _loadingOrders = false;
      });
    } catch (e) {
      debugPrint('LOAD ORDERS ERROR: $e');
      if (e is DioException) {
        debugPrint('status: ${e.response?.statusCode} | ${e.response?.data}');
      }
      if (!mounted) return;
      setState(() {
        _ordersFailed = true;
        _loadingOrders = false;
      });
    }
  }

  List<Widget> _orderWidgets() {
    const white = TextStyle(color: AppColors.white);
    if (_loadingOrders) {
      return const [
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.white),
          ),
        ),
      ];
    }
    if (_ordersFailed) {
      return [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                const Text('Failed to load order history', style: white),
                TextButton(
                  onPressed: _loadOrders,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    if (_orders.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No orders yet', style: white)),
        ),
      ];
    }
    return [
      for (final o in _orders)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _OrderTile(order: o, onDetail: () => _showInvoice(o)),
        ),
    ];
  }

  /// Popup invoice untuk satu order.
  void _showInvoice(Order o) {
    showCustDialog<void>(
      context: context,
      title: o.invoice ?? 'Order #${o.id}',
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              o.createdAt == null ? '-' : _fmtLong(o.createdAt!),
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
            ),
            const Divider(height: 20, color: Colors.white24),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: o.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final it = o.items[i];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              it.productName,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                            Text(
                              '${it.quantity} x ${_rupiah(it.unitPrice)}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _rupiah(it.unitPrice * it.quantity),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 20, color: Colors.white24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
                Text(
                  _rupiah(o.total),
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        Builder(
          builder: (ctx) =>
              custDialogAction('Close', () => Navigator.pop(ctx)),
        ),
      ],
    );
  }

  /// Popup detail kunjungan pada tanggal yang diketuk.
  void _showDay(DateTime day, List<CustomerVisit> list) {
    showCustDialog<void>(
      context: context,
      title: _fmtLong(day),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [for (final v in list) _VisitDetailCard(visit: v)],
        ),
      ),
      actions: [
        Builder(
          builder: (ctx) =>
              custDialogAction('Close', () => Navigator.pop(ctx)),
        ),
      ],
    );
  }

  Future<void> _openEdit() async {
    if (_store.id == null) return;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: kCustPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => _EditCustomerSheet(store: _store, visits: _visits),
    );
    if (!mounted) return;

    if (result == 'deleted') {
      Navigator.of(context).pop(true); // keluar dari detail, list reload
      return;
    }

    // Apa pun hasilnya (berhasil / sebagian gagal), ambil ulang dari server.
    _changed = true;
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    _SquareButton(
                      icon: Icons.chevron_left,
                      size: 42,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Customer',
                      style: GoogleFonts.poppins(
                        color: AppColors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _refresh();
                    await _loadOrders();
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      _InfoCard(store: _store),
                      const SizedBox(height: 12),
                      _StatsRow(visits: _visits),
                      const SizedBox(height: 12),
                      _CalendarCard(
                        visits: _visits,
                        loading: _loadingVisits,
                        failed: _visitsFailed,
                        onRetry: _loadVisits,
                        onDayTap: _showDay,
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Order History',
                        style: GoogleFonts.poppins(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._orderWidgets(),
                    ],
                  ),
                ),
              ),
              if (widget.canEdit)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _openEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(
                        'EDIT CUSTOMER',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.red,
                        foregroundColor: AppColors.white,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Kartu info ─────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.store});

  final CustomerStore store;

  Widget _meta(IconData icon, String text, {int maxLines = 1}) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.white54),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ),
      ],
    ),
  );

  Widget _chip(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0x14FFFFFF),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final photo = store.photoUrl;
    final owner = store.ownerName.isEmpty ? '-' : store.ownerName;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 64,
                  height: 64,
                  color: kCustField,
                  child: (photo == null || photo.isEmpty)
                      ? const Icon(
                          Icons.storefront_outlined,
                          color: Colors.white54,
                          size: 28,
                        )
                      : Image.network(
                          photo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.storefront_outlined,
                            color: Colors.white54,
                            size: 28,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.storeName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    _meta(Icons.person_outline, owner),
                    if (store.phone.isNotEmpty)
                      _meta(Icons.phone_outlined, store.phone),
                    _meta(
                      Icons.location_on_outlined,
                      store.address,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(Icons.badge_outlined, 'Sales: ${store.salesName ?? '-'}'),
              _chip(
                Icons.event_repeat_outlined,
                customerDayName(store.visitDay),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Statistik ─────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.visits});

  final List<CustomerVisit> visits;

  @override
  Widget build(BuildContext context) {
    final done = visits
        .where((v) => v.status == CustomerVisitStatus.visited)
        .length;
    final missed = visits
        .where((v) => v.status == CustomerVisitStatus.notVisited)
        .length;
    final overdue = visits.where((v) => v.isScheduled && v.isOverdue).length;
    final pending = visits.where((v) => v.isScheduled && !v.isOverdue).length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            count: done,
            label: 'Done',
            color: const Color(0xFF2ECC40),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            count: pending,
            label: 'Pending',
            color: Colors.white,
            hollow: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            count: overdue,
            label: 'Overdue',
            color: const Color(0xFFE53935),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            count: missed,
            label: 'Missed',
            color: const Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.count,
    required this.label,
    required this.color,
    this.hollow = false,
  });

  final int count;
  final String label;
  final Color color;
  final bool hollow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: _cardDeco(16),
      child: Column(
        children: [
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: hollow ? null : color,
                  shape: BoxShape.circle,
                  border: hollow ? Border.all(color: color, width: 1.5) : null,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Kalender ─────────────────────────

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.visits,
    required this.loading,
    required this.failed,
    required this.onRetry,
    required this.onDayTap,
  });

  final List<CustomerVisit> visits;
  final bool loading;
  final bool failed;
  final VoidCallback onRetry;
  final void Function(DateTime day, List<CustomerVisit> visits) onDayTap;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (loading) {
      child = const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: AppColors.white)),
      );
    } else if (failed) {
      child = SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Failed to load visit schedule',
                style: TextStyle(color: Colors.white70),
              ),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      );
    } else {
      child = _MiniCalendar(visits: visits, onDayTap: onDayTap);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(20),
      child: child,
    );
  }
}

class _MiniCalendar extends StatefulWidget {
  const _MiniCalendar({required this.visits, required this.onDayTap});

  final List<CustomerVisit> visits;
  final void Function(DateTime day, List<CustomerVisit> visits) onDayTap;

  @override
  State<_MiniCalendar> createState() => _MiniCalendarState();
}

class _MiniCalendarState extends State<_MiniCalendar> {
  static const _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shift(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final byDay = <DateTime, List<CustomerVisit>>{};
    for (final v in widget.visits) {
      (byDay[_dateOnly(v.date)] ??= []).add(v);
    }

    final first = DateTime(_month.year, _month.month, 1);
    final offset = first.weekday % 7; // Minggu = 0
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final rows = ((offset + daysInMonth) / 7).ceil();
    final start = first.subtract(Duration(days: offset));

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SquareButton(icon: Icons.chevron_left, onTap: () => _shift(-1)),
            Text(
              '${_monthsEn[_month.month - 1]} ${_month.year}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            _SquareButton(icon: Icons.chevron_right, onTap: () => _shift(1)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            for (final w in _weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var r = 0; r < rows; r++)
          SizedBox(
            height: 46,
            child: Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: _dayCell(
                      start.add(Duration(days: r * 7 + c)),
                      byDay,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _dot(CustomerVisit v) {
    final (color, hollow) = switch (v.status) {
      CustomerVisitStatus.visited => (const Color(0xFF2ECC40), false),
      CustomerVisitStatus.notVisited => (const Color(0xFF9E9E9E), false),
      CustomerVisitStatus.scheduled =>
        v.isOverdue ? (const Color(0xFFE53935), false) : (Colors.white, true),
    };
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: hollow ? null : color,
        shape: BoxShape.circle,
        border: hollow ? Border.all(color: color, width: 1.2) : null,
      ),
    );
  }

  Widget _dayCell(DateTime d, Map<DateTime, List<CustomerVisit>> byDay) {
    final key = _dateOnly(d);
    final list = byDay[key];
    final inMonth = d.month == _month.month;
    final isToday = _sameDay(d, DateTime.now());

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: list == null ? null : () => widget.onDayTap(key, list),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isToday
                  ? Border.all(color: Colors.white, width: 1.5)
                  : null,
            ),
            child: Text(
              '${d.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: inMonth ? Colors.white : Colors.white30,
              ),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(height: 6, child: list == null ? null : _dot(list.first)),
        ],
      ),
    );
  }
}

// ───────────────────────── Popup detail visit ─────────────────────────

class _VisitDetailCard extends StatelessWidget {
  const _VisitDetailCard({required this.visit});

  final CustomerVisit visit;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(visit);
    final reported = visit.reportedAt;
    final note = visit.note;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCustField,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _statusLabel(visit),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _line(Icons.badge_outlined, 'Sales', visit.salesName ?? '-'),
          if (note != null && note.isNotEmpty)
            _line(Icons.notes_outlined, 'Notes', note),
          if (reported != null)
            _line(
              Icons.check_circle_outline,
              'Reported',
              '${_fmtLong(reported)}, ${_pad2(reported.hour)}:${_pad2(reported.minute)}',
            ),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.white60),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

// ───────────────────────── Popup edit customer ─────────────────────────

/// Satu baris jadwal di popup edit. [original] null = jadwal baru.
class _VisitDraft {
  _VisitDraft({this.original, required this.date});

  final CustomerVisit? original;
  DateTime date;
  bool deleted = false;

  bool get isNew => original == null;
  bool get dateChanged => original != null && !_sameDay(original!.date, date);
}

class _EditCustomerSheet extends StatefulWidget {
  const _EditCustomerSheet({required this.store, required this.visits});

  final CustomerStore store;
  final List<CustomerVisit> visits;

  @override
  State<_EditCustomerSheet> createState() => _EditCustomerSheetState();
}

class _EditCustomerSheetState extends State<_EditCustomerSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.store.storeName);
  late final _ownerCtrl = TextEditingController(text: widget.store.ownerName);
  late final _phoneCtrl = TextEditingController(text: widget.store.phone);
  late final _addressCtrl = TextEditingController(text: widget.store.address);
  late final _notesCtrl = TextEditingController(text: widget.store.notes ?? '');

  List<Sales> _sales = const [];
  bool _salesLoading = true;
  bool _salesFailed = false;
  int? _salesId;
  int? _visitDay;

  late final List<_VisitDraft> _drafts = [
    for (final v in widget.visits.where((v) => v.isScheduled))
      _VisitDraft(original: v, date: v.date),
  ];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _salesId = widget.store.salesId;
    _visitDay = widget.store.visitDay;
    _loadSales();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ownerCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSales() async {
    setState(() {
      _salesLoading = true;
      _salesFailed = false;
    });
    try {
      final data = [...await SalesService().fetchAll()];
      // Sales yang sekarang menangani bisa saja sudah nonaktif dan tidak ada
      // di daftar; tetap tampilkan supaya dropdown tidak error.
      final current = widget.store.salesId;
      if (current != null && !data.any((s) => s.id == current)) {
        data.insert(
          0,
          Sales(id: current, nama: widget.store.salesName ?? 'Sales #$current'),
        );
      }
      if (!mounted) return;
      setState(() {
        _sales = data;
        _salesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _salesFailed = true;
        _salesLoading = false;
      });
    }
  }

  void _msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickDate(_VisitDraft d) async {
    final today = _dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: d.date,
      firstDate: d.date.isBefore(today) ? d.date : today,
      lastDate: DateTime(today.year + 2, 12, 31),
    );
    if (picked != null) setState(() => d.date = _dateOnly(picked));
  }

  Future<void> _addDraft() async {
    final today = _dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: DateTime(today.year + 2, 12, 31),
    );
    if (picked == null) return;
    setState(() => _drafts.add(_VisitDraft(date: _dateOnly(picked))));
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final id = widget.store.id!;
    final salesChanged = _salesId != widget.store.salesId;
    // Sales dikosongkan: jadwal lama tetap atas nama sales lama.
    final moveVisits = salesChanged && _salesId != null;
    final svc = CustomerService();
    var profileSaved = false;

    setState(() => _saving = true);
    try {
      await svc.update(
        id,
        salesId: _salesId,
        visitDay: _visitDay,
        name: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        ownerName: _ownerCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
      );
      profileSaved = true;

      for (final d in _drafts) {
        final o = d.original;
        if (d.deleted) {
          if (o != null) await svc.deleteVisit(o.id);
        } else if (o == null) {
          // Jadwal baru butuh sales (tombol tambah nonaktif kalau sales kosong).
          final s = _salesId;
          if (s != null) {
            await svc.createVisit(salesId: s, customerId: id, date: d.date);
          }
        } else if (d.dateChanged || moveVisits) {
          await svc.updateVisit(
            o.id,
            customerId: id,
            date: d.date,
            salesId: moveVisits ? _salesId : null,
          );
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop('saved');
    } on DioException catch (e) {
      final extra = profileSaved ? ' (profile already saved)' : '';
      _msg('${CustomerService.errorMessage(e)}$extra');
    } catch (_) {
      _msg('Something went wrong, please try again');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (_saving) return;

    final ok = await showCustDialog<bool>(
      context: context,
      title: 'Delete customer?',
      content: Text(
        '"${widget.store.storeName}" will be deleted along with its visit '
        'schedule. This action cannot be undone.',
        style: GoogleFonts.poppins(fontSize: 13.5, color: Colors.white70),
      ),
      actions: [
        Builder(
          builder: (ctx) =>
              custDialogAction('Cancel', () => Navigator.pop(ctx, false)),
        ),
        Builder(
          builder: (ctx) => custDialogAction(
            'Delete',
            () => Navigator.pop(ctx, true),
            danger: true,
          ),
        ),
      ],
    );
    if (ok != true) return;

    setState(() => _saving = true);
    try {
      await CustomerService().delete(widget.store.id!);
      if (!mounted) return;
      Navigator.of(context).pop('deleted');
    } on DioException catch (e) {
      _msg(CustomerService.errorMessage(e));
    } catch (_) {
      _msg('Something went wrong, please try again');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    int? maxLength,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          custLabel(required ? '$label *' : label),
          TextFormField(
            controller: controller,
            style: custInputStyle(),
            cursorColor: AppColors.white,
            maxLength: maxLength,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: formatters,
            decoration: custDecoration(hint: hint),
            validator: required
                ? (v) => (v == null || v.trim().isEmpty)
                      ? '$label is required'
                      : null
                : null,
          ),
        ],
      ),
    );
  }

  Widget _salesDropdown() {
    if (_salesLoading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 14),
        child: LinearProgressIndicator(color: AppColors.red),
      );
    }
    if (_salesFailed) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Failed to load sales list',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            ),
            TextButton(onPressed: _loadSales, child: const Text('Try again')),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          custLabel('Sales in charge'),
          DropdownButtonFormField<int?>(
            initialValue: _salesId,
            isExpanded: true,
            style: custInputStyle(),
            dropdownColor: kCustPanel,
            iconEnabledColor: Colors.white70,
            decoration: custDecoration(),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Not assigned'),
              ),
              for (final s in _sales)
                DropdownMenuItem<int?>(value: s.id, child: Text(s.nama)),
            ],
            onChanged: (v) => setState(() => _salesId = v),
            validator: (v) => (_visitDay != null && v == null)
                ? 'Select a sales if a visit day is set'
                : null,
          ),
        ],
      ),
    );
  }

  Widget _dayDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          custLabel('Fixed visit day'),
          DropdownButtonFormField<int?>(
            initialValue: _visitDay,
            isExpanded: true,
            style: custInputStyle(),
            dropdownColor: kCustPanel,
            iconEnabledColor: Colors.white70,
            decoration: custDecoration(),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('No fixed schedule'),
              ),
              for (final e in kVisitDayNames.entries)
                DropdownMenuItem<int?>(
                  value: e.key,
                  child: Text(customerDayName(e.key)),
                ),
            ],
            onChanged: (v) => setState(() => _visitDay = v),
          ),
        ],
      ),
    );
  }

  String _visitInfo(bool salesChanged) {
    if (_salesId == null) {
      return widget.store.salesId == null
          ? 'Select a sales first to add a new schedule.'
          : 'Sales cleared: existing schedules stay with the previous sales.';
    }
    return salesChanged
        ? 'Sales changed: unreported schedules will move to the new sales.'
        : 'Only unreported schedules can be changed.';
  }

  Widget _visitSection() {
    final shown = _drafts.where((d) => !d.deleted).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final salesChanged = _salesId != widget.store.salesId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visit schedule',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _visitInfo(salesChanged),
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.white60),
        ),
        const SizedBox(height: 10),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No schedules yet.',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white60),
            ),
          ),
        for (final d in shown)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
            decoration: BoxDecoration(
              color: kCustField,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _fmtDate(d.date),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
                if (d.isNew || d.dateChanged)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      d.isNew ? 'new' : 'changed',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: kCustPink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                IconButton(
                  color: Colors.white70,
                  tooltip: 'Change date',
                  icon: const Icon(Icons.edit_calendar_outlined, size: 20),
                  onPressed: () => _pickDate(d),
                ),
                IconButton(
                  color: Colors.white70,
                  tooltip: 'Remove schedule',
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => setState(() {
                    if (d.isNew) {
                      _drafts.remove(d);
                    } else {
                      d.deleted = true;
                    }
                  }),
                ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: _salesId == null ? null : _addDraft,
          icon: const Icon(Icons.add_circle_outline, size: 18),
          label: Text(
            'Add visit schedule',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.white,
            disabledForegroundColor: Colors.white30,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Edit Customer',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _field(
                        controller: _nameCtrl,
                        label: 'Store name',
                        required: true,
                        maxLength: 150,
                      ),
                      _field(
                        controller: _ownerCtrl,
                        label: 'Owner name',
                        maxLength: 100,
                      ),
                      _field(
                        controller: _phoneCtrl,
                        label: 'Phone',
                        maxLength: 20,
                        keyboardType: TextInputType.phone,
                        formatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      _field(
                        controller: _addressCtrl,
                        label: 'Address',
                        required: true,
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                      ),
                      _salesDropdown(),
                      _dayDropdown(),
                      _field(
                        controller: _notesCtrl,
                        label: 'Notes',
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                      ),
                      const Divider(height: 24, color: Colors.white24),
                      _visitSection(),
                      const Divider(height: 24, color: Colors.white24),
                      Center(
                        child: TextButton.icon(
                          onPressed: _saving ? null : _delete,
                          icon: const Icon(
                            Icons.delete_forever_outlined,
                            size: 18,
                          ),
                          label: Text(
                            'Delete customer',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: kCustPink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 10),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    custSaveButton(
                      onPressed: _saving ? null : _save,
                      saving: _saving,
                    ),
                    custCancelButton(
                      _saving ? null : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Order history ─────────────────────────

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.onDetail});

  final Order order;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final date = order.createdAt;

    return Material(
      color: kCustPanel,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onDetail,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 54,
                decoration: BoxDecoration(
                  color: kCustField,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: date == null
                    ? const Center(child: Text('-', style: TextStyle(color: Colors.white70)))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${date.day}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                            ),
                          ),
                          Text(
                            _months[date.month - 1]
                                .substring(0, 3)
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
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
                      order.invoice ?? 'Order #${order.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date == null ? '-' : _fmtLong(date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white38, width: 1.2),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 13,
                      color: Colors.white70,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Detail',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: kCustField,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
