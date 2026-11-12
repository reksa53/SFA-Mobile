import 'package:flutter/material.dart';
import 'package:sfa_mobile/data/repositories/order_repository.dart';
import 'package:sfa_mobile/ui/core/theme/app_colors.dart';
import 'package:sfa_mobile/ui/core/theme/app_text_styles.dart';

Future<StoreOption?> showStorePicker(
  BuildContext context,
  List<StoreOption> stores,
) {
  return showDialog<StoreOption>(
    context: context,
    builder: (_) => _StorePickerDialog(stores: stores),
  );
}

class _StorePickerDialog extends StatefulWidget {
  const _StorePickerDialog({required this.stores});

  final List<StoreOption> stores;

  @override
  State<_StorePickerDialog> createState() => _StorePickerDialogState();
}

class _StorePickerDialogState extends State<_StorePickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.toLowerCase();
    final results = widget.stores
        .where((s) => s.name.toLowerCase().contains(query))
        .toList();

    return Dialog(
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pilih Toko',
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 18)),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Cari toko',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: results.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Toko tidak ditemukan',
                            style: AppTextStyles.cardBody.copyWith(
                              fontSize: 14,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: results.length,
                        separatorBuilder: (_, _) => const Divider(
                            height: 1, color: Color(0xFFEDEDED)),
                        itemBuilder: (_, i) {
                          final store = results[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              store.name,
                              style: AppTextStyles.cardBody.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              store.address,
                              style: AppTextStyles.cardBody.copyWith(
                                fontSize: 12,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).pop(store),
                          );
                        },
                      ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}