import 'package:flutter/material.dart';

import '../core/widgets/floating_navbar.dart';
import '../core/widgets/tab_shell.dart';
import 'customer/customer_list_screen.dart';
import 'home/manager_home_screen.dart';
import 'order/views/order_list_screen.dart';
import 'product/product_list_screen.dart';
import 'sales/sales_visit_screen.dart';

class ManagerShell extends StatelessWidget {
  const ManagerShell({super.key});

  // Profil, tema, dan logout ada di sidebar (tombol hamburger di Home),
  // jadi tab "Akun" tidak diperlukan lagi.
  static const _items = [
    NavItem(label: 'Home', icon: Icons.home_outlined),
    NavItem(label: 'Customer', icon: Icons.storefront_outlined),
    NavItem(label: 'Product', icon: Icons.inventory_2_outlined),
    NavItem(label: 'Sales & Visit', icon: Icons.route_outlined),
    NavItem(label: 'Order', icon: Icons.receipt_long_outlined),
  ];

  static const _pages = [
    ManagerHomeScreen(),
    CustomerListScreen(),
    ProductListScreen(),
    SalesVisitScreen(),
    OrderListScreen(),
  ];

  @override
  Widget build(BuildContext context) =>
      const TabShell(items: _items, pages: _pages);
}
