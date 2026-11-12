import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/sales.dart';
import '../../core/theme/app_colors.dart';

/// Pilihan di menu ganti foto.
enum _FotoAksi { kamera, galeri, hapus }

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
  bool _hidePassword = true;
  final _picker = ImagePicker();
  Uint8List? _foto; // foto yang dipilih (null = belum ada)

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _telepon.dispose();
    _password.dispose();
    super.dispose();
  }

  void _simpan() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // TODO: kirim ke API (Manager mendaftarkan akun dengan role sales),
    // lalu pakai id dari response server, bukan id sementara ini.
    final baru = Sales(
      id: DateTime.now().millisecondsSinceEpoch,
      nama: _nama.text.trim(),
      fotoBytes: _foto,
    );
    Navigator.of(context).pop(baru);
  }

  /// Ketuk lingkaran foto -> muncul menu: kamera, galeri, atau hapus foto.
  Future<void> _pilihFoto() async {
    final aksi = await showModalBottomSheet<_FotoAksi>(
      context: context,
      backgroundColor: AppColors.white,
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
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            _FotoMenuItem(
              icon: Icons.photo_camera_outlined,
              label: 'Ambil dari kamera',
              onTap: () => Navigator.pop(ctx, _FotoAksi.kamera),
            ),
            _FotoMenuItem(
              icon: Icons.photo_library_outlined,
              label: 'Pilih dari galeri',
              onTap: () => Navigator.pop(ctx, _FotoAksi.galeri),
            ),
            if (_foto != null)
              _FotoMenuItem(
                icon: Icons.delete_outline,
                label: 'Hapus foto',
                color: AppColors.red,
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
        const SnackBar(content: Text('Tidak bisa membuka kamera/galeri')),
      );
    }
  }

  String? _wajib(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null;

  String? _cekEmail(String? v) {
    final salah = _wajib(v, 'Email');
    if (salah != null) return salah;
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v!.trim());
    return ok ? null : 'Format email tidak valid';
  }

  String? _cekTelepon(String? v) {
    final salah = _wajib(v, 'No. telepon');
    if (salah != null) return salah;
    final angka = v!.replaceAll(RegExp(r'[\s\-+]'), '');
    final ok = RegExp(r'^\d{9,15}$').hasMatch(angka);
    return ok ? null : 'No. telepon tidak valid';
  }

  String? _cekPassword(String? v) {
    if (v == null || v.isEmpty) return 'Password wajib diisi';
    return v.length < 8 ? 'Password minimal 8 karakter' : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Judul halaman (tanpa tombol cari, karena tidak ada daftar).
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: SizedBox(
                height: 44,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Add Sales',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
            // Expanded + Center + maxHeight: kotak putih tingginya paling besar
            // 550, tetap di tengah, dan MENGECIL otomatis saat keyboard muncul
            // (isinya bisa digulir) sehingga tidak ada garis overflow.
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 550, // ← tinggi kotak putih, ubah angka ini
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Material(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  clipBehavior: Clip.antiAlias,
                  child: LayoutBuilder(
                    builder: (context, box) => SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 40),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: math.max(0.0, box.maxHeight - 80),
                        ),
                        // Center = isi form tepat di tengah kotak putih
                        // (atas-bawah dan kiri-kanan).
                        child: Align(
                        alignment: Alignment.topCenter,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: _FotoPicker(
                                    nama: _nama,
                                    foto: _foto,
                                    onTap: _pilihFoto,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _Field(
                                  label: 'Nama Lengkap',
                                  controller: _nama,
                                  hint: 'Contoh: Icha Clowy',
                                  icon: Icons.person_outline,
                                  keyboardType: TextInputType.name,
                                  textCapitalization: TextCapitalization.words,
                                  validator: (v) => _wajib(v, 'Nama'),
                                ),
                                const SizedBox(height: 16),
                                _Field(
                                  label: 'Email',
                                  controller: _email,
                                  hint: 'nama@perusahaan.com',
                                  icon: Icons.mail_outline,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _cekEmail,
                                ),
                                const SizedBox(height: 16),
                                _Field(
                                  label: 'No. Telepon',
                                  controller: _telepon,
                                  hint: '08xxxxxxxxxx',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  validator: _cekTelepon,
                                ),
                                const SizedBox(height: 16),
                                _Field(
                                  label: 'Password',
                                  controller: _password,
                                  hint: 'Minimal 8 karakter',
                                  icon: Icons.lock_outline,
                                  obscure: _hidePassword,
                                  textInputAction: TextInputAction.done,
                                  validator: _cekPassword,
                                  onSubmitted: (_) => _simpan(),
                                  suffix: IconButton(
                                    tooltip: _hidePassword
                                        ? 'Tampilkan password'
                                        : 'Sembunyikan password',
                                    onPressed: () => setState(
                                        () => _hidePassword = !_hidePassword),
                                    icon: Icon(
                                      _hidePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppColors.black,
                                    ),
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
            ),
            ),
            _BottomBar(
              onBack: () => Navigator.of(context).maybePop(),
              onSave: _simpan,
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
    required this.nama,
    required this.foto,
    required this.onTap,
  });

  final TextEditingController nama;
  final Uint8List? foto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gambar = foto;

    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 96,
        height: 96,
        child: Stack(
          children: [
            Positioned.fill(
              child: gambar != null
                  ? CircleAvatar(
                      backgroundColor: AppColors.grey,
                      backgroundImage: MemoryImage(gambar),
                    )
                  : ValueListenableBuilder<TextEditingValue>(
                      valueListenable: nama,
                      builder: (_, value, __) {
                        final teks = value.text.trim().isEmpty
                            ? null
                            : Sales(id: 0, nama: value.text).inisial;
                        return CircleAvatar(
                          backgroundColor: AppColors.grey,
                          child: teks == null
                              ? const Icon(Icons.person,
                                  size: 48, color: AppColors.black)
                              : Text(
                                  teks,
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.black,
                                  ),
                                ),
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
                  border: Border.all(color: AppColors.white, width: 2),
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
    this.color = AppColors.black,
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

/// Satu kolom isian: label di atas, kotak abu muda di bawahnya.
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
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
          style: GoogleFonts.poppins(fontSize: 15, color: AppColors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black38,
            ),
            errorStyle: GoogleFonts.poppins(fontSize: 12),
            prefixIcon: Icon(icon, color: Colors.black54),
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xFFF1F1F1),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: _border(Colors.transparent),
            enabledBorder: _border(Colors.transparent),
            focusedBorder: _border(AppColors.red),
            errorBorder: _border(AppColors.red),
            focusedErrorBorder: _border(AppColors.red),
          ),
        ),
      ],
    );
  }
}

/// Baris bawah: "back" di kiri, tombol SIMPAN di kanan (gaya sama dengan
/// layar Visit).
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.onBack, required this.onSave});

  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onBack,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chevron_left,
                      size: 24, color: AppColors.white),
                  Text(
                    'back',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 183,
            height: 40,
            child: FilledButton(
              onPressed: onSave,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: AppColors.white,
                shape: const StadiumBorder(),
              ),
              child: Text(
                'Simpan',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
