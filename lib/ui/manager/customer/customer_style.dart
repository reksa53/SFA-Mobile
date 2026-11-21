import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

/// Gaya bersama layar Customer, disamakan dengan modul Sales & Visit
/// (panel gelap, kolom gelap, tombol SAVE merah berbentuk pil).
const kCustPanel = Color(0xFF565656);
const kCustField = Color(0xFF3F3F3F);
const kCustPink = Color(0xFFFF8A8A);

const _dayNames = {
  1: 'Monday',
  2: 'Tuesday',
  3: 'Wednesday',
  4: 'Thursday',
  5: 'Friday',
};

/// Nama hari tetap dalam bahasa Inggris (1 = Monday .. 5 = Friday).
String customerDayName(int? day) => _dayNames[day] ?? 'No fixed schedule';

/// Label kecil di atas kolom isian.
Widget custLabel(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Text(
    text,
    style: GoogleFonts.poppins(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: Colors.white70,
    ),
  ),
);

OutlineInputBorder _border(Color color) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: BorderSide(color: color, width: 1.5),
);

InputDecoration custDecoration({String? hint}) => InputDecoration(
  hintText: hint,
  hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.white38),
  errorStyle: GoogleFonts.poppins(fontSize: 12, color: kCustPink),
  counterText: '',
  filled: true,
  fillColor: kCustField,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  border: _border(Colors.transparent),
  enabledBorder: _border(Colors.transparent),
  disabledBorder: _border(Colors.transparent),
  focusedBorder: _border(AppColors.red),
  errorBorder: _border(kCustPink),
  focusedErrorBorder: _border(AppColors.red),
);

TextStyle custInputStyle() =>
    GoogleFonts.poppins(fontSize: 14.5, color: AppColors.white);

/// Tombol SAVE merah berbentuk pil (sama seperti form Edit Visit).
Widget custSaveButton({
  required VoidCallback? onPressed,
  required bool saving,
  String label = 'SAVE',
}) => SizedBox(
  height: 48,
  child: FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.red,
      foregroundColor: AppColors.white,
      minimumSize: Size.zero,
      shape: const StadiumBorder(),
    ),
    child: saving
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.white,
            ),
          )
        : Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
  ),
);

/// Tombol teks "Cancel" di bawah SAVE.
Widget custCancelButton(VoidCallback? onPressed) => TextButton(
  onPressed: onPressed,
  child: Text(
    'Cancel',
    style: GoogleFonts.poppins(
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      color: Colors.white70,
    ),
  ),
);

/// Dialog gelap (konfirmasi / popup) bergaya Edit Visit.
Future<T?> showCustDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  required List<Widget> actions,
}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: kCustPanel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
      content: content,
      actions: actions,
    ),
  );
}

/// Teks tombol aksi dialog.
Widget custDialogAction(
  String text,
  VoidCallback onPressed, {
  bool danger = false,
}) => TextButton(
  onPressed: onPressed,
  child: Text(
    text,
    style: GoogleFonts.poppins(
      fontWeight: danger ? FontWeight.w700 : FontWeight.w600,
      color: danger ? kCustPink : AppColors.white,
    ),
  ),
);

/// Bottom sheet gelap sederhana (pilihan foto, dsb).
Future<T?> showCustSheet<T>(
  BuildContext context,
  WidgetBuilder builder,
) => showModalBottomSheet<T>(
  context: context,
  backgroundColor: kCustPanel,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
  ),
  builder: builder,
);
