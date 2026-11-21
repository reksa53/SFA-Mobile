import 'package:flutter/material.dart';
import 'package:sfa_mobile/data/models/customer_store.dart';
import 'package:sfa_mobile/data/services/customer_service.dart';

import '../../core/theme/app_colors.dart';
import '../../manager/customer/add_customer_screen.dart';
import '../../manager/customer/customer_detail_screen.dart';
import '../../manager/customer/customer_list_widgets.dart';
import '../../core/widgets/manager_header.dart';

// Supaya file lain yang mengimpor layar ini tetap menemukan CustomerStore.
export 'package:sfa_mobile/data/models/customer_store.dart';

class SalesCustomerListScreen extends StatefulWidget {
  const SalesCustomerListScreen({super.key, this.canEdit = false});

  /// Manager = true. Sales = false: hanya daftar customer yang ditugaskan
  /// ke sales itu (dibatasi server), tanpa tombol tambah, detail read-only.
  final bool canEdit;

  @override
  State<SalesCustomerListScreen> createState() => _SalesCustomerListScreenState();
}

class _SalesCustomerListScreenState extends State<SalesCustomerListScreen> {
  final _service = CustomerService();
  List<CustomerStore> _stores = const [];
  bool _loading = true;
  bool _failed = false;
  final _search = TextEditingController();
  bool _searching = false;
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

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
      if (!_searching) {
        _query = '';
        _search.clear();
      }
    });
  }

  Future<void> _onAddStore() async {
    final added = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AddCustomerScreen()));
    if (added == true) _load(); // ambil ulang dari server
  }

  Future<void> _openDetail(CustomerStore store) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            CustomerDetailScreen(store: store, canEdit: widget.canEdit),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final stores = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ManagerHeader(
              title: 'Customer',
              searchOpen: _searching,
              searchController: _search,
              onSearchToggle: _toggleSearch,
              onSearchChanged: (v) => setState(() => _query = v),
              searchHint: 'Search store...',
            ),
            CustomerSubtitle(count: _stores.length),
            Expanded(
              child: _buildBody(stores),
            ),
            CustomerBottomBar(
              count: _stores.length,
              label: widget.canEdit ? 'All Store' : 'My Store',
              // Sales tidak bisa menambah customer.
              onAddStore: widget.canEdit ? _onAddStore : null,
            ),
            // Ruang agar tidak tertutup FloatingNavBar (tinggi 64 + margin).
            const SizedBox(height: 104),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<CustomerStore> stores) {
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
            customerListMessage('Failed to load customers'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _retry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.red,
                shape: const StadiumBorder(),
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }
    if (stores.isEmpty) {
      return customerListMessage(
        _stores.isEmpty
            ? (widget.canEdit
                  ? 'No customers yet'
                  : 'No customers have been assigned to you yet')
            : 'No store found',
      );
    }
    return CustomerListCard(
      stores: stores,
      onRefresh: _load,
      onTap: _openDetail,
    );
  }
}
