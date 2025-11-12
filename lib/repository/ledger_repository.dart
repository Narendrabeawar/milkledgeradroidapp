import 'package:hive/hive.dart';
import 'package:milk_ledger/models/milk_entry.dart';
import 'package:milk_ledger/models/settings.dart';
import 'package:milk_ledger/storage/hive_boxes.dart';

class LedgerRepository {
  Future<void> init() async {
    await HiveBoxes.ensureOpened();
  }

  Box<MilkEntry> get _entriesBox => Hive.box<MilkEntry>(HiveBoxes.entries);
  Box<Settings> get _settingsBox => Hive.box<Settings>(HiveBoxes.settings);

  List<MilkEntry> getAllEntries() {
    return _entriesBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> addEntry(MilkEntry entry) async {
    await _entriesBox.put(entry.id, entry);
  }

  Future<void> updateEntry(MilkEntry entry) async {
    await _entriesBox.put(entry.id, entry);
  }

  Future<void> deleteEntry(String id) async {
    await _entriesBox.delete(id);
  }

  MilkEntry? getLastEntry() {
    if (_entriesBox.isEmpty) return null;
    final entries = getAllEntries();
    return entries.isEmpty ? null : entries.first;
  }

  bool hasEntryForDate(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    return _entriesBox.values.any((e) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      return d == target;
    });
  }

  List<MilkEntry> getEntriesForDate(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    final list = _entriesBox.values.where((e) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      return d == target;
    }).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Settings getSettings() {
    return _settingsBox.get('app_settings') ?? const Settings(defaultPricePerLiter: 60.0, currency: 'INR');
  }

  Future<void> updateSettings(Settings settings) async {
    await _settingsBox.put('app_settings', settings);
  }

  // Aggregations
  double monthlyTotalAmount(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    return _entriesBox.values
        .where((e) => !e.date.isBefore(start) && e.date.isBefore(end))
        .fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  double monthlyTotalLiters(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    return _entriesBox.values
        .where((e) => !e.date.isBefore(start) && e.date.isBefore(end))
        .fold<double>(0.0, (sum, e) => sum + e.liters);
  }

  double monthlyCashAmount(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    return _entriesBox.values
        .where((e) => !e.date.isBefore(start) && e.date.isBefore(end) && e.paymentType.name == 'cash')
        .fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  double monthlyCreditAmount(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    return _entriesBox.values
        .where((e) => !e.date.isBefore(start) && e.date.isBefore(end) && e.paymentType.name == 'credit')
        .fold<double>(0.0, (sum, e) => sum + e.amount);
  }
}


