import 'package:flutter/material.dart';

import 'app_destinations.dart';
import 'floating_nav_bar.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  // Halaman baru dibangun saat pertama dibuka, lalu state-nya dipertahankan.
  final Set<int> _opened = {0};

  void _onSelected(int i) => setState(() {
        _index = i;
        _opened.add(i);
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // konten tampil di belakang navbar (efek glass)
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < appDestinations.length; i++)
            _opened.contains(i)
                ? appDestinations[i].builder(context)
                : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: FloatingNavBar(
        destinations: appDestinations,
        currentIndex: _index,
        onSelected: _onSelected,
      ),
    );
  }
}