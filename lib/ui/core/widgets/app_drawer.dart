import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sfa_mobile/data/services/api_client.dart';
import 'package:sfa_mobile/ui/auth/views/login_screen.dart';

import '../theme/app_colors.dart';

/// Membuka sidebar dari kiri.
///
/// Dibuka lewat route sendiri (bukan Scaffold.drawer) supaya menutupi navbar
/// melayang milik TabShell, jadi tombol Logout di bawah tidak tertutup.
Future<void> showAppDrawer(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Tutup menu',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, _, _) => const _DrawerPanel(),
    transitionBuilder: (_, animation, _, child) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

class _DrawerPanel extends StatefulWidget {
  const _DrawerPanel();

  @override
  State<_DrawerPanel> createState() => _DrawerPanelState();
}

class _DrawerPanelState extends State<_DrawerPanel> {
  ({String name, String email, String role})? _profile;

  @override
  void initState() {
    super.initState();
    ApiClient.instance.getProfile().then((p) {
      if (mounted) setState(() => _profile = p);
    });
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Keluar dari akun?',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black),
        ),
        content: const Text(
          'Kamu harus login lagi untuk memakai aplikasi.',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: Colors.black87),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    // logout() selalu menghapus sesi lokal, walau request ke server gagal.
    await ApiClient.instance.logout();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final width = screenWidth * 0.82 > 320 ? 320.0 : screenWidth * 0.82;
    final p = _profile;
    final roleLabel = switch (p?.role) {
      'manager' => 'Manager',
      'sales' => 'Sales',
      _ => '-',
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: AppColors.background,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: width,
          height: double.infinity,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kartu profil
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0x14FFFFFF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFFE9C46A),
                          child: Text(
                            _initials(p?.name ?? ''),
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (p == null || p.name.isEmpty) ? '-' : p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                              Text(
                                (p == null || p.email.isEmpty) ? '-' : p.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  color: Colors.white60,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  roleLabel,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tema: belum aktif di fase ini.
                  Opacity(
                    opacity: 0.55,
                    child: _DrawerTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Tema',
                      subtitle: 'Mode terang segera hadir',
                      trailing: Text(
                        'Gelap',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),
                  const Divider(color: Colors.white12),
                  _DrawerTile(
                    icon: Icons.logout,
                    title: 'Logout',
                    color: const Color(0xFFFF6B6B),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.color = AppColors.white,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
