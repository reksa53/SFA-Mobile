import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sfa_mobile/data/services/api_client.dart';
import 'package:sfa_mobile/ui/auth/views/login_screen.dart';

import '../theme/app_colors.dart';
import 'photo_picker_sheet.dart';

/// Tab "Account": info singkat dan tombol logout. Dipakai Manager dan Sales.
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String? _role;
  bool _loggingOut = false;
  String? _photoUrl;
  bool _savingPhoto = false;

  @override
  void initState() {
    super.initState();
    ApiClient.instance.getPhotoUrl().then((u) {
      if (mounted) setState(() => _photoUrl = u);
    });
    ApiClient.instance.getRole().then((r) {
      if (mounted) setState(() => _role = r);
    });
  }

  String get _roleLabel => switch (_role) {
    'manager' => 'Manager',
    'sales' => 'Sales',
    _ => '-',
  };

  /// Ganti atau hapus foto profil akun sendiri (ketuk avatar).
  Future<void> _changePhoto() async {
    final choice = await choosePhoto(context, canRemove: _photoUrl != null);
    if (choice == null || !mounted) return;

    setState(() => _savingPhoto = true);
    String message;
    try {
      final url = await ApiClient.instance.updateMyPhoto(
        bytes: choice.bytes,
        remove: choice.remove,
      );
      if (!mounted) return;
      setState(() => _photoUrl = url);
      message = choice.remove ? 'Photo removed' : 'Photo updated';
    } catch (e) {
      message = 'Failed to update photo';
      if (e is DioException) {
        final data = e.response?.data;
        if (e.response == null) {
          message = 'Cannot reach the server';
        } else if (data is Map &&
            data['errors'] is Map &&
            (data['errors'] as Map).isNotEmpty) {
          final first = (data['errors'] as Map).values.first;
          if (first is List && first.isNotEmpty) message = first.first.toString();
        }
      }
    }
    if (!mounted) return;
    setState(() => _savingPhoto = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmLogout() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF565656),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Log out?',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        content: Text(
          'You will need to log in again to use the app.',
          style: GoogleFonts.poppins(fontSize: 13.5, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Log out',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFF8A8A),
              ),
            ),
          ),
        ],
      ),
    );
    if (yakin != true || !mounted) return;

    setState(() => _loggingOut = true);
    // logout() selalu menghapus token lokal, walau request ke server gagal.
    await ApiClient.instance.logout();
    if (!mounted) return;

    // Kosongkan semua halaman, kembali ke Login.
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul sama seperti ManagerHeader (tanpa tombol cari).
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: SizedBox(
                height: 44,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Account',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
            // Kartu profil
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Material(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _EditableAvatar(
                        photoUrl: _photoUrl,
                        busy: _savingPhoto,
                        onTap: _savingPhoto ? null : _changePhoto,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Logged in as',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF777777),
                              ),
                            ),
                            Text(
                              _roleLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Baris Log out di dalam kotak putih (gaya daftar Sales & Visit).
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Material(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _loggingOut ? null : _confirmLogout,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFDE8E8),
                          ),
                          child: _loggingOut
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.red,
                                  ),
                                )
                              : const Icon(
                                  Icons.logout,
                                  size: 20,
                                  color: AppColors.red,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Log out',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.red,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFFB5B5B5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 104),
              child: Center(
                child: Text(
                  'SFA Mobile',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white38,
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

/// Avatar 64px di kartu profil: foto kalau ada, kalau tidak ikon orang.
/// Ada lencana kamera kecil; ketuk untuk ganti / hapus foto.
class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({
    required this.photoUrl,
    required this.busy,
    required this.onTap,
  });

  final String? photoUrl;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB7D6F0), Color(0xFF8FBAE0)],
        ),
      ),
      child: const Icon(Icons.person, size: 32, color: Color(0xFF222222)),
    );
    final url = photoUrl;
    final avatar = url == null
        ? fallback
        : ClipOval(
            child: Image.network(
              url,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
          );

    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 64,
        height: 64,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: avatar),
            if (busy)
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x66000000),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 12,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
