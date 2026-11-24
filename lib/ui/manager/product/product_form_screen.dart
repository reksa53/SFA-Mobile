import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/product.dart';
import '../../../data/services/product_service.dart';
import '/utils/format.dart';
import '../../core/theme/app_colors.dart';
import '/ui/core/widgets/common.dart';
import 'brand_category_sheet.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _svc = ProductService.instance;
  final _key = GlobalKey<FormState>();
  final _sku = TextEditingController();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _batchNo = TextEditingController();
  final _qty = TextEditingController();
  String? _brand;
  String? _category;
  static const _unit = 'box'; // satuan dikunci: semua produk dijual per box
  bool _active = true;
  DateTime? _expiry;
  DateTime _received = today();
  XFile? _photo;

  @override
  void dispose() {
    for (final c in [_sku, _name, _price, _batchNo, _qty]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) => (v?.trim().isEmpty ?? true) ? 'Wajib diisi' : null;

  Future<void> _pickBrandCategory() async {
    final r = await showBrandCategorySheet(context, brand: _brand, category: _category);
    if (r != null) {
      setState(() {
        _brand = r.$1;
        _category = r.$2;
      });
    }
  }

  Future<void> _pickPhoto() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1200);
    if (x != null) setState(() => _photo = x);
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _svc.create(
        sku: _sku.text.trim(),
        name: _name.text.trim(),
        brand: _svc.canon(_brand, _svc.brands),
        category: _svc.canon(_category, _svc.categories),
        unit: _unit,
        price: int.parse(_price.text),
        active: _active,
        batchNumber: _batchNo.text.trim(),
        expiry: _expiry,
        qty: int.parse(_qty.text),
        received: _received,
        photo: _photo,
      );
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Produk disimpan')));
    } on DioException catch (e) {
      final errors = e.response?.data is Map ? e.response!.data['errors'] as Map? : null;
      messenger.showSnackBar(SnackBar(
        content: Text(e.response?.statusCode == 422
            ? (errors == null ? 'Data tidak valid' : '${(errors.values.first as List).first}')
            : 'Gagal menyimpan produk'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bc = _brand == null ? null : [_brand, _category].whereType<String>().join(' · ');
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Row(children: [
              BackBtn(),
              SizedBox(width: 14),
              Text('Tambah Produk',
                  style: TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Form(
                key: _key,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _Card([
                    GestureDetector(
                      onTap: _pickPhoto,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF767676)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: _photo == null
                                ? const Icon(Icons.photo_camera_outlined, color: kTextMuted)
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.file(File(_photo!.path), fit: BoxFit.cover),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Foto Produk',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.black)),
                            SizedBox(height: 4),
                            Text('Opsional', style: TextStyle(fontSize: 13, color: kTextMuted)),
                          ]),
                        ]),
                      ),
                    ),
                    Labeled(
                      'SKU',
                      TextFormField(
                        controller: _sku,
                        style: kInputStyle,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [LengthLimitingTextInputFormatter(30)],
                        decoration: boxDecoration(),
                        validator: (v) {
                          if (_required(v) != null) return 'Wajib diisi';
                          return _svc.skuExists(v!.trim()) ? 'SKU sudah dipakai' : null;
                        },
                      ),
                    ),
                    Labeled(
                      'Nama Produk',
                      TextFormField(
                        controller: _name,
                        style: kInputStyle,
                        inputFormatters: [LengthLimitingTextInputFormatter(150)],
                        decoration: boxDecoration(),
                        validator: _required,
                      ),
                    ),
                    Labeled(
                      'Brand & Kategori',
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        TapField(
                          value: bc,
                          hint: 'Pilih brand & kategori',
                          icon: Icons.expand_more,
                          onTap: _pickBrandCategory,
                        ),
                        const SizedBox(height: 6),
                        const Text('Pilih brand dulu, lalu kategori. Boleh ketik baru.',
                            style: TextStyle(fontSize: 11, color: kTextMuted)),
                      ]),
                    ),
                    Labeled(
                      'Harga per box',
                      TextFormField(
                        controller: _price,
                        style: kInputStyle,
                        keyboardType: TextInputType.number,
                        inputFormatters: kDigitsOnly,
                        decoration: boxDecoration(prefix: 'Rp '),
                        validator: _required,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(children: [
                        const Expanded(
                          child: Text('Produk Aktif',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.black)),
                        ),
                        Switch(
                          value: _active,
                          activeThumbColor: AppColors.white,
                          activeTrackColor: AppColors.red,
                          onChanged: (v) => setState(() => _active = v),
                        ),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  const Text('Stok Awal (Batch Pertama)',
                      style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _Card([
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(
                        child: Labeled(
                          'Nomor Batch',
                          TextFormField(
                            controller: _batchNo,
                            style: kInputStyle,
                            inputFormatters: [LengthLimitingTextInputFormatter(50)],
                            decoration: boxDecoration(),
                            validator: _required,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Labeled(
                          'Jumlah',
                          TextFormField(
                            controller: _qty,
                            style: kInputStyle,
                            keyboardType: TextInputType.number,
                            inputFormatters: kDigitsOnly,
                            decoration: boxDecoration(suffix: _unit),
                            validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1 ? 'Min. 1' : null,
                          ),
                        ),
                      ),
                    ]),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(
                        child: Labeled(
                          'Tanggal Expired',
                          TapField(
                            value: _expiry == null ? null : fmtDate(_expiry!),
                            hint: 'Opsional',
                            icon: Icons.calendar_today_outlined,
                            onTap: () async {
                              final d = await pickDate(context, _expiry);
                              if (d != null) setState(() => _expiry = d);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Labeled(
                          'Diterima',
                          TapField(
                            value: fmtDate(_received),
                            hint: '',
                            icon: Icons.calendar_today_outlined,
                            onTap: () async {
                              final d = await pickDate(context, _received);
                              if (d != null) setState(() => _received = d);
                            },
                          ),
                        ),
                      ),
                    ]),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text('Expired boleh kosong untuk produk tanpa masa kedaluwarsa.',
                          style: TextStyle(fontSize: 11, color: kTextMuted)),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: PillButton('Simpan Produk', onPressed: _save),
          ),
        ]),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card(this.children);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );
}