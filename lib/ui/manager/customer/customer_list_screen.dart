import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'customer_detail_screen.dart';

/// Model sementara. Pindahkan ke data/models saat API-nya siap.
class CustomerStore {
  const CustomerStore({
    required this.storeName,
    required this.ownerName,
    required this.phone,
    required this.address,
    this.photoUrl,
  });

  final String storeName;
  final String ownerName;
  final String phone;
  final String address;
  final String? photoUrl;
}

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  static const _background = Color(0xFF3A3A3A);

  // Data dummy, ganti dengan data dari service.
  final List<CustomerStore> _stores = List.generate(
    11,
    (_) => const CustomerStore(
      storeName: 'TOKO PURNAMA ABADI SENTOSA',
      ownerName: 'BAMBANG SUTRISNO',
      phone: '(085876543210)',
      address: 'JL. JEND. SOEDIRMAN, KABUPATEN KLATEN',
    ),
  );

  bool _searching = false;
  String _query = '';

  List<CustomerStore> get _filtered {
    if (_query.isEmpty) return _stores;
    final q = _query.toLowerCase();
    return _stores
        .where((s) =>
            s.storeName.toLowerCase().contains(q) ||
            s.ownerName.toLowerCase().contains(q) ||
            s.address.toLowerCase().contains(q))
        .toList();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) _query = '';
    });
  }

  void _onAddStore() {
    // TODO: navigasi ke halaman tambah toko.
  }

  @override
  Widget build(BuildContext context) {
    final stores = _filtered;

    return Scaffold(
      backgroundColor: _background,
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
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.antiAlias,
                child: stores.isEmpty
                    ? const Center(child: Text('Toko tidak ditemukan'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: stores.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          thickness: 1,
                          indent: 12,
                          endIndent: 12,
                          color: Color(0xFFE6E6E6),
                        ),
                        itemBuilder: (_, i) => _StoreTile(store: stores[i]),
                      ),
              ),
            ),
            _BottomBar(count: stores.length, onAddStore: _onAddStore),
            // Ruang agar tidak tertutup FloatingNavBar (tinggi 64 + margin).
            const SizedBox(height: 96),
          ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: searching
                ? TextField(
                    autofocus: true,
                    onChanged: onChanged,
                    style: const TextStyle(color: AppColors.white),
                    cursorColor: AppColors.white,
                    decoration: const InputDecoration(
                      hintText: 'Cari toko...',
                      hintStyle: TextStyle(color: AppColors.grey),
                      border: InputBorder.none,
                    ),
                  )
                : const Text(
                    'Customer',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          Material(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onSearchTap,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  searching ? Icons.close : Icons.search,
                  color: Colors.black,
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
  const _StoreTile({required this.store});

  final CustomerStore store;

  static const _detailStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CustomerDetailScreen(store: store),
          ),
        );
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
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          store.ownerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _detailStyle,
                        ),
                      ),
                      Text(store.phone, style: _detailStyle),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    store.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _detailStyle,
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
  const _BottomBar({required this.count, required this.onAddStore});

  final int count;
  final VoidCallback onAddStore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        children: [
          const Text(
            'All Store',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.grey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          Material(
            color: AppColors.red,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onAddStore,
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
                    Icon(Icons.add_circle,
                        color: AppColors.white, size: 14),
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
