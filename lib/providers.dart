import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milk_ledger/models/milk_category.dart';
import 'package:milk_ledger/models/milk_entry.dart';
import 'package:milk_ledger/models/settings.dart';
import 'package:milk_ledger/repository/ledger_repository.dart';
import 'package:uuid/uuid.dart';

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  return LedgerRepository();
});

final initProvider = FutureProvider<void>((ref) async {
  await ref.read(ledgerRepositoryProvider).init();
  // Migrate existing entries to have default category
  await ref.read(ledgerRepositoryProvider).migrateEntriesToDefaultCategory();
});

// Current selected month for filtering
final currentMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final entriesProvider = StateNotifierProvider<EntriesNotifier, List<MilkEntry>>((ref) {
  final repo = ref.read(ledgerRepositoryProvider);
  final currentMonth = ref.watch(currentMonthProvider);
  final notifier = EntriesNotifier(repo);
  notifier.refreshForMonth(currentMonth);
  return notifier;
});

class EntriesNotifier extends StateNotifier<List<MilkEntry>> {
  EntriesNotifier(this._repo) : super(const []);
  final LedgerRepository _repo;

  void refresh() {
    state = _repo.getAllEntries();
  }

  void refreshForMonth(DateTime month) {
    state = _repo.getEntriesForMonth(month);
  }

  MilkEntry? get lastEntry => _repo.getLastEntry();

  bool hasEntryForDate(DateTime date, {String? exceptId}) {
    final target = DateTime(date.year, date.month, date.day);
    return state.any((entry) {
      if (exceptId != null && entry.id == exceptId) return false;
      final d = DateTime(entry.date.year, entry.date.month, entry.date.day);
      return d == target;
    });
  }

  // Get entries for all time (used by monthly summary)
  List<MilkEntry> getAllEntries() {
    return _repo.getAllEntries();
  }

  Future<void> add(MilkEntry entry) async {
    await _repo.addEntry(entry);
    refresh();
  }

  Future<void> update(MilkEntry entry) async {
    await _repo.updateEntry(entry);
    refresh();
  }

  Future<void> remove(String id) async {
    await _repo.deleteEntry(id);
    refresh();
  }

  Future<MilkEntry?> addTodayFromLast(MilkEntry last, {DateTime? now}) async {
    final DateTime nowDt = now ?? DateTime.now();
    final DateTime today = DateTime(nowDt.year, nowDt.month, nowDt.day, nowDt.hour, nowDt.minute, nowDt.second);
    if (hasEntryForDate(today)) {
      // Still allow another entry for today; timestamp differentiates
    }
    final MilkEntry newEntry = last.copyWith(
      id: const Uuid().v4(),
      date: today,
    );
    await _repo.addEntry(newEntry);
    refresh();
    return newEntry;
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, Settings>((ref) {
  final repo = ref.read(ledgerRepositoryProvider);
  return SettingsNotifier(repo)..load();
});

class SettingsNotifier extends StateNotifier<Settings> {
  SettingsNotifier(this._repo) : super(const Settings(defaultPricePerLiter: 60.0, currency: 'INR'));
  final LedgerRepository _repo;

  void load() {
    state = _repo.getSettings();
  }

  Future<void> update(Settings settings) async {
    await _repo.updateSettings(settings);
    state = settings;
  }
}

final categoriesProvider = StateNotifierProvider<CategoriesNotifier, List<MilkCategory>>((ref) {
  final repo = ref.read(ledgerRepositoryProvider);
  return CategoriesNotifier(repo)..refresh();
});

class CategoriesNotifier extends StateNotifier<List<MilkCategory>> {
  CategoriesNotifier(this._repo) : super(const []);
  final LedgerRepository _repo;

  void refresh() {
    state = _repo.getAllCategories();
  }

  Future<void> add(MilkCategory category) async {
    await _repo.addCategory(category);
    refresh();
  }

  Future<void> update(MilkCategory category) async {
    await _repo.updateCategory(category);
    refresh();
  }

  Future<void> remove(String id) async {
    await _repo.deleteCategory(id);
    refresh();
  }
}


