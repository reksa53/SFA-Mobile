import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/sales.dart';
import '../../../data/models/visit.dart';
import '../../../utils/date_id.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/manager_colors.dart';

/// Pilihan toko di form. TODO: ganti dengan daftar dari modul Customer / API.
const _tokoContoh = [
  'TOKO AKBAR AMIRUL',
  'TOKO PURNAMA ABADI SENTOSA',
  'TOKO JAYA AGUNG MANDIRI',
  'TOKO KEMBALI DJAYA',
];

/// Layar "Edit Visit": Manager mengatur jadwal kunjungan satu sales.
/// Dibuka dari tombol EDIT di VisitScreen. Ketuk pensil / "Tambah Kunjungan"
/// untuk membuka form (bottom sheet). Tombol SIMPAN menutup layar dan
/// mengembalikan daftar kunjungan terbaru; "back" membatalkan semua perubahan.
class EditVisitScreen extends StatefulWidget {
  const EditVisitScreen({
    super.key,
    required this.sales,
    required this.visits,
  });

  final Sales sales;
  final List<Visit> visits;

  @override
  State<EditVisitScreen> createState() => _EditVisitScreenState();
}

class _EditVisitScreenState extends State<EditVisitScreen> {
  late List<Visit> _visits;

  @override
  void initState() {
    super.initState();
    _visits = [...widget.visits]; // salinan: perubahan baru berlaku saat SIMPAN
    _urutkan();
  }

  void _urutkan() => _visits.sort((a, b) => a.tanggal.compareTo(b.tanggal));

  List<String> get _daftarToko =>
      {..._tokoContoh, ..._visits.map((v) => v.tokoNama)}.toList();

  void _info(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(teks)),
    );
  }

  Future<void> _bukaForm([Visit? awal]) async {
    final hasil = await showModalBottomSheet<_HasilForm>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _VisitForm(awal: awal, daftarToko: _daftarToko),
    );
    if (hasil == null || !mounted) return;

    if (hasil.hapus) {
      if (awal != null) await _hapus(awal);
      return;
    }
    final baru = hasil.visit;
    if (baru == null) return;

    setState(() {
      if (awal == null) {
        _visits.add(baru);
      } else {
        final i = _visits.indexWhere((v) => v.id == awal.id);
        if (i >= 0) _visits[i] = baru;
      }
      _urutkan();
    });
    _info(awal == null ? 'Kunjungan ditambahkan' : 'Kunjungan diperbarui');
  }

  Future<void> _hapus(Visit v) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus kunjungan?',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        content: Text(
          '${v.tokoNama} · ${formatTanggal(v.tanggal)} akan dihapus dari jadwal.',
          style: GoogleFonts.poppins(fontSize: 13.5, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Hapus',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: AppColors.red,
              ),
            ),
          ),
        ],
      ),
    );
    if (yakin != true || !mounted) return;
    setState(() => _visits.removeWhere((x) => x.id == v.id));
    _info('Kunjungan dihapus');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: SizedBox(
                height: 44,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Edit Visit',
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _SalesInfo(sales: widget.sales, jumlah: _visits.length),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
                children: [
                  for (final v in _visits)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _EditVisitCard(
                        visit: v,
                        onEdit: () => _bukaForm(v),
                        onDelete: () => _hapus(v),
                      ),
                    ),
                  if (_visits.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Belum ada kunjungan',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  _TambahButton(onTap: () => _bukaForm()),
                ],
              ),
            ),
            _BottomBar(
              onBack: () => Navigator.of(context).maybePop(),
              onSave: () => Navigator.of(context).pop(_visits),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu kecil: siapa sales yang sedang diedit.
class _SalesInfo extends StatelessWidget {
  const _SalesInfo({required this.sales, required this.jumlah});

  final Sales sales;
  final int jumlah;

  @override
  Widget build(BuildContext context) {
    final bytes = sales.fotoBytes;
    final url = sales.fotoUrl;
    final ImageProvider? gambar = bytes != null
        ? MemoryImage(bytes)
        : (url != null && url.isNotEmpty ? NetworkImage(url) : null);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ManagerColors.calendar,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.grey,
            backgroundImage: gambar,
            child: gambar != null
                ? null
                : Text(
                    sales.inisial,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sales.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  '$jumlah kunjungan',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Ketuk pensil\nuntuk mengubah',
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 11,
              height: 1.3,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu kunjungan versi edit: ada tombol pensil dan tempat sampah.
class _EditVisitCard extends StatelessWidget {
  const _EditVisitCard({
    required this.visit,
    required this.onEdit,
    required this.onDelete,
  });

  final Visit visit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ManagerColors.listCard,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    visit.tokoNama,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    formatTanggal(visit.tanggal),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  if (visit.catatan.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        visit.catatan,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: Colors.white60,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusChip(status: visit.status),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AksiIcon(
                      tooltip: 'Ubah',
                      icon: Icons.edit,
                      background: AppColors.white,
                      foreground: AppColors.black,
                      onTap: onEdit,
                    ),
                    const SizedBox(width: 8),
                    _AksiIcon(
                      tooltip: 'Hapus',
                      icon: Icons.delete,
                      background: ManagerColors.editButton,
                      foreground: AppColors.white,
                      onTap: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final VisitStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
      ),
    );
  }
}

class _AksiIcon extends StatelessWidget {
  const _AksiIcon({
    required this.tooltip,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: 18, color: foreground),
          ),
        ),
      ),
    );
  }
}

