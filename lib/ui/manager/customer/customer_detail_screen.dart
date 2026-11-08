import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'customer_list_screen.dart';

const _months = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

String _fmtDate(DateTime d) => '${d.day} - ${_months[d.month - 1]} - ${d.year}';

class _OrderHistory {
  const _OrderHistory({required this.invoice, required this.date});
  final String invoice;
  final String date;
}

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key, required this.store});

  final CustomerStore store;

  static const _background = Color(0xFF3A3A3A);

  // Data dummy, ganti dengan data dari service.
  static final List<DateTime> _visitDates = [
    DateTime(2026, 11, 21),
    DateTime(2026, 11, 28),
    DateTime(2025, 12, 5),
    DateTime(2025, 12, 13),
    DateTime(2025, 12, 20),
    DateTime(2026, 1, 5),
    DateTime(2026, 1, 18),
    DateTime(2026, 2, 2),
  ];

  static const _orders = [
    _OrderHistory(invoice: 'INV. 0028-089.12.23.2029', date: '23 Oktober 2026'),
    _OrderHistory(invoice: 'INV. 0028-089.12.23.2029', date: '23 Oktober 2026'),
    _OrderHistory(invoice: 'INV. 0028-089.12.23.2029', date: '23 Oktober 2026'),
    _OrderHistory(invoice: 'INV. 0028-089.12.23.2029', date: '23 Oktober 2026'),
    _OrderHistory(invoice: 'INV. 0028-089.12.23.2029', date: '23 Oktober 2026'),
    _OrderHistory(invoice: 'INV. 0028-089.12.23.2029', date: '23 Oktober 2026'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: _InfoCard(store: store, visitDates: _visitDates),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'History Order',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _OrderTile(order: _orders[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.chevron_left,
                      color: AppColors.white,
                      size: 22,
                    ),
                    label: const Text(
                      'back',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Material(
                      color: const Color(0xFF5C1414),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          // TODO: navigasi ke halaman edit customer.
                        },
                        child: const SizedBox(
                          height: 40,
                          child: Center(
                            child: Text(
                              'EDIT',
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
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
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.store, required this.visitDates});

  final CustomerStore store;
  final List<DateTime> visitDates;

  static const _cardColor = Color(0xFFD6D6D6);
  static const _panelColor = Color(0xFFBDBDBD);

  @override
  Widget build(BuildContext context) {
    final history = [...visitDates]..sort((a, b) => b.compareTo(a));

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 56,
                  height: 56,
                  color: AppColors.white,
                  child: store.photoUrl == null
                      ? null
                      : Image.network(store.photoUrl!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            store.ownerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                        Text(store.phone, style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      store.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 176,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                    decoration: BoxDecoration(
                      color: _panelColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'HISTORY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: history.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, color: Colors.black54),
                            itemBuilder: (_, i) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                _fmtDate(history[i]),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _panelColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _MiniCalendar(
                      initialMonth: DateTime(2026, 1),
                      highlighted: visitDates.toSet(),
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
}

class _MiniCalendar extends StatefulWidget {
  const _MiniCalendar({required this.initialMonth, required this.highlighted});

  final DateTime initialMonth;
  final Set<DateTime> highlighted;

  @override
  State<_MiniCalendar> createState() => _MiniCalendarState();
}

class _MiniCalendarState extends State<_MiniCalendar> {
  static const _weekdays = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
  late DateTime _month = DateTime(
    widget.initialMonth.year,
    widget.initialMonth.month,
  );

  void _shift(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(_month.year, _month.month, 1);
    final offset = first.weekday - 1; // Senin = 0
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final rows = ((offset + daysInMonth) / 7).ceil();
    final start = first.subtract(Duration(days: offset));

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ArrowButton(icon: Icons.chevron_left, onTap: () => _shift(-1)),
            Text(
              '${_months[_month.month - 1]} ${_month.year}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
            _ArrowButton(icon: Icons.chevron_right, onTap: () => _shift(1)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    _weekdays[i],
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: i == 6 ? AppColors.red : Colors.black,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        for (var r = 0; r < rows; r++)
          Expanded(
            child: Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: _dayCell(start.add(Duration(days: r * 7 + c))),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _dayCell(DateTime d) {
    final inMonth = d.month == _month.month;
    final isVisit = widget.highlighted.contains(
      DateTime(d.year, d.month, d.day),
    );

    return Center(
      child: Container(
        width: 16,
        height: 16,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isVisit ? const Color(0xFF2ECC40) : null,
          shape: BoxShape.circle,
        ),
        child: Text(
          '${d.day}',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: inMonth ? Colors.black : Colors.black45,
          ),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(icon, size: 14),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final _OrderHistory order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF5A5A5A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.invoice,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order.date,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                // TODO: navigasi ke detail order.
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'detail',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 14,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
