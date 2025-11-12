import 'package:hive/hive.dart';
import 'package:milk_ledger/models/milk_entry.dart';
import 'package:milk_ledger/models/settings.dart';

class HiveBoxes {
  static const String entries = 'milk_entries_box';
  static const String settings = 'settings_box';

  static Future<void> ensureOpened() async {
    if (!Hive.isBoxOpen(entries)) {
      await Hive.openBox<MilkEntry>(entries);
    }
    if (!Hive.isBoxOpen(settings)) {
      await Hive.openBox<Settings>(settings);
    }

    // Seed default settings
    final settingsBox = Hive.box<Settings>(settings);
    if (settingsBox.isEmpty) {
      await settingsBox.put('app_settings', const Settings(defaultPricePerLiter: 60.0, currency: 'INR'));
    }
  }
}


