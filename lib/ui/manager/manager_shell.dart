import 'package:flutter/material.dart';

import '../core/widgets/floating_navbar.dart';
import '../core/widgets/placeholder_page.dart';
import '../core/widgets/tab_shell.dart';

class ManagerShell extends StatelessWidget {
  const ManagerShell({super.key});

  static const _items = [
    NavItem(label: 'Customer', icon: Icons.storefront_outlined),
    NavItem(label: 'Product', icon: Icons.inventory_2_outlined),
    NavItem(label: 'Sales & Visit', icon: Icons.route_outlined),
    NavItem(label: 'Order', icon: Icons.receipt_long_outlined),
  ];

  // Ganti PlaceholderPage dengan layar sungguhan saat fiturnya jadi.
  static const _pages = [
    PlaceholderPage(title: 'Customer'),
    PlaceholderPage(title: 'Product'),
    PlaceholderPage(title: 'Sales & Visit'),
    PlaceholderPage(title: 'Order'),
  ];

  @override
  Widget build(BuildContext context) =>
      const TabShell(items: _items, pages: _pages);
}