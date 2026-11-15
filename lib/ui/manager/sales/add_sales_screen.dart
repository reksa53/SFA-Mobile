import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/sales.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/manager_colors.dart';
import 'sales_avatar.dart';

/// Pilihan di menu ganti foto.
enum _FotoAksi { kamera, galeri, hapus }

/// Warna dasar kolom isian (gelap).
const _warnaKolom = Color(0xFF3F3F3F);

/// Layar "Add Sales": form untuk menambah akun sales baru.
/// Dibuka dari tombol "Add Sales" di SalesVisitScreen dan menutupi navbar.
///
/// Saat ini hanya UI. Setelah tombol SIMPAN ditekan dan form valid, layar
/// menutup dan mengembalikan objek [Sales] ke layar sebelumnya.
class AddSalesScreen extends StatefulWidget {
  const AddSalesScreen({super.key});

  @override
  State<AddSalesScreen> createState() => _AddSalesScreenState();
}

class _AddSalesScreenState extends State<AddSalesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _telepon = TextEditingController();
  final _password = TextEditingController();
  final _konfirmasi = TextEditingController();
  bool _hidePassword = true;
  bool _hideKonfirmasi = true;
  final _picker = ImagePicker();
  Uint8List? _foto; // foto yang dipilih (null = belum ada)

  // Id sementara; dipakai juga untuk warna avatar supaya warnanya sama
  // dengan yang tampil di daftar sales.
  final int _id = DateTime.now().millisecondsSinceEpoch;

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _telepon.dispose();
    _password.dispose();
    _konfirmasi.dispose();
    super.dispose();
  }

  void _simpan() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // TODO: kirim ke API (Manager mendaftarkan akun dengan role sales),
    // lalu pakai id dari response server, bukan id sementara ini.
    final baru = Sales(
      id: _id,
      nama: _nama.text.trim(),
      fotoBytes: _foto,
    );
    Navigator.of(context).pop(baru);
  }

  /// Ketuk lingkaran foto -> muncul menu: kamera, galeri, atau hapus foto.
  Future<void> _pilihFoto() async {
    final aksi = await showModalBottomSheet<_FotoAksi>(
      context: context,
      backgroundColor: const Color(0xFF565656),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            _FotoMenuItem(
              icon: Icons.photo_camera_outlined,
              label: 'Take photo',
              onTap: () => Navigator.pop(ctx, _FotoAksi.kamera),
            ),
            _FotoMenuItem(
              icon: Icons.photo_library_outlined,
              label: 'Choose from gallery',
              onTap: () => Navigator.pop(ctx, _FotoAksi.galeri),
            ),
            if (_foto != null)
              _FotoMenuItem(
                icon: Icons.delete_outline,
                label: 'Remove photo',
                color: const Color(0xFFFF8A8A),
                onTap: () => Navigator.pop(ctx, _FotoAksi.hapus),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (aksi == null) return; // menu ditutup tanpa memilih
    if (aksi == _FotoAksi.hapus) {
      setState(() => _foto = null);
      return;
    }
    await _ambilFoto(
      aksi == _FotoAksi.kamera ? ImageSource.camera : ImageSource.gallery,
    );
  }

  Future<void> _ambilFoto(ImageSource sumber) async {
    try {
      final file = await _picker.pickImage(
        source: sumber,
        maxWidth: 800, // kecilkan supaya ringan dikirim ke server nanti
        maxHeight: 800,
        imageQuality: 85,
      );
      if (file == null) return; // pengguna membatalkan
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _foto = bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open camera/gallery')),
      );
    }
  }

  String? _wajib(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label is required' : null;

  String? _cekEmail(String? v) {
    final salah = _wajib(v, 'Email');
    if (salah != null) return salah;
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v!.trim());
    return ok ? null : 'Invalid email format';
  }

  String? _cekTelepon(String? v) {
    final salah = _wajib(v, 'Phone number');
    if (salah != null) return salah;
    final angka = v!.replaceAll(RegExp(r'[\s\-+]'), '');
    final ok = RegExp(r'^\d{9,15}$').hasMatch(angka);
    return ok ? null : 'Invalid phone number';
  }

  String? _cekPassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    return v.length < 8 ? 'Password must be at least 8 characters' : null;
  }

  String? _cekKonfirmasi(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    return v == _password.text ? null : 'Passwords do not match';
  }

  Widget _mata(bool tersembunyi, VoidCallback onTap) => IconButton(
        tooltip: tersembunyi ? 'Show password' : 'Hide password',
        onPressed: onTap,
        icon: Icon(
          tersembunyi
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: Colors.white70,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header: tombol back + judul (sama seperti layar Visit).
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    Material(
                      color: const Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.of(context).maybePop(),
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(Icons.chevron_left,
                              size: 28, color: AppColors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Add Sales',
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Box abu-abu memenuhi sisa layar sampai tombol SIMPAN. Isinya
            // tersebar merata; kalau layar pendek / keyboard muncul, bisa digulir.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: ManagerColors.calendar,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: LayoutBuilder(
                    builder: (context, box) => SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: math.max(0.0, box.maxHeight - 40),
                        ),
                        child: IntrinsicHeight(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 26),
                                Center(
                                  child: _FotoPicker(
                                    id: _id,
                                    nama: _nama,
                                    foto: _foto,
                                    onTap: _pilihFoto,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                _Field(
                                  label: 'Full Name',
                                  controller: _nama,
                                  hint: 'Example: Icha Clowy',
                                  icon: Icons.person,
                                  keyboardType: TextInputType.name,
                                  textCapitalization: TextCapitalization.words,
                                  validator: (v) => _wajib(v, 'Name'),
                                ),
                                const SizedBox(height: 28),
                                _Field(
                                  label: 'Email',
                                  controller: _email,
                                  hint: 'name@company.com',
                                  icon: Icons.mail,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _cekEmail,
                                ),
                                const SizedBox(height: 28),
                                _Field(
                                  label: 'Phone Number',
                                  controller: _telepon,
                                  hint: '08xxxxxxxxxx',
                                  icon: Icons.phone,
                                  keyboardType: TextInputType.phone,
                                  validator: _cekTelepon,
                                ),
                                const SizedBox(height: 28),
                                _Field(
                                  label: 'Password',
                                  controller: _password,
                                  hint: 'At least 8 characters',
                                  icon: Icons.lock,
                                  obscure: _hidePassword,
                                  validator: _cekPassword,
                                  suffix: _mata(
                                    _hidePassword,
                                    () => setState(
                                        () => _hidePassword = !_hidePassword),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                _Field(
                                  label: 'Confirm Password',
                                  controller: _konfirmasi,
                                  hint: 'Repeat password',
                                  icon: Icons.lock,
                                  obscure: _hideKonfirmasi,
                                  textInputAction: TextInputAction.done,
                                  validator: _cekKonfirmasi,
                                  onSubmitted: (_) => _simpan(),
                                  suffix: _mata(
                                    _hideKonfirmasi,
                                    () => setState(() =>
                                        _hideKonfirmasi = !_hideKonfirmasi),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _simpan,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.red,
                    foregroundColor: AppColors.white,
                    minimumSize: Size.zero,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    'SAVE',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lingkaran foto di atas form. Kalau sudah ada foto, tampilkan foto itu;
/// kalau belum, tampilkan inisial nama (ikut berubah saat nama diketik).
class _FotoPicker extends StatelessWidget {
  const _FotoPicker({
    required this.id,
    required this.nama,
    required this.foto,
    required this.onTap,
  });

  final int id;
  final TextEditingController nama;
  final Uint8List? foto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 96,
        height: 96,
        child: Stack(
          children: [
            Positioned.fill(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: nama,
                builder: (_, value, __) {
                  final kosong = value.text.trim().isEmpty && foto == null;
                  if (kosong) {
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.grey,
                        border: Border.all(color: Colors.white38, width: 2),
                      ),
                      child: const Icon(Icons.person,
                          size: 48, color: AppColors.black),
                    );
                  }
                  return SalesAvatar(
                    sales: Sales(id: id, nama: value.text, fotoBytes: foto),
                    size: 96,
                  );
                },
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.red,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: ManagerColors.calendar, width: 2),
                ),
                child: const Icon(Icons.camera_alt,
                    size: 16, color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu baris di menu ganti foto.
class _FotoMenuItem extends StatelessWidget {
  const _FotoMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.white,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      onTap: onTap,
    );
  }
}

/// Satu kolom isian: label di atas, kotak gelap di bawahnya.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction = TextInputAction.next,
    this.obscure = false,
    this.suffix,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;
  final bool obscure;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: 1.5),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscure,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          cursorColor: AppColors.red,
          style: GoogleFonts.poppins(fontSize: 14.5, color: AppColors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white38,
            ),
            errorStyle: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFFFF8A8A),
            ),
            prefixIcon: Icon(icon, size: 20, color: Colors.white54),
            suffixIcon: suffix,
            filled: true,
            fillColor: _warnaKolom,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: _border(Colors.transparent),
            enabledBorder: _border(Colors.transparent),
            focusedBorder: _border(AppColors.red),
            errorBorder: _border(const Color(0xFFFF8A8A)),
            focusedErrorBorder: _border(AppColors.red),
          ),
        ),
      ],
    );
  }
}
