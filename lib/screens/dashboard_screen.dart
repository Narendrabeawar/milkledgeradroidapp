import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:milk_ledger/models/milk_entry.dart';
import 'package:milk_ledger/providers.dart';
import 'package:milk_ledger/screens/add_entry_screen.dart';
import 'package:milk_ledger/screens/monthly_summary_screen.dart';
import 'package:milk_ledger/screens/settings_screen.dart';
import 'package:milk_ledger/widgets/entry_tile.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final init = ref.watch(initProvider);
    return init.when(
      data: (_) => const _DashboardBody(),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(entriesProvider);
    final currency = ref.watch(settingsProvider).currency;
    final notifier = ref.read(entriesProvider.notifier);

    final today = DateTime.now();
    final monthLabel = DateFormat('MMMM yyyy').format(today);

    Future<bool> confirmDuplicate(BuildContext context) async {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Entry already exists'),
          content: const Text('A milk entry for today already exists. Do you want to add another one?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add anyway')),
          ],
        ),
      );
      return result ?? false;
    }

    Future<void> onDeleteEntry(BuildContext context, MilkEntry entry) async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete entry?'),
          content: const Text('This milk entry will be removed permanently. Continue?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
          ],
        ),
      );
      if (confirm == true) {
        await notifier.remove(entry.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry deleted')));
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Milk Ledger - $monthLabel'),
        actions: [
          IconButton(
            tooltip: 'Summary',
            onPressed: () => Navigator.pushNamed(context, MonthlySummaryScreen.route),
            icon: const Icon(Icons.assessment_outlined),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, SettingsScreen.route),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'add_today',
            onPressed: () async {
              final last = notifier.lastEntry;
              if (last == null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No last entry found. Opening add screen.')),
                  );
                  await Navigator.pushNamed(context, AddEntryScreen.route);
                }
                return;
              }
              if (notifier.hasEntryForDate(DateTime.now())) {
                final proceed = await confirmDuplicate(context);
                if (!proceed) return;
              }
              final newEntry = await notifier.addTodayFromLast(last);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added today: ${DateFormat.Hm().format(newEntry!.date)} • ${newEntry.liters} L')),
                );
              }
            },
            icon: const Icon(Icons.flash_on_outlined),
            label: const Text('Add Today Milk'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add_entry',
            onPressed: () async {
              await Navigator.pushNamed(context, AddEntryScreen.route);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Entry'),
          ),
        ],
      ),
      body: entries.isEmpty
          ? const _EmptyView()
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final MilkEntry entry = entries[index];
                return EntryTile(
                  entry: entry,
                  currency: currency,
                  onEdit: () async {
                    await Navigator.pushNamed(context, AddEntryScreen.route, arguments: entry);
                  },
                  onDelete: () => onDeleteEntry(context, entry),
                );
              },
            ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_grocery_store_outlined, size: 64),
          const SizedBox(height: 12),
          const Text('No entries yet'),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Entry" to record today\'s milk purchase.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}


