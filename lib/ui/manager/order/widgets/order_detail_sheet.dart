import 'package:flutter/material.dart';
import 'package:sfa_mobile/data/models/order.dart';

String _rp(int n) => 'Rp ${n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';

/// [onAccept] dan [onReject] mengembalikan pesan error, atau null kalau berhasil.
Future<void> showOrderDetail(
  BuildContext context,
  Order order, {
  required Future<String?> Function() onAccept,
  required Future<String?> Function(String reason) onReject,
}) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OrderDetail(order, onAccept, onReject),
    );

class _OrderDetail extends StatelessWidget {
  const _OrderDetail(this.order, this.onAccept, this.onReject);
  final Order order;
  final Future<String?> Function() onAccept;
  final Future<String?> Function(String reason) onReject;

  Future<void> _run(BuildContext context, Future<String?> Function() action) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final error = await action();
    nav.pop();
    messenger.showSnackBar(SnackBar(content: Text(error ?? 'Order diperbarui')));
  }

  Future<void> _reject(BuildContext context) async {
    var reason = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alasan penolakan'),
        content: TextField(autofocus: true, maxLines: 2, onChanged: (v) => reason = v),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tolak')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) _run(context, () => onReject(reason.trim()));
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.storeName, style: Theme.of(context).textTheme.titleLarge),
              if (order.salesName != null) Text('Sales: ${order.salesName}'),
              const Divider(),
              Flexible(
                child: ListView(shrinkWrap: true, children: [
                  for (final i in order.items)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(i.productName),
                      subtitle: Text('${i.quantity} × ${_rp(i.unitPrice)}'),
                      trailing: Text(_rp(i.subtotal)),
                    ),
                ]),
              ),
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total'),
                Text(_rp(order.total), style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
              if (order.status == OrderStatus.pending) ...[
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => _reject(context), child: const Text('Tolak'))),
                  const SizedBox(width: 12),
                  Expanded(child: FilledButton(onPressed: () => _run(context, onAccept), child: const Text('Terima'))),
                ]),
              ],
            ],
          ),
        ),
      );
}