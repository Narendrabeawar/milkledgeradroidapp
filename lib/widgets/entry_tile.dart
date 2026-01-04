import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:milk_ledger/models/milk_entry.dart';

class EntryTile extends StatelessWidget {
  const EntryTile({
    super.key,
    required this.entry,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
  });
  final MilkEntry entry;
  final String currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd MMM, EEE').format(entry.date);
    final amount = NumberFormat('#,##0.##').format(entry.amount);
    final liters = NumberFormat('0.##').format(entry.liters);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onEdit,
        title: Text('$liters L @ ${entry.pricePerLiter.toStringAsFixed(2)} $currency'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$date • ${entry.milkCategory.name} • ${entry.paymentType.name.toUpperCase()}${entry.note == null ? '' : ' • ${entry.note}'}'),
            Text('Total: $amount $currency', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
            PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}


