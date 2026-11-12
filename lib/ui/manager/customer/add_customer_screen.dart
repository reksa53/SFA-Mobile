import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';

/// Opsi sales untuk dropdown. Data dummy, ganti dengan hasil API
/// (users dengan role = 'sales' dan is_active = true).
class SalesOption {
  const SalesOption({required this.id, required this.name});
  final int id;
  final String name;
}

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  static const _background = Color(0xFF3A3A3A);

  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _picker = ImagePicker();

  // TODO: ambil dari API.
  final List<SalesOption> _salesOptions = const [
    SalesOption(id: 1, name: 'Sales A'),
    SalesOption(id: 2, name: 'Sales B'),
    SalesOption(id: 3, name: 'Sales C'),
  ];

  int? _salesId;
  File? _photo;
  bool _saving = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _ownerCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1280,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Ambil foto'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_photo != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Hapus foto'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _photo = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Nama key sama dengan kolom tabel customers.
    final fields = <String, String>{
      'assigned_sales_id': '$_salesId',
      'code': _codeCtrl.text.trim(),
      'name': _nameCtrl.text.trim(),
      'owner_name': _ownerCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'notes': _notesCtrl.text.trim(),
    }..removeWhere((k, v) => v.isEmpty);

    setState(() => _saving = true);

    // TODO: kirim `fields` + file `_photo` (multipart, field 'photo')
    // ke POST /customers lewat service. Tampilkan error validasi server
    // (mis. code sudah dipakai) di field terkait.
    debugPrint('Add customer: $fields, photo: ${_photo?.path}');

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.chevron_left,
                      color: AppColors.white,
                      size: 30,
                    ),
                  ),
                  const Text(
                    'Add Customer',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.antiAlias,
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Center(
                        child: _PhotoPicker(
                          photo: _photo,
                          onTap: _showPhotoOptions,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _field(
                        controller: _codeCtrl,
                        label: 'Kode Customer',
                        required: true,
                        maxLength: 20,
                        textCapitalization: TextCapitalization.characters,
                      ),
                      _field(
                        controller: _nameCtrl,
                        label: 'Nama Toko',
                        required: true,
                        maxLength: 150,
                        textCapitalization: TextCapitalization.words,
                      ),
                      _field(
                        controller: _ownerCtrl,
                        label: 'Nama Pemilik',
                        maxLength: 100,
                        textCapitalization: TextCapitalization.words,
                      ),
                      _field(
                        controller: _phoneCtrl,
                        label: 'No. Telepon',
                        maxLength: 20,
                        keyboardType: TextInputType.phone,
                        formatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      _field(
                        controller: _addressCtrl,
                        label: 'Alamat',
                        required: true,
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      _salesDropdown(),
                      _field(
                        controller: _notesCtrl,
                        label: 'Catatan',
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.white,
                        side: const BorderSide(color: AppColors.white),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.red,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, {bool required = false}) {
    return InputDecoration(
      labelText: required ? '$label *' : label,
      counterText: '',
      filled: true,
      fillColor: const Color(0xFFF3F3F3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.red, width: 1.5),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    bool required = false,
    int? maxLength,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLength: maxLength,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: formatters,
        decoration: _decoration(label, required: required),
        validator: required
            ? (v) =>
                  (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null
            : null,
      ),
    );
  }

  Widget _salesDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<int>(
        isExpanded: true,
        decoration: _decoration('Sales yang Menangani', required: true),
        items: [
          for (final s in _salesOptions)
            DropdownMenuItem(value: s.id, child: Text(s.name)),
        ],
        onChanged: (v) => setState(() => _salesId = v),
        validator: (v) => v == null ? 'Pilih sales untuk customer ini' : null,
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.photo, required this.onTap});

  final File? photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 110,
              height: 110,
              color: const Color(0xFFA8A8A8),
              child: photo == null
                  ? const Icon(
                      Icons.storefront_outlined,
                      size: 40,
                      color: AppColors.white,
                    )
                  : Image.file(photo!, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.photo_camera,
                size: 16,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
