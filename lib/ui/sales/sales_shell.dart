import 'package:flutter/material.dart';

import '../core/widgets/floating_navbar.dart';
import '../core/widgets/placeholder_page.dart';
import '../core/widgets/tab_shell.dart';

class SalesShell extends StatelessWidget {
  const SalesShell({super.key});

  static const _items = [
    NavItem(label: 'Visit', icon: Icons.pin_drop_outlined),
    NavItem(label: 'Order', icon: Icons.receipt_long_outlined),
  ];

  static const _pages = [
    PlaceholderPage(title: 'Visit'),
    PlaceholderPage(title: 'Order'),
  ];

  @override
  Widget build(BuildContext context) =>
      const TabShell(items: _items, pages: _pages);
}
