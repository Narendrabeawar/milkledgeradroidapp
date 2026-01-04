import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milk_ledger/models/settings.dart';
import 'package:milk_ledger/providers.dart';
import 'package:milk_ledger/screens/category_management_screen.dart';
import 'package:milk_ledger/services/notification_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  static const String route = '/settings';

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _priceCtrl;
  late TextEditingController _currencyCtrl;
  bool _dailyReminderEnabled = false;
  TimeOfDay? _reminderTime;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _priceCtrl = TextEditingController(text: s.defaultPricePerLiter.toStringAsFixed(2));
    _currencyCtrl = TextEditingController(text: s.currency);
    _dailyReminderEnabled = s.dailyReminderEnabled;
    if (s.reminderHour != null && s.reminderMinute != null) {
      _reminderTime = TimeOfDay(hour: s.reminderHour!, minute: s.reminderMinute!);
    }
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _currencyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _priceCtrl,
            decoration: const InputDecoration(labelText: 'Default Price per Liter'),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _currencyCtrl,
            decoration: const InputDecoration(labelText: 'Currency'),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            title: const Text('Daily reminder to add milk'),
            value: _dailyReminderEnabled,
            onChanged: (v) async {
              if (!v) {
                setState(() => _dailyReminderEnabled = false);
                return;
              }
              if (_reminderTime == null) {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 19, minute: 0),
                );
                if (picked == null) {
                  return;
                }
                setState(() {
                  _dailyReminderEnabled = true;
                  _reminderTime = picked;
                });
              } else {
                setState(() => _dailyReminderEnabled = v);
              }
            },
          ),
          if (_dailyReminderEnabled) ...[
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Reminder time'),
              subtitle: Text(_reminderTime == null
                  ? 'Not set'
                  : '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'),
              trailing: IconButton(
                icon: const Icon(Icons.access_time_outlined),
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _reminderTime ?? const TimeOfDay(hour: 19, minute: 0),
                  );
                  if (picked != null) {
                    setState(() => _reminderTime = picked);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await NotificationService.instance.showTestNotification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test notification sent')));
                }
              },
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Send test notification'),
            ),
          ],
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Milk Categories'),
            subtitle: const Text('Manage milk categories'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.pushNamed(context, CategoryManagementScreen.route),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () async {
              final price = double.tryParse(_priceCtrl.text);
              final currency = _currencyCtrl.text.trim().isEmpty ? 'INR' : _currencyCtrl.text.trim().toUpperCase();
              if (price == null || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid price')));
                return;
              }
              if (_dailyReminderEnabled && _reminderTime == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a reminder time')));
                return;
              }
              final updated = Settings(
                defaultPricePerLiter: price,
                currency: currency,
                dailyReminderEnabled: _dailyReminderEnabled,
                reminderHour: _reminderTime?.hour,
                reminderMinute: _reminderTime?.minute,
              );
              await ref.read(settingsProvider.notifier).update(updated);
              // Schedule/cancel notifications based on settings
              if (_dailyReminderEnabled && _reminderTime != null) {
                await NotificationService.instance.scheduleDailyReminder(
                  hour: _reminderTime!.hour,
                  minute: _reminderTime!.minute,
                );
              } else {
                await NotificationService.instance.cancelDailyReminder();
              }
              if (mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }
}


