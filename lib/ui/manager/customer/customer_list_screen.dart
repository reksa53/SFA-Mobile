import 'package:flutter/material.dart';
import 'package:sfa_mobile/data/models/customer_store.dart';
import 'package:sfa_mobile/data/services/customer_service.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'add_customer_screen.dart';
import 'customer_detail_screen.dart';

// Supaya file lain yang mengimpor layar ini tetap menemukan CustomerStore.
export 'package:sfa_mobile/data/models/customer_store.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key, this.canEdit = true});

  /// Manager = true. Sales = false: hanya daftar customer yang ditugaskan
  /// ke sales itu (dibatasi server), tanpa tombol tambah, detail read-only.
  final bool canEdit;

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _service = CustomerService();
  List<CustomerStore> _stores = const [];
  bool _loading = true;
  bool _failed = false;
  bool _searching = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _service.fetchAll();
      if (!mounted) return;
      setState(() {
        _stores = data;
        _loading = false;
        _failed = false;
      });
    } catch (e) {
      debugPrint('LOAD CUSTOMERS ERROR: $e');
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

  List<CustomerStore> get _filtered {
    if (_query.isEmpty) return _stores;
    final q = _query.toLowerCase();
    return _stores
        .where(
          (s) =>
              s.storeName.toLowerCase().contains(q) ||
              s.ownerName.toLowerCase().contains(q) ||
              s.address.toLowerCase().contains(q),
        )
        .toList();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) _query = '';
    });
  }

  Future<void> _onAddStore() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
    );
    if (added == true) _load(); // ambil ulang dari server
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final stores = _filtered;

    return ThemedPage(
      child: Scaffold(
        backgroundColor: p.bgDeep,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _Header(
                searching: _searching,
                onSearchTap: _toggleSearch,
                onChanged: (v) => setState(() => _query = v),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: p.surfaceBorder,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildBody(stores),
                ),
              ),
              _BottomBar(
                count: _stores.length,
                label: widget.canEdit ? 'All Store' : 'My Store',
                // Sales tidak bisa menambah customer.
                onAddStore: widget.canEdit ? _onAddStore : null,
              ),
              // Ruang agar tidak tertutup FloatingNavBar (tinggi 64 + margin).
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<CustomerStore> stores) {
    final p = context.palette;

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
              'Gagal memuat data customer',
              style: TextStyle(color: p.onSurface),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _retry,
              style: FilledButton.styleFrom(backgroundColor: AppColors.red),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }
    if (stores.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _stores.isEmpty
                ? (widget.canEdit
                      ? 'Belum ada customer'
                      : 'Belum ada customer yang ditugaskan ke kamu')
                : 'Toko tidak ditemukan',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.onSurface),
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.red,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: stores.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          thickness: 1,
          indent: 12,
          endIndent: 12,
          color: p.divider,
        ),
        itemBuilder: (_, i) => _StoreTile(
          store: stores[i],
          canEdit: widget.canEdit,
          onReturn: _load,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.searching,
    required this.onSearchTap,
    required this.onChanged,
  });

  final bool searching;
  final VoidCallback onSearchTap;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: searching
                ? TextField(
                    autofocus: true,
                    onChanged: onChanged,
                    style: TextStyle(color: p.text),
                    cursorColor: p.text,
                    decoration: InputDecoration(
                      hintText: 'Cari toko...',
                      hintStyle: TextStyle(color: p.hint),
                      border: InputBorder.none,
                    ),
                  )
                : Text(
                    'Customer',
                    style: TextStyle(
                      color: p.text,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          Material(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onSearchTap,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: p.surfaceBorder,
                ),
                child: Icon(
                  searching ? Icons.close : Icons.search,
                  color: p.onSurface,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreTile extends StatelessWidget {
  const _StoreTile({
    required this.store,
    required this.canEdit,
    required this.onReturn,
  });

  final CustomerStore store;
  final bool canEdit;

  /// Dipanggil setelah kembali dari layar detail (data mungkin berubah).
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final photo = store.photoUrl;
    final detailStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: p.onSurface,
    );

    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CustomerDetailScreen(store: store, canEdit: canEdit),
          ),
        );
        onReturn();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 44,
                height: 44,
                color: const Color(0xFFA8A8A8),
                child: (photo == null || photo.isEmpty)
                    ? const Icon(
                        Icons.storefront_outlined,
                        color: AppColors.white,
                        size: 22,
                      )
                    : Image.network(
                        photo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.storefront_outlined,
                          color: AppColors.white,
                          size: 22,
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
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: p.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          store.ownerName.isEmpty ? '-' : store.ownerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: detailStyle,
                        ),
                      ),
                      if (store.phone.isNotEmpty)
                        Text(store.phone, style: detailStyle),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    store.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: detailStyle,
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

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.count,
    required this.label,
    required this.onAddStore,
  });

  final int count;
  final String label;

  /// Null = tombol Add Store disembunyikan (tampilan sales).
  final VoidCallback? onAddStore;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final add = onAddStore;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: p.text,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: p.chip,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: p.onChip,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          if (add != null)
            Material(
              color: AppColors.red,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: add,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Add Store',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.add_circle, color: AppColors.white, size: 14),
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