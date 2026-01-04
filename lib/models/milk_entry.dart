import 'package:hive/hive.dart';
import 'package:milk_ledger/models/milk_category.dart';
import 'package:milk_ledger/models/payment_type.dart';

@HiveType(typeId: 11)
class MilkEntry {
  @HiveField(0)
  final String id; // uuid string

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final double liters;

  @HiveField(3)
  final double pricePerLiter;

  @HiveField(4)
  final PaymentType paymentType;

  @HiveField(5)
  final MilkCategory milkCategory;

  @HiveField(6)
  final String? note;

  const MilkEntry({
    required this.id,
    required this.date,
    required this.liters,
    required this.pricePerLiter,
    required this.paymentType,
    required this.milkCategory,
    this.note,
  });

  double get amount => liters * pricePerLiter;

  MilkEntry copyWith({
    String? id,
    DateTime? date,
    double? liters,
    double? pricePerLiter,
    PaymentType? paymentType,
    MilkCategory? milkCategory,
    String? note,
  }) {
    return MilkEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      liters: liters ?? this.liters,
      pricePerLiter: pricePerLiter ?? this.pricePerLiter,
      paymentType: paymentType ?? this.paymentType,
      milkCategory: milkCategory ?? this.milkCategory,
      note: note ?? this.note,
    );
  }
}

class MilkEntryAdapter extends TypeAdapter<MilkEntry> {
  @override
  final int typeId = 11;

  @override
  MilkEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MilkEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      liters: (fields[2] as num).toDouble(),
      pricePerLiter: (fields[3] as num).toDouble(),
      paymentType: fields[4] as PaymentType,
      milkCategory: fields[5] as MilkCategory,
      note: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MilkEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.liters)
      ..writeByte(3)
      ..write(obj.pricePerLiter)
      ..writeByte(4)
      ..write(obj.paymentType)
      ..writeByte(5)
      ..write(obj.milkCategory)
      ..writeByte(6)
      ..write(obj.note);
  }
}


