import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';

/// Hasil memilih foto: [bytes] berisi foto baru, atau [remove] = true kalau
/// foto ingin dihapus.
class PhotoChoice {
  const PhotoChoice.picked(this.bytes) : remove = false;
  const PhotoChoice.removed() : bytes = null, remove = true;

  final Uint8List? bytes;
  final bool remove;
}

enum _PhotoAction { camera, gallery, remove }

/// Menu ganti foto (kamera / galeri / hapus), lalu langsung membuka kamera
/// atau galeri. Mengembalikan null kalau dibatalkan.
Future<PhotoChoice?> choosePhoto(
  BuildContext context, {
  required bool canRemove,
}) async {
  final action = await showModalBottomSheet<_PhotoAction>(
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
          _Item(
            icon: Icons.photo_camera_outlined,
            label: 'Take photo',
            onTap: () => Navigator.pop(ctx, _PhotoAction.camera),
          ),
          _Item(
            icon: Icons.photo_library_outlined,
            label: 'Choose from gallery',
            onTap: () => Navigator.pop(ctx, _PhotoAction.gallery),
          ),
          if (canRemove)
            _Item(
              icon: Icons.delete_outline,
              label: 'Remove photo',
              color: const Color(0xFFFF8A8A),
              onTap: () => Navigator.pop(ctx, _PhotoAction.remove),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  if (action == null) return null;
  if (action == _PhotoAction.remove) return const PhotoChoice.removed();

  try {
    final file = await ImagePicker().pickImage(
      source: action == _PhotoAction.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 800, // dikecilkan supaya ringan dikirim ke server
      maxHeight: 800,
      imageQuality: 85,
    );
    if (file == null) return null;
    return PhotoChoice.picked(await file.readAsBytes());
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open camera/gallery')),
      );
    }
    return null;
  }
}

class _Item extends StatelessWidget {
  const _Item({
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
