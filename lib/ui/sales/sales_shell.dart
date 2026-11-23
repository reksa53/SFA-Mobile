import 'package:flutter/material.dart';
import 'package:sfa_mobile/ui/sales/order/views/sales_order_list_screen.dart';
import 'package:sfa_mobile/ui/sales/visit/sales_visit_screen.dart';
import 'package:sfa_mobile/ui/sales/product/sales_product_list_screen.dart';

import '../core/widgets/floating_navbar.dart';
import '../core/widgets/placeholder_page.dart';
import '../core/widgets/tab_shell.dart';
import '../manager/customer/customer_list_screen.dart';
import 'home/sales_home_screen.dart';

class SalesShell extends StatelessWidget {
  const SalesShell({super.key});

  // Profil, tema, dan logout ada di sidebar (tombol hamburger di Home).
  static const _items = [
    NavItem(label: 'Home', icon: Icons.home_outlined),
    NavItem(label: 'Customer', icon: Icons.storefront_outlined),
    NavItem(label: 'Product', icon: Icons.inventory_2_outlined),
    NavItem(label: 'Visit', icon: Icons.pin_drop_outlined),
    NavItem(label: 'Order', icon: Icons.receipt_long_outlined),
  ];

  static const _pages = [
    SalesHomeScreen(),
    CustomerListScreen(),
    SalesProductListScreen(),
    SalesVisitScreen(),
    SalesOrderListScreen(),
  ];

  @override
  Widget build(BuildContext context) =>
      const TabShell(items: _items, pages: _pages);
}
