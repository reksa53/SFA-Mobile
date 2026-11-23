int _int(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

DateTime? _date(dynamic v) =>
    v is String && v.isNotEmpty ? DateTime.tryParse(v)?.toLocal() : null;

Map<String, dynamic> _map(dynamic v) =>
    v is Map ? v.cast<String, dynamic>() : const <String, dynamic>{};

List<Map<String, dynamic>> _list(dynamic v) =>
    v is List ? v.map(_map).toList() : const [];

class VisitStats {
  const VisitStats({
    required this.total,
    required this.done,
    required this.pending,
    required this.overdue,
    required this.missed,
  });

  final int total;
  final int done;
  final int pending;
  final int overdue;
  final int missed;

  factory VisitStats.fromJson(Map<String, dynamic> j) => VisitStats(
    total: _int(j['total']),
    done: _int(j['done']),
    pending: _int(j['pending']),
    overdue: _int(j['overdue']),
    missed: _int(j['missed']),
  );
}

/// Order bulan berjalan + omzet dari order accepted.
class OrderStats {
  const OrderStats({
    required this.all,
    required this.pending,
    required this.accepted,
    required this.rejected,
    required this.revenue,
  });

  final int all;
  final int pending;
  final int accepted;
  final int rejected;
  final int revenue;

  factory OrderStats.fromJson(Map<String, dynamic> j) => OrderStats(
    all: _int(j['all']),
    pending: _int(j['pending']),
    accepted: _int(j['accepted']),
    rejected: _int(j['rejected']),
    revenue: _int(j['revenue']),
  );
}

// ───────────── Manager ─────────────

class PendingOrder {
  const PendingOrder({
    required this.id,
    required this.customer,
    required this.sales,
    required this.total,
    this.createdAt,
  });

  final int id;
  final String customer;
  final String sales;
  final int total;
  final DateTime? createdAt;

  factory PendingOrder.fromJson(Map<String, dynamic> j) => PendingOrder(
    id: _int(j['id']),
    customer: '${j['customer'] ?? '-'}',
    sales: '${j['sales'] ?? '-'}',
    total: _int(j['total']),
    createdAt: _date(j['created_at']),
  );
}

class BehindSales {
  const BehindSales({
    required this.id,
    required this.name,
    required this.overdue,
  });

  final int id;
  final String name;
  final int overdue;

  factory BehindSales.fromJson(Map<String, dynamic> j) => BehindSales(
    id: _int(j['id']),
    name: '${j['name'] ?? '-'}',
    overdue: _int(j['overdue']),
  );
}

class ManagerDashboard {
  const ManagerDashboard({
    required this.orders,
    required this.pendingTotal,
    required this.pendingList,
    required this.visitsToday,
    required this.visitsMonth,
    required this.behindSales,
    required this.customersTotal,
    required this.customersUnassigned,
    required this.salesTotal,
    required this.outOfStock,
    required this.nearExpiredBatches,
    required this.nearExpiryDays,
  });

  final OrderStats orders;
  final int pendingTotal;
  final List<PendingOrder> pendingList;
  final VisitStats visitsToday;
  final VisitStats visitsMonth;
  final List<BehindSales> behindSales;
  final int customersTotal;
  final int customersUnassigned;
  final int salesTotal;
  final int outOfStock;
  final int nearExpiredBatches;
  final int nearExpiryDays;

  factory ManagerDashboard.fromJson(Map<String, dynamic> j) {
    final orders = _map(j['orders']);
    final visits = _map(j['visits']);
    final customers = _map(j['customers']);
    final stock = _map(j['stock']);

    return ManagerDashboard(
      orders: OrderStats.fromJson(orders),
      pendingTotal: _int(orders['pending_total']),
      pendingList: _list(orders['pending_list'])
          .map(PendingOrder.fromJson)
          .toList(),
      visitsToday: VisitStats.fromJson(_map(visits['today'])),
      visitsMonth: VisitStats.fromJson(_map(visits['month'])),
      behindSales: _list(visits['behind_sales'])
          .map(BehindSales.fromJson)
          .toList(),
      customersTotal: _int(customers['total']),
      customersUnassigned: _int(customers['unassigned']),
      salesTotal: _int(j['sales_total']),
      outOfStock: _int(stock['out_of_stock']),
      nearExpiredBatches: _int(stock['near_expired_batches']),
      nearExpiryDays: _int(stock['near_expiry_days']),
    );
  }
}

// ───────────── Sales ─────────────

class TodayVisit {
  const TodayVisit({
    required this.id,
    required this.status,
    required this.customerId,
    required this.customerName,
    this.customerAddress,
  });

  final int id;

  /// 'scheduled' | 'visited' | 'not_visited'
  final String status;
  final int? customerId;
  final String customerName;
  final String? customerAddress;

  factory TodayVisit.fromJson(Map<String, dynamic> j) {
    final c = _map(j['customer']);
    return TodayVisit(
      id: _int(j['id']),
      status: '${j['status'] ?? 'scheduled'}',
      customerId: c['id'] == null ? null : _int(c['id']),
      customerName: '${c['name'] ?? '-'}',
      customerAddress: c['address'] as String?,
    );
  }
}

class InactiveCustomer {
  const InactiveCustomer({
    required this.id,
    required this.name,
    this.address,
    this.daysSince,
  });

  final int id;
  final String name;
  final String? address;

  /// Null = belum pernah order.
  final int? daysSince;

  factory InactiveCustomer.fromJson(Map<String, dynamic> j) => InactiveCustomer(
    id: _int(j['id']),
    name: '${j['name'] ?? '-'}',
    address: j['address'] as String?,
    daysSince: j['days_since'] == null ? null : _int(j['days_since']),
  );
}

class SalesDashboard {
  const SalesDashboard({
    required this.customersTotal,
    required this.visitsToday,
    required this.visitsMonth,
    required this.todayVisits,
    required this.orders,
    required this.inactive,
    required this.inactiveDays,
  });

  final int customersTotal;
  final VisitStats visitsToday;
  final VisitStats visitsMonth;
  final List<TodayVisit> todayVisits;
  final OrderStats orders;
  final List<InactiveCustomer> inactive;
  final int inactiveDays;

  factory SalesDashboard.fromJson(Map<String, dynamic> j) {
    final visits = _map(j['visits']);
    return SalesDashboard(
      customersTotal: _int(_map(j['customers'])['total']),
      visitsToday: VisitStats.fromJson(_map(visits['today'])),
      visitsMonth: VisitStats.fromJson(_map(visits['month'])),
      todayVisits: _list(j['today_visits']).map(TodayVisit.fromJson).toList(),
      orders: OrderStats.fromJson(_map(j['orders'])),
      inactive: _list(j['inactive_customers'])
          .map(InactiveCustomer.fromJson)
          .toList(),
      inactiveDays: _int(j['inactive_days']),
    );
  }
}
