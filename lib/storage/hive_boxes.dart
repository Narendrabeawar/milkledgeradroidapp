import 'package:hive/hive.dart';
import 'package:milk_ledger/models/milk_category.dart';
import 'package:milk_ledger/models/milk_entry.dart';
import 'package:milk_ledger/models/settings.dart';

class HiveBoxes {
  static const String entries = 'milk_entries_box';
  static const String settings = 'settings_box';
  static const String categories = 'milk_categories_box';

  static Future<void> ensureOpened() async {
    if (!Hive.isBoxOpen(entries)) {
      await Hive.openBox<MilkEntry>(entries);
    }
    if (!Hive.isBoxOpen(settings)) {
      await Hive.openBox<Settings>(settings);
    }
    if (!Hive.isBoxOpen(categories)) {
      await Hive.openBox<MilkCategory>(categories);
    }

    // Seed default settings
    final settingsBox = Hive.box<Settings>(settings);
    if (settingsBox.isEmpty) {
      await settingsBox.put('app_settings', const Settings(defaultPricePerLiter: 60.0, currency: 'INR'));
    }

    // Seed default categories
    final categoriesBox = Hive.box<MilkCategory>(categories);
    if (categoriesBox.isEmpty) {
      await categoriesBox.put(MilkCategory.cowMilkId, MilkCategory.cowMilk);
      await categoriesBox.put(MilkCategory.buffaloMilkId, MilkCategory.buffaloMilk);
    } else {
      // Migrate existing categories to include defaultPricePerLiter
      await _migrateCategoriesWithDefaultPrices(categoriesBox);
    }
  }

  static Future<void> _migrateCategoriesWithDefaultPrices(Box<MilkCategory> categoriesBox) async {
    final categoriesToUpdate = <String, MilkCategory>{};

    for (final entry in categoriesBox.toMap().entries) {
      final category = entry.value;
      // If category doesn't have default price (would be 0 or null), set defaults
      if (category.defaultPricePerLiter == 0.0) {
        if (category.id == MilkCategory.cowMilkId) {
          categoriesToUpdate[entry.key] = MilkCategory.cowMilk;
        } else if (category.id == MilkCategory.buffaloMilkId) {
          categoriesToUpdate[entry.key] = MilkCategory.buffaloMilk;
        } else {
          // For custom categories, use a reasonable default
          categoriesToUpdate[entry.key] = category.copyWith(defaultPricePerLiter: 60.0);
        }
      }
    }

    // Update categories with default prices
    for (final entry in categoriesToUpdate.entries) {
      await categoriesBox.put(entry.key, entry.value);
    }
  }
}


