import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

// Warna status, sama dengan layar Visit dan detail customer.
const kDone = Color(0xFF2ECC40);
const kOverdue = Color(0xFFE53935);
const kMissed = Color(0xFF9E9E9E);
const kWarn = Color(0xFFF59E0B);

const _monthsId = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];
const _daysId = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

String monthLabelId(DateTime d) => '${_monthsId[d.month - 1]} ${d.year}';

String dateLabelId(DateTime d) =>
    '${_daysId[d.weekday - 1]}, ${d.day} ${_monthsId[d.month - 1]} ${d.year}';

String timeAgoId(DateTime? t) {
  if (t == null) return '-';
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 1) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  return '${diff.inDays} hari lalu';
}

String rupiah(num v) {
  final s = v.round().abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return 'Rp $b';
}

/// Panel tembus pandang di atas latar layar.
BoxDecoration dashGlass(BuildContext context, {double radius = 20}) {
  final p = context.palette;
  return BoxDecoration(
    color: p.glass,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: p.glassBorder),
  );
}

/// Header Home: tombol hamburger + judul + sapaan.
class DashHeader extends StatelessWidget {
  const DashHeader({
    super.key,
    required this.title,
    required this.onMenu,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),
      child: Row(
        children: [
          Material(
            color: p.glassStrong,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onMenu,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.menu, color: p.text),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                    height: 1.15,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: p.textFaint,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashSection extends StatelessWidget {
  const DashSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.palette.text,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

/// Label kecil di dalam section (mis. "Hari ini", "Bulan ini").
class DashLabel extends StatelessWidget {
  const DashLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: context.palette.textFaint,
        ),
      ),
    );
  }
}

class DashCard extends StatelessWidget {
  const DashCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: dashGlass(context),
      child: child,
    );
  }
}

/// Titik status kecil. [hollow] = lingkaran kosong (status "pending"), warnanya
/// mengikuti tema sehingga tetap terlihat di mode terang.
class DashDot extends StatelessWidget {
  const DashDot({super.key, this.color = Colors.white, this.hollow = false});

  final Color color;
  final bool hollow;

  @override
  Widget build(BuildContext context) {
    final c = hollow ? context.palette.textMuted : color;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: hollow ? null : c,
        shape: BoxShape.circle,
        border: hollow ? Border.all(color: c, width: 1.4) : null,
      ),
    );
  }
}

/// Kartu angka: nilai besar + label (dengan titik warna opsional).
class DashStat extends StatelessWidget {
  const DashStat({
    super.key,
    required this.value,
    required this.label,
    this.dot,
    this.hollow = false,
  });

  final String value;
  final String label;
  final Color? dot;
  final bool hollow;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: dashGlass(context, radius: 16),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: p.text,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (dot != null || hollow) ...[
                DashDot(color: dot ?? Colors.white, hollow: hollow),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 11, color: p.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Deretan kartu dengan lebar sama rata.
class DashTiles extends StatelessWidget {
  const DashTiles({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

/// Pesan di tengah layar (gagal memuat, dll) dengan tombol coba lagi opsional.
class DashMessage extends StatelessWidget {
  const DashMessage({super.key, required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: GoogleFonts.poppins(color: p.textMuted)),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: p.text),
              child: const Text('Coba lagi'),
            ),
        ],
      ),
    );
  }
}
