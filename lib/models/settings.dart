import 'package:hive/hive.dart';

@HiveType(typeId: 12)
class Settings {
  @HiveField(0)
  final double defaultPricePerLiter;

  @HiveField(1)
  final String currency; // e.g. INR

  @HiveField(2)
  final bool dailyReminderEnabled;

  @HiveField(3)
  final int? reminderHour; // 0-23

  @HiveField(4)
  final int? reminderMinute; // 0-59

  const Settings({
    required this.defaultPricePerLiter,
    this.currency = 'INR',
    this.dailyReminderEnabled = false,
    this.reminderHour,
    this.reminderMinute,
  });

  Settings copyWith({
    double? defaultPricePerLiter,
    String? currency,
    bool? dailyReminderEnabled,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return Settings(
      defaultPricePerLiter: defaultPricePerLiter ?? this.defaultPricePerLiter,
      currency: currency ?? this.currency,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }
}

class SettingsAdapter extends TypeAdapter<Settings> {
  @override
  final int typeId = 12;

  @override
  Settings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Settings(
      defaultPricePerLiter: (fields[0] as num).toDouble(),
      currency: fields[1] as String? ?? 'INR',
      dailyReminderEnabled: fields[2] as bool? ?? false,
      reminderHour: (fields[3] as int?),
      reminderMinute: (fields[4] as int?),
    );
  }

  @override
  void write(BinaryWriter writer, Settings obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.defaultPricePerLiter)
      ..writeByte(1)
      ..write(obj.currency)
      ..writeByte(2)
      ..write(obj.dailyReminderEnabled)
      ..writeByte(3)
      ..write(obj.reminderHour)
      ..writeByte(4)
      ..write(obj.reminderMinute);
  }
}


