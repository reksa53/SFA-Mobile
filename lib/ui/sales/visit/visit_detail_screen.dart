import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/visit.dart';
import '../../../data/repositories/sales_visit_repository.dart';
import '../../../utils/date_id.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/manager_colors.dart';
import 'visit_status_chip.dart';

/// Detail satu kunjungan. Sales mengisi catatan lalu memilih
/// "Not Visited" atau "Mark as Visited".
///
/// Aturan:
/// - hanya kunjungan berstatus scheduled yang tanggalnya hari ini / sudah
///   lewat (Overdue) yang bisa dilaporkan;
/// - kunjungan di masa depan terkunci;
/// - kunjungan yang sudah dilaporkan hanya bisa dibaca;
/// - Not Visited wajib diberi catatan.
class VisitDetailScreen extends StatefulWidget {
  const VisitDetailScreen({
    super.key,
    required this.visit,
    required this.repository,
  });

  final Visit visit;
  final SalesVisitRepository repository;

  @override
  State<VisitDetailScreen> createState() => _VisitDetailScreenState();
}

class _VisitDetailScreenState extends State<VisitDetailScreen> {
  late final TextEditingController _catatan;
  bool _error = false;
  bool _saving = false;

  Visit get _v => widget.visit;
  bool get _future => _v.tanggal.isAfter(dateOnly(DateTime.now()));
  bool get _editable => _v.status == VisitStatus.scheduled && !_future;

  @override
  void initState() {
    super.initState();
    _catatan = TextEditingController(text: _v.catatan);
  }

  @override
  void dispose() {
    _catatan.dispose();
    super.dispose();
  }

  Future<void> _simpan(VisitStatus status) async {
    final teks = _catatan.text.trim();
    if (status == VisitStatus.notVisited && teks.isEmpty) {
      setState(() => _error = true);
      return;
    }
    setState(() => _saving = true);
    try {
      final hasil = await widget.repository.reportVisit(_v, status, teks);
      if (!mounted) return;
      Navigator.of(context).pop(hasil);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                child: _panel(),
              ),
            ),
            _bottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Material(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(context).pop(),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.chevron_left,
                      size: 28, color: AppColors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Visit Detail',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panel() {
    final label = GoogleFonts.poppins(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: Colors.white70,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ManagerColors.listCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _v.tokoNama.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 17, color: Colors.white60),
              const SizedBox(width: 8),
              Text(
                formatTanggal(_v.tanggal),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          
                    if (_v.alamat.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(Icons.location_on_outlined,
                      size: 17, color: Colors.white60),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _v.alamat,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 10),
          VisitStatusChipDark(status: _v.tampilan),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Colors.white12),
          ),
          Text('Notes', style: label),
          const SizedBox(height: 6),
          if (_editable) ...[
            TextField(
              controller: _catatan,
              maxLines: 4,
              minLines: 4,
              enabled: !_saving,
              onChanged: (_) {
                if (_error) setState(() => _error = false);
              },
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                color: AppColors.white,
              ),
              cursorColor: AppColors.red,
              decoration: InputDecoration(
                hintText: 'Visit result (required if not visited)',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14.5,
                  color: Colors.white38,
                ),
                filled: true,
                fillColor: const Color(0xFF3F3F3F),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _error
                        ? const Color(0xFFFF8A8A)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color:
                        _error ? const Color(0xFFFF8A8A) : AppColors.red,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            if (_error)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Please write why the visit did not happen.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFFFF8A8A),
                  ),
                ),
              ),
          ] else
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF3F3F3F),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _v.catatan.isEmpty ? '—' : _v.catatan,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          if (_future)
            _kunci('You can fill in this visit on its scheduled date.')
          else if (!_editable)
            _kunci('This visit is already reported and can no longer be changed.'),
        ],
      ),
    );
  }

  Widget _kunci(String teks) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, size: 17, color: Colors.white60),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              teks,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    final glass = FilledButton.styleFrom(
      backgroundColor: const Color(0x24FFFFFF),
      foregroundColor: AppColors.white,
      minimumSize: const Size.fromHeight(48),
      shape: const StadiumBorder(),
    );
    final teksStyle =
        GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w700);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: _editable
          ? Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed:
                        _saving ? null : () => _simpan(VisitStatus.notVisited),
                    style: glass,
                    child: Text('Not Visited', style: teksStyle),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed:
                        _saving ? null : () => _simpan(VisitStatus.visited),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: const StadiumBorder(),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : Text('Mark as Visited', style: teksStyle),
                  ),
                ),
              ],
            )
          : FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: glass,
              child: Text('Back', style: teksStyle),
            ),
    );
  }
}
