import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:milk_ledger/screens/dashboard_screen.dart';
import 'package:milk_ledger/screens/add_entry_screen.dart';
import 'package:milk_ledger/screens/monthly_summary_screen.dart';
import 'package:milk_ledger/screens/settings_screen.dart';
import 'package:milk_ledger/screens/category_management_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class MilkLedgerApp extends StatelessWidget {
  const MilkLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32));
    final theme = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(centerTitle: true),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    );

    return ProviderScope(
      child: MaterialApp(
        title: 'Milk Ledger',
        debugShowCheckedModeBanner: false,
        theme: theme,
        navigatorKey: appNavigatorKey,
        routes: {
          '/': (_) => const DashboardScreen(),
          AddEntryScreen.route: (_) => const AddEntryScreen(),
          MonthlySummaryScreen.route: (_) => const MonthlySummaryScreen(),
          SettingsScreen.route: (_) => const SettingsScreen(),
          CategoryManagementScreen.route: (_) => const CategoryManagementScreen(),
        },
      ),
    );
  }
}



