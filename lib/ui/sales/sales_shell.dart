import 'package:flutter/material.dart';
import 'package:sfa_mobile/ui/sales/order/views/sales_order_list_screen.dart';
import 'package:sfa_mobile/ui/sales/visit/sales_visit_screen.dart';

import '../core/widgets/floating_navbar.dart';
import '../core/widgets/tab_shell.dart';

class SalesShell extends StatelessWidget {
  const SalesShell({super.key});

  static const _items = [
    NavItem(label: 'Visit', icon: Icons.pin_drop_outlined),
    NavItem(label: 'Order', icon: Icons.receipt_long_outlined),
  ];

  static const _pages = [
    SalesVisitScreen(),
    SalesOrderListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return const TabShell(items: _items, pages: _pages);
  }
}
