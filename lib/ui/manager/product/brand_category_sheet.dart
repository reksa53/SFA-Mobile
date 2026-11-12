import 'package:flutter/material.dart';

import '../../../data/services/product_service.dart';
import '/ui/core/widgets/common.dart';

/// Panel pilih brand lalu kategori. Mengembalikan (brand, category) atau null kalau ditutup.
Future<(String?, String?)?> showBrandCategorySheet(
  BuildContext context, {
  String? brand,
  String? category,
}) =>
    showAppSheet<(String?, String?)>(context, (_) => _Picker(brand: brand, category: category));

class _Picker extends StatefulWidget {
  const _Picker({this.brand, this.category});

  final String? brand;
  final String? category;

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  final _svc = ProductService.instance;
  String? _brand;
  String? _category;
  String? _newBrand; // nilai baru yang belum tersimpan di produk mana pun
  String? _newCategory;

  @override
  void initState() {
    super.initState();
    _brand = widget.brand;
    _category = widget.category;
    if (_brand != null && !_svc.knowsBrand(_brand!)) _newBrand = _brand;
    if (_category != null && !_svc.categories.contains(_category)) _newCategory = _category;
  }

  List<String> get _brandOptions => <String>{..._svc.brands, if (_newBrand != null) _newBrand!}.toList()..sort();

  // brand yang belum punya produk: tawarkan semua kategori
  List<String> get _catOptions {
    final b = _brand;
    final base = (b == null || !_svc.knowsBrand(b)) ? _svc.categories : _svc.categoriesFor([b]);
    return <String>{...base, if (_newCategory != null) _newCategory!}.toList()..sort();
  }

  void _pickBrand(String b) => setState(() {
        _brand = b;
        if (_category != null && !_catOptions.contains(_category)) _category = null;
      });

  Future<void> _addBrand() async {
    final v = await showNewValueSheet(
      context,
      title: 'Brand Baru',
      label: 'Nama Brand',
      existing: _brandOptions,
      buttonLabel: 'Pakai Brand Baru',
    );
    if (v == null) return;
    setState(() {
      if (!_svc.knowsBrand(v)) _newBrand = v;
    });
    _pickBrand(v);
  }

  Future<void> _addCategory() async {
    final v = await showNewValueSheet(
      context,
      title: 'Kategori Baru',
      label: 'Nama Kategori',
      existing: _catOptions,
      buttonLabel: 'Pakai Kategori Baru',
    );
    if (v == null) return;
    setState(() {
      if (!_svc.categories.contains(v)) _newCategory = v;
      _category = v;
    });
  }

  @override
  Widget build(BuildContext context) => SheetFrame(
        title: 'Brand & Kategori',
        action: 'Reset',
        onAction: () => setState(() {
          _brand = _category = _newBrand = _newCategory = null;
        }),
        child: Column(children: [
          SheetBox(
            title: '1. Brand',
            caption: 'pilih satu',
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (final b in _brandOptions)
                PillChip(label: b, selected: b == _brand, onTap: () => _pickBrand(b)),
              PillChip(label: 'Brand baru', icon: Icons.add, outlined: true, onTap: _addBrand),
            ]),
          ),
          SheetBox(
            title: '2. Kategori',
            caption: _brand == null ? null : 'sesuai brand terpilih',
            dim: _brand == null,
            child: _brand == null
                ? const Row(children: [
                    Icon(Icons.lock_outline, size: 16, color: kTextMuted),
                    SizedBox(width: 8),
                    Text('Pilih brand dulu.', style: TextStyle(fontSize: 13, color: kTextMuted)),
                  ])
                : Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final c in _catOptions)
                      PillChip(
                        label: c,
                        icon: categoryIcon(c),
                        selected: c == _category,
                        onTap: () => setState(() => _category = c == _category ? null : c),
                      ),
                    PillChip(label: 'Kategori baru', icon: Icons.add, outlined: true, onTap: _addCategory),
                  ]),
          ),
          const SizedBox(height: 16),
          PillButton(
            'Pilih',
            onPressed: _brand == null ? null : () => Navigator.pop(context, (_brand, _category)),
          ),
        ]),
      );
}

/// Panel ketik brand/kategori baru, dengan saran yang mirip supaya tidak dobel.
Future<String?> showNewValueSheet(
  BuildContext context, {
  required String title,
  required String label,
  required List<String> existing,
  required String buttonLabel,
}) =>
    showAppSheet<String>(
      context,
      (_) => _NewValue(title: title, label: label, existing: existing, buttonLabel: buttonLabel),
    );

class _NewValue extends StatefulWidget {
  const _NewValue({required this.title, required this.label, required this.existing, required this.buttonLabel});

  final String title;
  final String label;
  final List<String> existing;
  final String buttonLabel;

  @override
  State<_NewValue> createState() => _NewValueState();
}

class _NewValueState extends State<_NewValue> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String get _typed => _c.text.trim();

  List<String> get _similar {
    final t = _typed.toLowerCase();
    if (t.isEmpty) return [];
    return widget.existing.where((e) {
      final l = e.toLowerCase();
      return l.contains(t) || t.contains(l);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final similar = _similar;
    return SheetFrame(
      title: widget.title,
      action: 'Batal',
      actionColor: kTextMuted,
      onAction: () => Navigator.pop(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 16),
        Labeled(
          widget.label,
          TextField(
            controller: _c,
            autofocus: true,
            maxLength: 100, // sama dengan string(100) di ERD
            style: kInputStyle,
            onChanged: (_) => setState(() {}),
            decoration: boxDecoration(hint: 'Ketik ${widget.label.toLowerCase()}')
                .copyWith(counterStyle: const TextStyle(fontSize: 11, color: kTextMuted)),
          ),
        ),
        SheetBox(
          title: 'Mirip dengan yang sudah ada',
          child: _typed.isEmpty
              ? const Text('Mulai mengetik untuk melihat yang mirip.',
                  style: TextStyle(fontSize: 13, color: kTextMuted))
              : similar.isEmpty
                  ? const Text('Belum ada yang mirip.', style: TextStyle(fontSize: 13, color: kTextMuted))
                  : Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final e in similar)
                        PillChip(label: e, icon: categoryIcon(e) == Icons.sell_outlined ? null : categoryIcon(e), onTap: () => Navigator.pop(context, e)),
                    ]),
        ),
        const SizedBox(height: 8),
        const Text('Ketuk yang mirip untuk memakainya, supaya tidak ada duplikat.',
            style: TextStyle(fontSize: 11, color: kTextMuted)),
        const SizedBox(height: 16),
        PillButton(
          widget.buttonLabel,
          onPressed: _typed.isEmpty
              ? null
              : () => Navigator.pop(
                    context,
                    // ketikan sama persis (beda huruf besar/kecil) -> pakai ejaan yang sudah ada
                    widget.existing.firstWhere((e) => e.toLowerCase() == _typed.toLowerCase(), orElse: () => _typed),
                  ),
        ),
      ]),
    );
  }
}