import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:milk_ledger/models/milk_entry.dart';
import 'package:milk_ledger/models/payment_type.dart';
import 'package:milk_ledger/providers.dart';
import 'package:uuid/uuid.dart';

class AddEntryScreen extends ConsumerStatefulWidget {
  const AddEntryScreen({super.key});
  static const String route = '/add';

  @override
  ConsumerState<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends ConsumerState<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _date = DateTime.now();
  final _litersCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  PaymentType _paymentType = PaymentType.cash;
  MilkEntry? _editingEntry;
  bool _loadedRouteArgs = false;

  @override
  void initState() {
    super.initState();
    final defaultPrice = ref.read(settingsProvider).defaultPricePerLiter;
    _priceCtrl.text = NumberFormat('##0.##').format(defaultPrice);
    // Default liters = 1.0
    _litersCtrl.text = '1.0';
    // Prefill from last entry if available
    final last = ref.read(entriesProvider.notifier).lastEntry;
    if (last != null) {
      _litersCtrl.text = NumberFormat('##0.##').format(last.liters);
      _priceCtrl.text = NumberFormat('##0.##').format(last.pricePerLiter);
      _paymentType = last.paymentType;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedRouteArgs) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is MilkEntry) {
      _editingEntry = args;
      _date = args.date;
      _litersCtrl.text = NumberFormat('##0.##').format(args.liters);
      _priceCtrl.text = NumberFormat('##0.##').format(args.pricePerLiter);
      _paymentType = args.paymentType;
      if (args.note != null) {
        _noteCtrl.text = args.note!;
      }
    }
    _loadedRouteArgs = true;
  }

  @override
  void dispose() {
    _litersCtrl.dispose();
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _isEditing => _editingEntry != null;

  Future<bool> _confirmDuplicate(BuildContext context) async {
    final notifier = ref.read(entriesProvider.notifier);
    final hasDuplicate = notifier.hasEntryForDate(_date, exceptId: _editingEntry?.id);
    if (!hasDuplicate) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate entry'),
        content: const Text('A milk entry for this date already exists. Do you want to add another entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add anyway')),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(settingsProvider).currency;
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Entry' : 'Add Entry')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(DateFormat('EEE, dd MMM yyyy').format(_date)),
              trailing: IconButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _date = DateTime(picked.year, picked.month, picked.day));
                  }
                },
                icon: const Icon(Icons.calendar_today_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _litersCtrl,
              decoration: const InputDecoration(labelText: 'Liters'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final d = double.tryParse(v ?? '');
                if (d == null || d <= 0) return 'Enter liters';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceCtrl,
              decoration: InputDecoration(labelText: 'Price per Liter ($currency)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final d = double.tryParse(v ?? '');
                if (d == null || d <= 0) return 'Enter price';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PaymentType>(
              value: _paymentType,
              items: const [
                DropdownMenuItem(value: PaymentType.cash, child: Text('Cash')),
                DropdownMenuItem(value: PaymentType.credit, child: Text('Credit')),
              ],
              onChanged: (v) => setState(() => _paymentType = v ?? PaymentType.cash),
              decoration: const InputDecoration(labelText: 'Payment Type'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                if (!await _confirmDuplicate(context)) return;
                final liters = double.parse(_litersCtrl.text);
                final price = double.parse(_priceCtrl.text);
                final note = _noteCtrl.text.isEmpty ? null : _noteCtrl.text;
                final notifier = ref.read(entriesProvider.notifier);

                if (_isEditing) {
                  final updated = _editingEntry!.copyWith(
                    date: _date,
                    liters: liters,
                    pricePerLiter: price,
                    paymentType: _paymentType,
                    note: note,
                  );
                  await notifier.update(updated);
                } else {
                  final entry = MilkEntry(
                    id: const Uuid().v4(),
                    date: _date,
                    liters: liters,
                    pricePerLiter: price,
                    paymentType: _paymentType,
                    note: note,
                  );
                  await notifier.add(entry);
                }

                if (!mounted) return;
                Navigator.pop(context);
              },
              icon: const Icon(Icons.save_outlined),
              label: Text(_isEditing ? 'Update' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}


