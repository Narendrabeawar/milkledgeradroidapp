import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:milk_ledger/models/milk_category.dart';
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
  MilkCategory? _milkCategory;
  MilkEntry? _editingEntry;
  bool _loadedRouteArgs = false;

  @override
  void initState() {
    super.initState();
    final defaultPrice = ref.read(settingsProvider).defaultPricePerLiter;
    _priceCtrl.text = NumberFormat('##0.##').format(defaultPrice);
    // Default liters = 1.0
    _litersCtrl.text = '1.0';
    // Set default category
    final categories = ref.read(categoriesProvider);
    _milkCategory = categories.isNotEmpty ? categories.first : null;

    // Prefill from last entry if available
    final last = ref.read(entriesProvider.notifier).lastEntry;
    if (last != null) {
      _litersCtrl.text = NumberFormat('##0.##').format(last.liters);
      _priceCtrl.text = NumberFormat('##0.##').format(last.pricePerLiter);
      _paymentType = last.paymentType;
      _milkCategory = last.milkCategory;
    } else if (_milkCategory != null) {
      // If no last entry but we have a default category, use its default price
      _priceCtrl.text = NumberFormat('##0.##').format(_milkCategory!.defaultPricePerLiter);
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
      _milkCategory = args.milkCategory;
      if (args.note != null) {
        _noteCtrl.text = args.note!;
      }
    } else if (_milkCategory != null) {
      // For new entries, set default price based on selected category
      _priceCtrl.text = NumberFormat('##0.##').format(_milkCategory!.defaultPricePerLiter);
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
    final categories = ref.watch(categoriesProvider);
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
              initialValue: _paymentType,
              items: const [
                DropdownMenuItem(value: PaymentType.cash, child: Text('Cash')),
                DropdownMenuItem(value: PaymentType.credit, child: Text('Credit')),
              ],
              onChanged: (v) => setState(() => _paymentType = v ?? PaymentType.cash),
              decoration: const InputDecoration(labelText: 'Payment Type'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MilkCategory>(
              initialValue: _milkCategory,
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (v) {
                setState(() {
                  _milkCategory = v;
                  // Auto-populate price when category changes
                  if (v != null) {
                    _priceCtrl.text = NumberFormat('##0.##').format(v.defaultPricePerLiter);
                  }
                });
              },
              decoration: const InputDecoration(labelText: 'Milk Category'),
              validator: (v) => v == null ? 'Please select a category' : null,
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
                final category = _milkCategory!;
                final notifier = ref.read(entriesProvider.notifier);

                if (_isEditing) {
                  final updated = _editingEntry!.copyWith(
                    date: _date,
                    liters: liters,
                    pricePerLiter: price,
                    paymentType: _paymentType,
                    milkCategory: category,
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
                    milkCategory: category,
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


