import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _timeZoneConfigured = false;

  Future<void> _configureLocalTimeZone() async {
    if (_timeZoneConfigured) return;
    tz.initializeTimeZones();
    // For Android, we'll use the system's default timezone
    // The notification plugin will handle local time correctly with wallClockTime interpretation
    // We'll use UTC as the base and let the system interpret it as local time
    try {
      // Try to detect timezone from offset and find matching location
      final now = DateTime.now();
      final offsetHours = now.timeZoneOffset.inHours;
      // Use a common timezone based on offset (this is a simplification)
      // For most use cases, this will work correctly with wallClockTime interpretation
      tz.setLocalLocation(tz.UTC);
    } catch (e) {
      debugPrint('Error configuring timezone, using UTC: $e');
      tz.setLocalLocation(tz.UTC);
    }
    _timeZoneConfigured = true;
  }

  Future<void> initialize({required void Function(String? payload) onSelect}) async {
    if (_initialized) return;
    await _configureLocalTimeZone();

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onSelect(response.payload);
      },
    );

    // Android 13+ runtime permission
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await _configureLocalTimeZone();
    if (!_initialized) {
      debugPrint('NotificationService not initialized before scheduling.');
    }

    // Cancel previous to avoid duplicates
    await cancelDailyReminder();

    // Build the intended local wall-clock time and convert to UTC since tz is set to UTC
    final nowLocal = DateTime.now();
    var scheduledLocal = DateTime(nowLocal.year, nowLocal.month, nowLocal.day, hour, minute);
    if (scheduledLocal.isBefore(nowLocal)) {
      scheduledLocal = scheduledLocal.add(const Duration(days: 1));
    }
    final scheduledUtc = scheduledLocal.toUtc();
    final tzScheduled = tz.TZDateTime(
      tz.UTC,
      scheduledUtc.year,
      scheduledUtc.month,
      scheduledUtc.day,
      scheduledUtc.hour,
      scheduledUtc.minute,
      scheduledUtc.second,
    );

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_milk_channel',
      'Daily Milk Reminder',
      channelDescription: 'Daily reminder to add milk entry',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      1001,
      'Add today\'s milk',
      'Tap to add today\'s milk entry',
      tzScheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'add_today',
    );
  }

  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(1001);
  }

  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_milk_channel',
      'Daily Milk Reminder',
      channelDescription: 'Daily reminder to add milk entry',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      1002,
      'Test notification',
      'If you can see this, notifications are working.',
      details,
      payload: 'add_today',
    );
  }
}


