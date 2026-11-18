import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sfa_mobile/data/models/customer_visit.dart';
import 'package:sfa_mobile/data/models/sales.dart';
import 'package:sfa_mobile/data/services/customer_service.dart';
import 'package:sfa_mobile/data/services/sales_service.dart';

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

String _fmtLong(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';
String _fmtDate(DateTime d) => '${d.day} - ${_months[d.month - 1]} - ${d.year}';
String _pad2(int n) => n.toString().padLeft(2, '0');
DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

const _colorScheduled = Color(0xFF3B82F6);
const _colorOverdue = Color(0xFFF59E0B);
const _colorVisited = Color(0xFF2ECC40);
const _colorNotVisited = Color(0xFFE53935);

String _statusLabel(CustomerVisit v) => switch (v.status) {
  CustomerVisitStatus.visited => 'Sudah dikunjungi',
  CustomerVisitStatus.notVisited => 'Tidak dikunjungi',
  CustomerVisitStatus.scheduled => v.isOverdue ? 'Terlewat' : 'Terjadwal',
};

Color _statusColor(CustomerVisit v) => switch (v.status) {
  CustomerVisitStatus.visited => _colorVisited,
  CustomerVisitStatus.notVisited => _colorNotVisited,
  CustomerVisitStatus.scheduled =>
    v.isOverdue ? _colorOverdue : _colorScheduled,
};

class _OrderHistory {
  const _OrderHistory({required this.invoice, required this.date});
  final String invoice;
  final String date;
}

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({super.key, required this.store});

  final CustomerStore store;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  static const _background = Color(0xFF3A3A3A);

  // Data dummy, ganti dengan data dari service (menunggu backend order).
  static const _orders = [
    _OrderHistory(invoice: 'INV. 0028-089.12.23.2029', date: '23 Oktober 2026'),
    _OrderHistory(invoice: 'INV. 0028-089.12.23.2029', date: '23 Oktober 2026'),
    _OrderHistory(invoice: 'INV. 0028-089.12.23.2029', date: '23 Oktober 2026'),
    _OrderHistory(invoice: 'INV. 0028-089.12.23.2029', date: '23 Oktober 2026'),
  ];

  final _service = CustomerService();
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

  /// Popup detail kunjungan pada tanggal yang diketuk.
  void _showDay(DateTime day, List<CustomerVisit> list) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        title: Text(
          _fmtLong(day),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [for (final v in list) _VisitDetailCard(visit: v)],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _openEdit() async {
    if (_store.id == null) return;
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditCustomerSheet(store: _store, visits: _visits),
    );
    if (!mounted) return;
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
        backgroundColor: _background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: _InfoCard(
                  store: _store,
                  visits: _visits,
                  loading: _loadingVisits,
                  failed: _visitsFailed,
                  onRetry: _loadVisits,
                  onDayTap: _showDay,
                ),
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
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
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
                          onTap: _openEdit,
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
      ),
    );
  }
}