/// Kotak garis putus-putus "Tambah Kunjungan".
class _TambahButton extends StatelessWidget {
  const _TambahButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _DashedBorderPainter(),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, color: AppColors.white),
              const SizedBox(width: 8),
              Text(
                'Tambah Kunjungan',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      );
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + 8, metric.length)),
          paint,
        );
        d += 14;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Baris bawah: "back" (batal) di kiri, SIMPAN di kanan.
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

// ───────────────────────── Form (bottom sheet) ─────────────────────────

/// Hasil dari form: simpan (ada [visit]) atau hapus.
class _HasilForm {
  const _HasilForm.simpan(Visit v)
      : visit = v,
        hapus = false;
  const _HasilForm.hapus()
      : visit = null,
        hapus = true;

  final Visit? visit;
  final bool hapus;
}

Widget _label(String teks) => Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        teks,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
      ),
    );

OutlineInputBorder _garis(Color warna) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: warna, width: 1.5),
    );

InputDecoration _dekor({String? hint, Widget? suffix}) => InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.black38),
      errorStyle: GoogleFonts.poppins(fontSize: 12),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF1F1F1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: _garis(Colors.transparent),
      enabledBorder: _garis(Colors.transparent),
      focusedBorder: _garis(AppColors.red),
      errorBorder: _garis(AppColors.red),
      focusedErrorBorder: _garis(AppColors.red),
    );

class _VisitForm extends StatefulWidget {
  const _VisitForm({required this.awal, required this.daftarToko});

  /// null = tambah kunjungan baru, ada isi = ubah kunjungan itu.
  final Visit? awal;
  final List<String> daftarToko;

  @override
  State<_VisitForm> createState() => _VisitFormState();
}

class _VisitFormState extends State<_VisitForm> {
  final _formKey = GlobalKey<FormState>();
  final _tglText = TextEditingController();
  late final TextEditingController _catatan;
  String? _toko;
  DateTime? _tanggal;
  late VisitStatus _status;

  @override
  void initState() {
    super.initState();
    final v = widget.awal;
    _toko = v?.tokoNama;
    _tanggal = v?.tanggal;
    _status = v?.status ?? VisitStatus.pending;
    _catatan = TextEditingController(text: v?.catatan ?? '');
    _isiTanggal();
  }

  @override
  void dispose() {
    _tglText.dispose();
    _catatan.dispose();
    super.dispose();
  }

  void _isiTanggal() {
    final t = _tanggal;
    _tglText.text = t == null ? '' : formatTanggal(t);
  }

  Future<void> _pilihTanggal() async {
    final t = await showDatePicker(
      context: context,
      initialDate: _tanggal ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.red),
        ),
        child: child!,
      ),
    );
    if (t == null || !mounted) return;
    setState(() {
      _tanggal = dateOnly(t);
      _isiTanggal();
    });
  }

  void _simpan() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final visit = Visit(
      id: widget.awal?.id ?? DateTime.now().millisecondsSinceEpoch,
      tokoNama: _toko!,
      tanggal: _tanggal!,
      status: _status,
      catatan: _catatan.text.trim(),
    );
    Navigator.of(context).pop(_HasilForm.simpan(visit));
  }

  @override
  Widget build(BuildContext context) {
    final edit = widget.awal != null;

    return Padding(
      // Naik mengikuti keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  edit ? 'Edit Kunjungan' : 'Tambah Kunjungan',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 14),
                _label('Nama Toko'),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _toko,
                  isExpanded: true,
                  dropdownColor: AppColors.white,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    color: AppColors.black,
                  ),
                  decoration: _dekor(hint: 'Pilih toko...'),
                  items: [
                    for (final t in widget.daftarToko)
                      DropdownMenuItem(
                        value: t,
                        child: Text(t, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => _toko = v),
                  validator: (v) => v == null ? 'Toko wajib dipilih' : null,
                ),
                const SizedBox(height: 12),
                _label('Tanggal Kunjungan'),
                TextFormField(
                  controller: _tglText,
                  readOnly: true,
                  onTap: _pilihTanggal,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    color: AppColors.black,
                  ),
                  decoration: _dekor(
                    hint: 'Pilih tanggal',
                    suffix: const Icon(Icons.calendar_today_outlined,
                        size: 20, color: Colors.black54),
                  ),
                  validator: (_) =>
                      _tanggal == null ? 'Tanggal wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                _label('Status'),
                Row(
                  children: [
                    for (final s in VisitStatus.values) ...[
                      if (s != VisitStatus.values.first)
                        const SizedBox(width: 8),
                      Expanded(
                        child: _StatusPilihan(
                          status: s,
                          dipilih: s == _status,
                          onTap: () => setState(() => _status = s),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _label('Catatan (opsional)'),
                TextFormField(
                  controller: _catatan,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  cursorColor: AppColors.red,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    color: AppColors.black,
                  ),
                  decoration:
                      _dekor(hint: 'Contoh: bawa katalog produk baru'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 10,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          foregroundColor: AppColors.black,
                          side: const BorderSide(color: Colors.black26),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 14,
                      child: FilledButton(
                        onPressed: _simpan,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          backgroundColor: AppColors.red,
                          foregroundColor: AppColors.white,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          'Simpan',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (edit)
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(const _HasilForm.hapus()),
                    child: Text(
                      'Hapus kunjungan ini',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPilihan extends StatelessWidget {
  const _StatusPilihan({
    required this.status,
    required this.dipilih,
    required this.onTap,
  });

  final VisitStatus status;
  final bool dipilih;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: dipilih ? AppColors.red : const Color(0xFFF1F1F1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Center(
            child: Text(
              status.label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: dipilih ? AppColors.white : AppColors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
