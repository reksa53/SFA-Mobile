import 'package:flutter/material.dart';

import '../../../core/widgets/app_header.dart';
import '../data/toko.dart';
import '../data/toko_repository.dart';
import 'toko_card.dart';

class TokoPage extends StatefulWidget {
  const TokoPage({super.key, this.repository = const DummyTokoRepository()});

  final TokoRepository repository;

  @override
  State<TokoPage> createState() => _TokoPageState();
}

class _TokoPageState extends State<TokoPage> {
  late Future<List<Toko>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getTokoSales();
  }

  void _reload() =>
      setState(() => _future = widget.repository.getTokoSales());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppHeader(title: 'CENTRAL SINN'),
        Expanded(
          child: FutureBuilder<List<Toko>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Gagal memuat data toko'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _reload,
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                );
              }
              final list = snapshot.data ?? const <Toko>[];
              if (list.isEmpty) {
                return const Center(child: Text('Belum ada toko'));
              }
              return ListView.separated(
                // Padding bawah = tinggi navbar (diisi Scaffold lewat
                // extendBody) supaya item terakhir tidak tertutup.
                padding: EdgeInsets.fromLTRB(
                  7.5,
                  0,
                  7.5,
                  MediaQuery.paddingOf(context).bottom + 16,
                ),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (_, i) => TokoCard(toko: list[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}