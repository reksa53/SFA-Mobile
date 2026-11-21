import 'package:flutter/material.dart';

import 'order/views/order_list_screen.dart';
import '../core/widgets/account_page.dart';
import '../core/widgets/floating_navbar.dart';
import '../core/widgets/tab_shell.dart';
import 'product/product_list_screen.dart';
import 'customer/customer_list_screen.dart';
import 'sales/sales_visit_screen.dart';

class ManagerShell extends StatelessWidget {
  const ManagerShell({super.key});

  static const _items = [
    NavItem(label: 'Customer', icon: Icons.storefront_outlined),
    NavItem(label: 'Product', icon: Icons.inventory_2_outlined),
    NavItem(label: 'Sales & Visit', icon: Icons.route_outlined),
    NavItem(label: 'Order', icon: Icons.receipt_long_outlined),
    NavItem(label: 'Account', icon: Icons.person_outline),
  ];

  // Ganti PlaceholderPage dengan layar sungguhan saat fiturnya jadi.
  static const _pages = [
    CustomerListScreen(),
    ProductListScreen(),
    SalesVisitScreen(),
    OrderListScreen(),
    AccountPage(),
  ];

  @override
  Widget build(BuildContext context) =>
      const TabShell(items: _items, pages: _pages);
}
