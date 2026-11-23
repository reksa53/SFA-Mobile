import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

const kTextMuted = Color(0xFF555555);
const kInputStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.black);
final kDigitsOnly = [FilteringTextInputFormatter.digitsOnly];

IconData categoryIcon(String c) => switch (c) {
      'Mie Instan' => Icons.ramen_dining_outlined,
      'Minuman' => Icons.local_drink_outlined,
      'Sembako' => Icons.shopping_basket_outlined,
      'Susu' => Icons.water_drop_outlined,
      'Bumbu' => Icons.soup_kitchen_outlined,
      'Kopi' => Icons.coffee_outlined,
      _ => Icons.sell_outlined,
    };

class BackBtn extends StatelessWidget {
  const BackBtn({super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => Navigator.maybePop(context),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.chevron_left, color: AppColors.black, size: 28),
        ),
      );
}

/// Chip bulat dengan lingkaran ikon/huruf di kiri. Terpilih = merah penuh.
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    this.letter,
    this.icon,
    this.selected = false,
    this.showClose = false,
    this.outlined = false,
    this.onTap,
  });

  final String label;
  final String? letter;
  final IconData? icon;
  final bool selected;
  final bool showClose;
  final bool outlined; // untuk chip "+ baru"
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.white : AppColors.black;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.red
              : outlined
                  ? Colors.transparent
                  : const Color(0xFFEDEDED),
          // shortcut: border solid, Flutter tidak punya border putus-putus bawaan
          border: outlined ? Border.all(color: const Color(0xFF767676)) : null,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.white.withAlpha(64) : AppColors.white,
            ),
            child: icon != null
                ? Icon(icon, size: 16, color: selected ? AppColors.white : AppColors.red)
                : Text(
                    letter ?? label[0],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: selected ? AppColors.white : AppColors.red,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: fg)),
          if (selected && showClose) ...[
            const SizedBox(width: 8),
            const Icon(Icons.close, size: 16, color: AppColors.white),
          ],
        ]),
      ),
    );
  }
}

Future<T?> showAppSheet<T>(
  BuildContext context,
  WidgetBuilder builder, {
  double? maxHeightFactor, // null = perilaku lama
}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      constraints: maxHeightFactor == null
          ? null
          : BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor),
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: builder,
    );

class SheetFrame extends StatelessWidget {
  const SheetFrame({
    super.key,
    required this.title,
    required this.child,
    this.action,
    this.onAction,
    this.actionColor = AppColors.red,
  });

  final String title;
  final Widget child;
  final String? action;
  final VoidCallback? onAction;
  final Color actionColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.grey,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      if (action != null)
                        GestureDetector(
                          onTap: onAction,
                          child: Text(
                            action!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: actionColor,
                            ),
                          ),
                        ),
                    ]),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      );
}
/// Kotak ber-border dengan judul (Brand, Kategori, Status).
class SheetBox extends StatelessWidget {
  const SheetBox({super.key, required this.title, required this.child, this.caption, this.dim = false});

  final String title;
  final String? caption;
  final Widget child;
  final bool dim;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: dim ? .5 : 1,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.grey),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text.rich(TextSpan(
              text: title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.black),
              children: [
                if (caption != null)
                  TextSpan(
                    text: '  $caption',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: kTextMuted),
                  ),
              ],
            )),
            const SizedBox(height: 10),
            child,
          ]),
        ),
      );
}

class PillButton extends StatelessWidget {
  const PillButton(this.label, {super.key, this.onPressed});

  final String label;
  final VoidCallback? onPressed; // null = pudar

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.red,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.red.withAlpha(100),
            disabledForegroundColor: AppColors.white,
            shape: const StadiumBorder(),
          ),
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );
}

/// Label di atas field.
class Labeled extends StatelessWidget {
  const Labeled(this.label, this.child, {super.key});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.black)),
          const SizedBox(height: 8),
          child,
        ]),
      );
}

OutlineInputBorder _border(Color c, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: w),
    );

InputDecoration boxDecoration({String? hint, String? suffix, String? prefix}) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: kTextMuted),
      suffixText: suffix,
      suffixStyle: const TextStyle(fontSize: 13, color: kTextMuted),
      prefixText: prefix,
      prefixStyle: kInputStyle,
      filled: true,
      fillColor: AppColors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: _border(AppColors.grey, 1),
      enabledBorder: _border(AppColors.grey, 1),
      focusedBorder: _border(AppColors.red, 2),
      errorBorder: _border(AppColors.red, 1),
      focusedErrorBorder: _border(AppColors.red, 2),
    );

/// Field yang bisa di-tap (dropdown / tanggal), bukan ketik.
class TapField extends StatelessWidget {
  const TapField({super.key, required this.value, required this.hint, required this.icon, this.onTap});

  final String? value;
  final String hint;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.grey),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Expanded(
              child: Text(
                value ?? hint,
                overflow: TextOverflow.ellipsis,
                style: kInputStyle.copyWith(color: value == null ? kTextMuted : AppColors.black),
              ),
            ),
            Icon(icon, size: 20, color: kTextMuted),
          ]),
        ),
      );
}

Future<String?> pickFromList(BuildContext context, String title, List<String> options, String? current) =>
    showAppSheet<String>(
      context,
      (ctx) => SheetFrame(
        title: title,
        child: Column(children: [
          for (final o in options)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(o, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.black)),
              trailing: o == current ? const Icon(Icons.check, color: AppColors.red) : null,
              onTap: () => Navigator.pop(ctx, o),
            ),
        ]),
      ),
    );

Future<DateTime?> pickDate(BuildContext context, DateTime? initial) => showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );

class ProductThumb extends StatelessWidget {
  const ProductThumb(this.url, {super.key, this.size = 40});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(Icons.inventory_2_outlined, color: kTextMuted, size: size / 2);
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 4),
      child: Container(
        width: size,
        height: size,
        color: const Color(0xFFF1F4F8),
        child: url == null
            ? icon
            : Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, _, _) => icon),
      ),
    );
  }
}