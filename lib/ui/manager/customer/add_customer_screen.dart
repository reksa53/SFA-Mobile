import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sfa_mobile/data/models/customer_store.dart';
import 'package:sfa_mobile/data/models/sales.dart';
import 'package:sfa_mobile/data/services/customer_service.dart';
import 'package:sfa_mobile/data/services/sales_service.dart';

import '../../core/theme/app_colors.dart';
import 'customer_style.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
    final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _picker = ImagePicker();

  List<Sales> _salesOptions = const [];
  bool _salesLoading = true;
  bool _salesFailed = false;

  int? _salesId;
  int? _visitDay;
  Uint8List? _photo;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ownerCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSales() async {
    setState(() {
      _salesLoading = true;
      _salesFailed = false;
    });
    try {
      final data = await SalesService().fetchAll();
      if (!mounted) return;
      setState(() {
        _salesOptions = data;
        _salesLoading = false;
      });
    } catch (e) {
      debugPrint('LOAD SALES (form) ERROR: $e');
      if (!mounted) return;
      setState(() {
        _salesFailed = true;
        _salesLoading = false;
      });
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 80,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() => _photo = bytes);
    } catch (_) {
      _showMessage('Cannot open camera/gallery');
    }
  }

  void _showPhotoOptions() {
    Widget option(IconData icon, String text, VoidCallback onTap) => ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 14, color: AppColors.white),
      ),
      onTap: onTap,
    );

    showCustSheet<void>(
      context,
      (ctx) => SafeArea(
        child: Wrap(
          children: [
            option(Icons.photo_camera_outlined, 'Take photo', () {
              Navigator.pop(ctx);
              _pickPhoto(ImageSource.camera);
            }),
            option(Icons.photo_library_outlined, 'Choose from gallery', () {
              Navigator.pop(ctx);
              _pickPhoto(ImageSource.gallery);
            }),
            if (_photo != null)
              option(Icons.delete_outline, 'Remove photo', () {
                Navigator.pop(ctx);
                setState(() => _photo = null);
              }),
          ],
        ),
      ),
    );
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await CustomerService().create(
        salesId: _salesId,
        visitDay: _visitDay,
        name: _nameCtrl.text.trim(),
        ownerName: _ownerCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        photoBytes: _photo,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true); // true = daftar perlu di-refresh
    } on DioException catch (e) {
      _showMessage(CustomerService.errorMessage(e));
    } catch (_) {
      _showMessage('Something went wrong, please try again');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Material(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          Icons.chevron_left,
                          color: AppColors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Add Customer',
                    style: GoogleFonts.poppins(
                      color: AppColors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: kCustPanel,
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.antiAlias,
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      Center(
                        child: _PhotoPicker(
                          photo: _photo,
                          onTap: _showPhotoOptions,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _field(
                        controller: _nameCtrl,
                        label: 'Store name',
                        hint: 'Enter store name',
                        required: true,
                        maxLength: 150,
                        textCapitalization: TextCapitalization.words,
                      ),
                      _field(
                        controller: _ownerCtrl,
                        label: 'Owner name',
                        hint: 'Enter owner name',
                        maxLength: 100,
                        textCapitalization: TextCapitalization.words,
                      ),
                      _field(
                        controller: _phoneCtrl,
                        label: 'Phone',
                        hint: 'Enter phone number',
                        maxLength: 20,
                        keyboardType: TextInputType.phone,
                        formatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      _field(
                        controller: _addressCtrl,
                        label: 'Address',
                        hint: 'Enter address',
                        required: true,
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      _salesDropdown(),
                      _dayDropdown(),
                      _field(
                        controller: _notesCtrl,
                        label: 'Notes',
                        hint: 'Optional notes',
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  custSaveButton(
                    onPressed: _saving ? null : _submit,
                    saving: _saving,
                  ),
                  custCancelButton(
                    _saving ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    int? maxLength,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          custLabel(required ? '$label *' : label),
          TextFormField(
            controller: controller,
            style: custInputStyle(),
            cursorColor: AppColors.white,
            maxLength: maxLength,
            maxLines: maxLines,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            inputFormatters: formatters,
            decoration: custDecoration(hint: hint),
            validator: required
                ? (v) => (v == null || v.trim().isEmpty)
                      ? '$label is required'
                      : null
                : null,
          ),
        ],
      ),
    );
  }

  Widget _salesDropdown() {
    final hint = _salesLoading
        ? 'Loading sales...'
        : _salesFailed
        ? 'Failed to load sales'
        : 'Not assigned';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          custLabel('Sales in charge'),
          DropdownButtonFormField<int?>(
            isExpanded: true,
            style: custInputStyle(),
            dropdownColor: kCustPanel,
            iconEnabledColor: Colors.white70,
            decoration: custDecoration(),
            hint: Text(
              hint,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white38),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Not assigned'),
              ),
              for (final s in _salesOptions)
                DropdownMenuItem<int?>(value: s.id, child: Text(s.nama)),
            ],
            onChanged: _salesLoading
                ? null
                : (v) => setState(() => _salesId = v),
            validator: (v) => (_visitDay != null && v == null)
                ? 'Select a sales if a visit day is set'
                : null,
          ),
          if (_salesFailed)
            TextButton(
              onPressed: _loadSales,
              child: Text(
                'Reload sales list',
                style: GoogleFonts.poppins(color: AppColors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dayDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          custLabel('Fixed visit day'),
          DropdownButtonFormField<int?>(
            isExpanded: true,
            style: custInputStyle(),
            dropdownColor: kCustPanel,
            iconEnabledColor: Colors.white70,
            decoration: custDecoration(),
            hint: Text(
              'No fixed schedule',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white38),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('No fixed schedule'),
              ),
              for (final e in kVisitDayNames.entries)
                DropdownMenuItem<int?>(
                  value: e.key,
                  child: Text(customerDayName(e.key)),
                ),
            ],
            onChanged: (v) => setState(() => _visitDay = v),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Text(
              'Used to generate weekly visit schedules automatically.',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.photo, required this.onTap});

  final Uint8List? photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 110,
              height: 110,
              color: kCustField,
              child: photo == null
                  ? const Icon(
                      Icons.storefront_outlined,
                      size: 40,
                      color: Colors.white54,
                    )
                  : Image.memory(photo!, fit: BoxFit.cover),
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
