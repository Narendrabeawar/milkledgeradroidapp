import 'package:hive/hive.dart';
import 'package:milk_ledger/models/milk_category.dart';
import 'package:milk_ledger/models/milk_entry.dart';
import 'package:milk_ledger/models/settings.dart';
import 'package:milk_ledger/storage/hive_boxes.dart';

class LedgerRepository {
  Future<void> init() async {
    await HiveBoxes.ensureOpened();
  }

  Box<MilkEntry> get _entriesBox => Hive.box<MilkEntry>(HiveBoxes.entries);
  Box<Settings> get _settingsBox => Hive.box<Settings>(HiveBoxes.settings);
  Box<MilkCategory> get _categoriesBox => Hive.box<MilkCategory>(HiveBoxes.categories);

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

  List<MilkEntry> getEntriesForMonth(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final list = _entriesBox.values.where((e) {
      return !e.date.isBefore(start) && e.date.isBefore(end);
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

  // Category-wise aggregations
  Map<String, double> monthlyTotalLitersByCategory(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final categoryTotals = <String, double>{};

    for (final entry in _entriesBox.values) {
      if (!entry.date.isBefore(start) && entry.date.isBefore(end)) {
        final categoryName = entry.milkCategory.name;
        categoryTotals[categoryName] = (categoryTotals[categoryName] ?? 0) + entry.liters;
      }
    }

    return categoryTotals;
  }

  Map<String, double> monthlyTotalAmountByCategory(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final categoryTotals = <String, double>{};

    for (final entry in _entriesBox.values) {
      if (!entry.date.isBefore(start) && entry.date.isBefore(end)) {
        final categoryName = entry.milkCategory.name;
        categoryTotals[categoryName] = (categoryTotals[categoryName] ?? 0) + entry.amount;
      }
    }

    return categoryTotals;
  }

  // Category management
  List<MilkCategory> getAllCategories() {
    return _categoriesBox.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> addCategory(MilkCategory category) async {
    await _categoriesBox.put(category.id, category);
  }

  Future<void> updateCategory(MilkCategory category) async {
    await _categoriesBox.put(category.id, category);
  }

  Future<void> deleteCategory(String id) async {
    // Don't allow deletion of default categories
    if (id == MilkCategory.cowMilkId || id == MilkCategory.buffaloMilkId) {
      throw Exception('Cannot delete default categories');
    }

    // Check if category is being used by any entries
    final isUsed = _entriesBox.values.any((entry) => entry.milkCategory.id == id);
    if (isUsed) {
      throw Exception('Cannot delete category that is being used by entries');
    }

    await _categoriesBox.delete(id);
  }

  MilkCategory? getCategoryById(String id) {
    return _categoriesBox.get(id);
  }

  // Migration helper for existing entries (they won't have categories)
  Future<void> migrateEntriesToDefaultCategory() async {
    final defaultCategory = _categoriesBox.get(MilkCategory.cowMilkId);
    if (defaultCategory == null) return;

    final entriesToMigrate = _entriesBox.values.where((entry) {
      // This is a simple check - if the entry doesn't have a proper category, migrate it
      return entry.milkCategory.id.isEmpty;
    }).toList();

    for (final entry in entriesToMigrate) {
      final migratedEntry = entry.copyWith(milkCategory: defaultCategory);
      await _entriesBox.put(entry.id, migratedEntry);
    }
  }
}


