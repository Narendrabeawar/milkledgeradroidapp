import 'package:hive/hive.dart';

@HiveType(typeId: 13)
class MilkCategory {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int colorValue; // Store color as int value

  @HiveField(3)
  final double defaultPricePerLiter;

  const MilkCategory({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.defaultPricePerLiter,
  });

  // Predefined categories
  static const String cowMilkId = 'cow_milk';
  static const String buffaloMilkId = 'buffalo_milk';

  static const MilkCategory cowMilk = MilkCategory(
    id: cowMilkId,
    name: 'Cow Milk',
    colorValue: 0xFF4CAF50, // Green
    defaultPricePerLiter: 60.0,
  );

  static const MilkCategory buffaloMilk = MilkCategory(
    id: buffaloMilkId,
    name: 'Buffalo Milk',
    colorValue: 0xFF2196F3, // Blue
    defaultPricePerLiter: 70.0,
  );

  static List<MilkCategory> get defaultCategories => [cowMilk, buffaloMilk];

  MilkCategory copyWith({
    String? id,
    String? name,
    int? colorValue,
    double? defaultPricePerLiter,
  }) {
    return MilkCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      defaultPricePerLiter: defaultPricePerLiter ?? this.defaultPricePerLiter,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MilkCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class MilkCategoryAdapter extends TypeAdapter<MilkCategory> {
  @override
  final int typeId = 13;

  @override
  MilkCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MilkCategory(
      id: fields[0] as String,
      name: fields[1] as String,
      colorValue: fields[2] as int,
      defaultPricePerLiter: fields[3] as double? ?? 60.0, // Default fallback
    );
  }

  @override
  void write(BinaryWriter writer, MilkCategory obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.colorValue)
      ..writeByte(3)
      ..write(obj.defaultPricePerLiter);
  }
}
