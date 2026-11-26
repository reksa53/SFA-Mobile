import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'floating_navbar.dart';

/// Kerangka halaman bertab: isi di atas, navbar melayang di bawah.
/// Dipakai ManagerShell dan SalesShell.
class TabShell extends StatefulWidget {
  const TabShell({super.key, required this.items, required this.pages});

  final List<NavItem> items;
  final List<Widget> pages;

  @override
  State<TabShell> createState() => _TabShellState();
}

class _TabShellState extends State<TabShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Layar tanpa Scaffold sendiri (Order, placeholder) memakai latar ini.
      backgroundColor: context.palette.bg,
      extendBody: true,
      body: IndexedStack(
        index: _index,
        sizing: StackFit.expand,
        children: widget.pages,
      ),
      bottomNavigationBar: FloatingNavBar(
        items: widget.items,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}