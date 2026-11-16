import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/sales.dart';
import '../../../data/models/visit.dart';
import '../../../utils/date_id.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/manager_colors.dart';
import 'sales_avatar.dart';
import 'visit_card.dart';

/// Pilihan toko di form. TODO: ganti dengan daftar dari modul Customer / API.
const _tokoContoh = [
  'TOKO AKBAR AMIRUL',
  'TOKO PURNAMA ABADI SENTOSA',
  'TOKO JAYA AGUNG MANDIRI',
  'TOKO KEMBALI DJAYA',
];

const _panel = Color(0xFF565656);
const _warnaKolom = Color(0xFF3F3F3F);
const _merahMuda = Color(0xFFFF8A8A);

/// Layar "Edit Visit": Manager mengatur jadwal kunjungan satu sales.
/// Dibuka dari tombol EDIT di VisitScreen. Ketuk pensil / "Tambah Kunjungan"
/// untuk membuka form (bottom sheet). Tombol SIMPAN menutup layar dan
/// mengembalikan daftar kunjungan terbaru; "Batal" / back membatalkan semua
/// perubahan.
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
      backgroundColor: _panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
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
    _info(awal == null ? 'Visit added' : 'Visit updated');
  }

  Future<void> _hapus(Visit v) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete visit?',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        content: Text(
          '${v.tokoNama} · ${formatTanggal(v.tanggal)} will be removed from the schedule.',
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
              'Delete',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: _merahMuda,
              ),
            ),
          ),
        ],
      ),
    );
    if (yakin != true || !mounted) return;
    setState(() => _visits.removeWhere((x) => x.id == v.id));
    _info('Visit deleted');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header: tombol back + judul (sama seperti layar Visit).
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),
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
                      'Edit Visit',
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
            Expanded(
              // Kotak daftar: sisi kiri-kanan sejajar dengan kartu, sudut atas
              // dan bawah melengkung, jadi kartu yang terpotong di tepi tidak
              // terlihat dipotong lurus.
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 8),
                    children: [
                      _SalesInfo(sales: widget.sales, jumlah: _visits.length),
                      const SizedBox(height: 12),
                      for (final v in _visits)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 9),
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
                              'No visits yet',
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
              ),
            ),
            _BottomBar(
              onBatal: () => Navigator.of(context).maybePop(),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          SalesAvatar(sales: sales, size: 44),
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
                  '$jumlah visits',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Set store & date\nof visits',
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              height: 1.3,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu kunjungan versi edit: sama dengan VisitCard, plus tombol pensil
/// dan tempat sampah di kanan.
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ManagerColors.listCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0x38000000),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${visit.tanggal.day}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  singkatBulan(visit.tanggal.month),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visit.tokoNama.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  formatTanggal(visit.tanggal),
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 5),
                VisitStatusPill(status: visit.tampilan),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (visit.status == VisitStatus.scheduled)
            Column(
              children: [
                _AksiIcon(
                  tooltip: 'Edit',
                  icon: Icons.edit,
                  background: const Color(0x24FFFFFF),
                  onTap: onEdit,
                ),
                const SizedBox(height: 6),
                _AksiIcon(
                  tooltip: 'Delete',
                  icon: Icons.delete,
                  background: ManagerColors.editButton,
                  onTap: onDelete,
                ),
              ],
            )
          else
            const Tooltip(
              message: 'Already filled by Sales, cannot be changed',
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.lock_outline,
                    size: 20, color: Colors.white38),
              ),
            ),
        ],
      ),
    );
  }
}

class _AksiIcon extends StatelessWidget {
  const _AksiIcon({
    required this.tooltip,
    required this.icon,
    required this.background,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final Color background;
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
            child: Icon(icon, size: 18, color: AppColors.white),
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
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: CustomPaint(
        painter: const _DashedBorderPainter(),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, size: 20, color: AppColors.white),
                const SizedBox(width: 8),
                Text(
                  'Add Visit',
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
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
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

/// Baris bawah: Batal di kiri, SIMPAN (merah) di kanan.
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.onBatal, required this.onSave});

  final VoidCallback onBatal;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
      child: Row(
        children: [
          Expanded(
            flex: 36,
            child: SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: onBatal,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0x24FFFFFF),
                  foregroundColor: AppColors.white,
                  minimumSize: Size.zero,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 64,
            child: SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: onSave,
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        teks,
        style: GoogleFonts.poppins(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
      ),
    );

OutlineInputBorder _garis(Color warna) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: warna, width: 1.5),
    );

InputDecoration _dekor({String? hint, Widget? suffix}) => InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.white38),
      errorStyle: GoogleFonts.poppins(fontSize: 12, color: _merahMuda),
      suffixIcon: suffix,
      filled: true,
      fillColor: _warnaKolom,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: _garis(Colors.transparent),
      enabledBorder: _garis(Colors.transparent),
      focusedBorder: _garis(AppColors.red),
      errorBorder: _garis(_merahMuda),
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
  String? _toko;
  DateTime? _tanggal;

  @override
  void initState() {
    super.initState();
    final v = widget.awal;
    _toko = v?.tokoNama;
    _tanggal = v?.tanggal;
    _isiTanggal();
  }

  @override
  void dispose() {
    _tglText.dispose();
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
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.red,
            onPrimary: AppColors.white,
            surface: _panel,
            onSurface: AppColors.white,
          ),
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
    // Manager hanya mengatur toko dan tanggal. Jadwal baru berstatus
    // scheduled; status & catatan hasil kunjungan diisi oleh Sales.
    final awal = widget.awal;
    final visit = awal != null
        ? awal.copyWith(tokoNama: _toko!, tanggal: _tanggal!)
        : Visit(
            id: DateTime.now().millisecondsSinceEpoch,
            tokoNama: _toko!,
            tanggal: _tanggal!,
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
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
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
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  edit ? 'Edit Visit' : 'Add Visit',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 14),
                _label('Store'),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _toko,
                  isExpanded: true,
                  dropdownColor: _panel,
                  iconEnabledColor: Colors.white70,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    color: AppColors.white,
                  ),
                  decoration: _dekor(hint: 'Select store...'),
                  items: [
                    for (final t in widget.daftarToko)
                      DropdownMenuItem(
                        value: t,
                        child: Text(t, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => _toko = v),
                  validator: (v) => v == null ? 'Store is required' : null,
                ),
                const SizedBox(height: 12),
                _label('Date'),
                TextFormField(
                  controller: _tglText,
                  readOnly: true,
                  onTap: _pilihTanggal,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    color: AppColors.white,
                  ),
                  decoration: _dekor(
                    hint: 'Select date',
                    suffix: const Icon(Icons.calendar_today_outlined,
                        size: 20, color: Colors.white70),
                  ),
                  validator: (_) =>
                      _tanggal == null ? 'Date is required' : null,
                ),
                const SizedBox(height: 18),
                SizedBox(
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
                if (edit)
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(const _HasilForm.hapus()),
                    child: Text(
                      'Delete visit',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _merahMuda,
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