import 'package:flutter/widgets.dart';

class NavDestination {
  const NavDestination({
    required this.label,
    required this.iconAsset,
    required this.builder,
  });

  final String label;
  final String iconAsset;
  final WidgetBuilder builder;
}