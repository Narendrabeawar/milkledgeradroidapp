import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:milk_ledger/providers.dart';

class MonthlySummaryScreen extends ConsumerStatefulWidget {
  const MonthlySummaryScreen({super.key});
  static const String route = '/summary';

  @override
  ConsumerState<MonthlySummaryScreen> createState() => _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends ConsumerState<MonthlySummaryScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(ledgerRepositoryProvider);
    final currency = ref.watch(settingsProvider).currency;

    final totalLiters = repo.monthlyTotalLiters(_month);
    final totalAmount = repo.monthlyTotalAmount(_month);
    final cashAmount = repo.monthlyCashAmount(_month);
    final creditAmount = repo.monthlyCreditAmount(_month);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Summary'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Month'),
            subtitle: Text(DateFormat('MMMM yyyy').format(_month)),
            trailing: IconButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _month,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  helpText: 'Pick any date in the month',
                );
                if (picked != null) {
                  setState(() => _month = DateTime(picked.year, picked.month));
                }
              },
              icon: const Icon(Icons.calendar_month_outlined),
            ),
          ),
          const SizedBox(height: 16),
          _StatCard(label: 'Total Liters', value: NumberFormat('#,##0.##').format(totalLiters)),
          _StatCard(label: 'Total Amount ($currency)', value: NumberFormat('#,##0.##').format(totalAmount)),
          _StatCard(label: 'Cash Amount ($currency)', value: NumberFormat('#,##0.##').format(cashAmount)),
          _StatCard(label: 'Credit Amount ($currency)', value: NumberFormat('#,##0.##').format(creditAmount)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}


