import 'package:flutter/material.dart';

import 'app_header.dart';

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppHeader(title: 'CENTRAL SINN'),
        Expanded(
          child: Center(child: Text('Halaman $title belum dibuat')),
        ),
      ],
    );
  }
}