// ───────────────────────── Kartu info + kalender ─────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.store,
    required this.visits,
    required this.loading,
    required this.failed,
    required this.onRetry,
    required this.onDayTap,
  });

  final CustomerStore store;
  final List<CustomerVisit> visits;
  final bool loading;
  final bool failed;
  final VoidCallback onRetry;
  final void Function(DateTime day, List<CustomerVisit> visits) onDayTap;

  static const _cardColor = Color(0xFFD6D6D6);
  static const _panelColor = Color(0xFFBDBDBD);

  @override
  Widget build(BuildContext context) {
    final photo = store.photoUrl;

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
                  child: (photo == null || photo.isEmpty)
                      ? const Icon(
                          Icons.storefront_outlined,
                          color: Colors.black38,
                        )
                      : Image.network(
                          photo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.storefront_outlined,
                            color: Colors.black38,
                          ),
                        ),
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
                            store.ownerName.isEmpty ? '-' : store.ownerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                        if (store.phone.isNotEmpty)
                          Text(
                            store.phone,
                            style: const TextStyle(fontSize: 10),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      store.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    // Sales yang menangani customer ini.
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined, size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Sales: ${store.salesName ?? '-'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 262,
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _panelColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.red),
                  )
                : failed
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Gagal memuat jadwal visit',
                          style: TextStyle(fontSize: 12),
                        ),
                        TextButton(
                          onPressed: onRetry,
                          child: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  )
                : _MiniCalendar(visits: visits, onDayTap: onDayTap),
          ),
        ],
      ),
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
  static const _weekdays = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
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
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
                      fontSize: 10,
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
                    child: _dayCell(
                      start.add(Duration(days: r * 7 + c)),
                      byDay,
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        const Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 2,
          children: [
            _LegendDot(color: _colorScheduled, label: 'Terjadwal'),
            _LegendDot(color: _colorOverdue, label: 'Terlewat'),
            _LegendDot(color: _colorVisited, label: 'Dikunjungi'),
            _LegendDot(color: _colorNotVisited, label: 'Tidak dikunjungi'),
          ],
        ),
      ],
    );
  }

  Widget _dayCell(DateTime d, Map<DateTime, List<CustomerVisit>> byDay) {
    final key = _dateOnly(d);
    final list = byDay[key];
    final inMonth = d.month == _month.month;
    final isToday = _sameDay(d, DateTime.now());
    final color = list == null ? null : _statusColor(list.first);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: list == null ? null : () => widget.onDayTap(key, list),
      child: Center(
        child: Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: (isToday && color == null)
                ? Border.all(color: Colors.black54)
                : null,
          ),
          child: Text(
            '${d.day}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: color != null ? FontWeight.w700 : FontWeight.w500,
              color: color != null
                  ? Colors.white
                  : (inMonth ? Colors.black : Colors.black45),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 8.5)),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Icon(icon, size: 18),
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
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(10),
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
            _line(Icons.notes_outlined, 'Catatan', note),
          if (reported != null)
            _line(
              Icons.check_circle_outline,
              'Dilaporkan',
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
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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

  late final List<_VisitDraft> _drafts = [
    for (final v in widget.visits.where((v) => v.isScheduled))
      _VisitDraft(original: v, date: v.date),
  ];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _salesId = widget.store.salesId;
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
    final svc = CustomerService();
    var profileSaved = false;

    setState(() => _saving = true);
    try {
      await svc.update(
        id,
        salesId: _salesId!,
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
          await svc.createVisit(
            salesId: _salesId!,
            customerId: id,
            date: d.date,
          );
        } else if (d.dateChanged || salesChanged) {
          await svc.updateVisit(
            o.id,
            customerId: id,
            date: d.date,
            salesId: salesChanged ? _salesId : null,
          );
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      final extra = profileSaved ? ' (profil sudah tersimpan)' : '';
      _msg('${CustomerService.errorMessage(e)}$extra');
    } catch (_) {
      _msg('Terjadi kesalahan, coba lagi');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(String label, {bool required = false}) {
    return InputDecoration(
      labelText: required ? '$label *' : label,
      labelStyle: const TextStyle(color: Color(0xFF757575)),
      floatingLabelStyle: const TextStyle(color: AppColors.red),
      counterText: '',
      filled: true,
      fillColor: const Color(0xFFF3F3F3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.red, width: 1.5),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    bool required = false,
    int? maxLength,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.black87),
        maxLength: maxLength,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        decoration: _decoration(label, required: required),
        validator: required
            ? (v) =>
                  (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null
            : null,
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
            const Expanded(child: Text('Gagal memuat daftar sales')),
            TextButton(onPressed: _loadSales, child: const Text('Coba lagi')),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<int>(
        initialValue: _salesId,
        isExpanded: true,
        style: const TextStyle(color: Colors.black87),
        dropdownColor: AppColors.white,
        decoration: _decoration('Sales yang Menangani', required: true),
        items: [
          for (final s in _sales)
            DropdownMenuItem(value: s.id, child: Text(s.nama)),
        ],
        onChanged: (v) => setState(() => _salesId = v),
        validator: (v) => v == null ? 'Pilih sales' : null,
      ),
    );
  }

  Widget _visitSection() {
    final shown = _drafts.where((d) => !d.deleted).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final salesChanged = _salesId != widget.store.salesId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jadwal Visit',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          salesChanged
              ? 'Sales diganti: jadwal yang belum dilaporkan akan dipindah ke sales baru.'
              : 'Hanya jadwal yang belum dilaporkan yang bisa diubah.',
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        if (shown.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Belum ada jadwal.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        for (final d in shown)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _fmtDate(d.date),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (d.isNew || d.dateChanged)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      d.isNew ? 'baru' : 'diubah',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                IconButton(
                  tooltip: 'Ubah tanggal',
                  icon: const Icon(Icons.edit_calendar_outlined, size: 20),
                  onPressed: () => _pickDate(d),
                ),
                IconButton(
                  tooltip: 'Hapus jadwal',
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
          onPressed: _addDraft,
          icon: const Icon(Icons.add_circle_outline, size: 18),
          label: const Text('Tambah jadwal visit'),
          style: TextButton.styleFrom(foregroundColor: AppColors.red),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Edit Customer',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _field(
                        controller: _nameCtrl,
                        label: 'Nama Toko',
                        required: true,
                        maxLength: 150,
                      ),
                      _field(
                        controller: _ownerCtrl,
                        label: 'Nama Pemilik',
                        maxLength: 100,
                      ),
                      _field(
                        controller: _phoneCtrl,
                        label: 'No. Telepon',
                        maxLength: 20,
                        keyboardType: TextInputType.phone,
                        formatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      _field(
                        controller: _addressCtrl,
                        label: 'Alamat',
                        required: true,
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                      ),
                      _salesDropdown(),
                      _field(
                        controller: _notesCtrl,
                        label: 'Catatan',
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                      ),
                      const Divider(height: 24),
                      _visitSection(),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.red,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Text('Simpan'),
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

// ───────────────────────── History order (dummy) ─────────────────────────

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
                // TODO: navigasi ke detail order (menunggu backend order).
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
