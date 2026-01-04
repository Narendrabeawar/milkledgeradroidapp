import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:milk_ledger/app.dart';
import 'package:milk_ledger/models/milk_category.dart';
import 'package:milk_ledger/models/milk_entry.dart';
import 'package:milk_ledger/models/payment_type.dart';
import 'package:milk_ledger/models/settings.dart';
import 'package:milk_ledger/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(PaymentTypeAdapter());
  Hive.registerAdapter(MilkEntryAdapter());
  Hive.registerAdapter(SettingsAdapter());
  Hive.registerAdapter(MilkCategoryAdapter());

  await NotificationService.instance.initialize(onSelect: (payload) {
    if (payload == 'add_today') {
      // Navigate to Add Entry screen
      appNavigatorKey.currentState?.pushNamed('/add');
    }
  });

  runApp(const MilkLedgerApp());
}


