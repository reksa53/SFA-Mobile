import 'package:flutter/material.dart';
import 'package:sfa_mobile/ui/sales/order/views/sales_order_list_screen.dart';
import 'package:sfa_mobile/ui/sales/visit/sales_visit_screen.dart';
import 'package:sfa_mobile/ui/sales/product/sales_product_list_screen.dart';
import 'package:sfa_mobile/ui/sales/customer/sales_customer_list_screen.dart';

import '../core/widgets/account_page.dart';
import '../core/widgets/floating_navbar.dart';
import '../core/widgets/tab_shell.dart';

class SalesShell extends StatelessWidget {
  const SalesShell({super.key});

  static const _items = [
    NavItem(label: 'Customer', icon: Icons.storefront_outlined),
    NavItem(label: 'Product', icon: Icons.inventory_2_outlined),
    NavItem(label: 'Visit', icon: Icons.pin_drop_outlined),
    NavItem(label: 'Order', icon: Icons.receipt_long_outlined),
    NavItem(label: 'Account', icon: Icons.person_outline),
  ];

  static const _pages = [
    SalesCustomerListScreen(canEdit: false),
    SalesProductListScreen(),
    SalesVisitScreen(),
    SalesOrderListScreen(),
    AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return const TabShell(items: _items, pages: _pages);
  }
}
