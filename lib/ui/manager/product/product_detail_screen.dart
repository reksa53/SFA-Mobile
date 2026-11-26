import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../data/models/product.dart';
import '../../../data/services/product_service.dart';
import '/utils/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '/ui/core/widgets/common.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    this.canEdit = true,
  });

  final Product product;
  final bool canEdit;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    ProductService.instance.loadDetail(
      widget.product,
    ); // ambil batch dari server
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ProductService.instance,
    builder: (context, _) {
      final pal = context.palette;
      final p = ProductService.instance.current(widget.product);
      final batches = p.fefo;
      final first = batches.indexWhere(
        (b) => !b.expired && b.qty > 0,
      ); // "Keluar dulu"

      return ThemedPage(
        child: Scaffold(
          backgroundColor: pal.bg,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const BackBtn(),
                      const SizedBox(width: 14),
                      Text(
                        'Detail Produk',
                        style: TextStyle(
                          color: pal.text,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: pal.surface,
                      border: pal.surfaceBorder,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F4F8),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: kTextMuted,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  p.sku,
                                  p.brand,
                                  p.category,
                                ].whereType<String>().join(' · '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: kTextMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${fmtRp(p.price)} / ${p.unit}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.grey,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  p.isActive ? 'Aktif' : 'Nonaktif',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${p.stock}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            Text(
                              '${p.unit} · ${p.batches.length} batch',
                              style: const TextStyle(
                                fontSize: 11,
                                color: kTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Batch (urut FEFO)',
                    style: TextStyle(
                      color: pal.text,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: pal.surface,
                        border: pal.surfaceBorder,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: batches.isEmpty
                            ? const Center(
                                child: Text(
                                  'Belum ada batch',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black,
                                  ),
                                ),
                              )
                            : ScrollConfiguration(
                                behavior: ScrollConfiguration.of(context)
                                    .copyWith(overscroll: false),
                                child: ListView.separated(
                                  physics: const ClampingScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  itemCount: batches.length,
                                  separatorBuilder: (_, _) => const Divider(
                                    height: 1,
                                    indent: 14,
                                    endIndent: 14,
                                  ),
                                  itemBuilder: (_, i) => _BatchRow(
                                    batch: batches[i],
                                    unit: p.unit,
                                    first: i == first,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                  if (widget.canEdit) ...[
                    const SizedBox(height: 16),
                    PillButton(
                      'Tambah Batch',
                      onPressed: () => _showAddBatch(context, p),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _BatchRow extends StatelessWidget {
  const _BatchRow({
    required this.batch,
    required this.unit,
    required this.first,
  });

  final ProductBatch batch;
  final String unit;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final b = batch;
    final exp = b.expiry;
    final (text, color) = exp == null
        ? ('Tanpa expired', kTextMuted)
        : b.expired
        ? ('EXP. ${fmtDate(exp)} · expired', kTextMuted)
        : b.nearExpired
        ? ('EXP. ${fmtDate(exp)} · hampir expired', AppColors.red)
        : ('EXP. ${fmtDate(exp)}', kTextMuted);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      b.number,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    if (first) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Keluar dulu',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(text, style: TextStyle(fontSize: 11, color: color)),
                Text(
                  'Diterima ${fmtDate(b.receivedAt)}',
                  style: const TextStyle(fontSize: 11, color: kTextMuted),
                ),
              ],
            ),
          ),
          Text.rich(
            TextSpan(
              text: '${b.qty}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
              children: [
                TextSpan(
                  text: ' / ${b.initialQty} $unit',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: kTextMuted,
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

// layar Tambah Batch belum didesain: ini bentuk minimal (panel bawah)
Future<void> _showAddBatch(BuildContext context, Product p) =>
    showAppSheet<void>(context, (_) => _AddBatch(product: p));

class _AddBatch extends StatefulWidget {
  const _AddBatch({required this.product});

  final Product product;

  @override
  State<_AddBatch> createState() => _AddBatchState();
}

class _AddBatchState extends State<_AddBatch> {
  final _key = GlobalKey<FormState>();
  final _no = TextEditingController();
  final _qty = TextEditingController();
  DateTime? _expiry;
  DateTime _received = today();

  @override
  void dispose() {
    _no.dispose();
    _qty.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    final q = int.parse(_qty.text);
    try {
      await ProductService.instance.addBatch(
        widget.product,
        ProductBatch(
          number: _no.text.trim(),
          expiry: _expiry,
          initialQty: q,
          qty: q,
          receivedAt: _received,
        ),
      );
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.response?.statusCode == 422
                ? 'Nomor batch sudah ada'
                : 'Gagal menyimpan batch',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => SheetFrame(
    title: 'Tambah Batch',
    child: Form(
      key: _key,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Labeled(
                    'Nomor Batch',
                    TextFormField(
                      controller: _no,
                      style: kInputStyle,
                      decoration: boxDecoration(),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return 'Wajib diisi';
                        if (widget.product.batches.any(
                          (b) => b.number.toLowerCase() == t.toLowerCase(),
                        )) {
                          return 'Sudah ada';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Labeled(
                    'Jumlah',
                    TextFormField(
                      controller: _qty,
                      style: kInputStyle,
                      keyboardType: TextInputType.number,
                      inputFormatters: kDigitsOnly,
                      decoration: boxDecoration(suffix: widget.product.unit),
                      validator: (v) =>
                          (int.tryParse(v ?? '') ?? 0) < 1 ? 'Min. 1' : null,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Labeled(
                    'Tanggal Expired',
                    TapField(
                      value: _expiry == null ? null : fmtDate(_expiry!),
                      hint: 'Opsional',
                      icon: Icons.calendar_today_outlined,
                      onTap: () async {
                        final d = await pickDate(context, _expiry);
                        if (d != null) setState(() => _expiry = d);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Labeled(
                    'Diterima',
                    TapField(
                      value: fmtDate(_received),
                      hint: '',
                      icon: Icons.calendar_today_outlined,
                      onTap: () async {
                        final d = await pickDate(context, _received);
                        if (d != null) setState(() => _received = d);
                      },
                    ),
                  ),
                ),
              ],
            ),
            PillButton('Simpan Batch', onPressed: _save),
          ],
        ),
      ),
    ),
  );
}
