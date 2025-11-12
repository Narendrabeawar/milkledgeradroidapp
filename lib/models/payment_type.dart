import 'package:hive/hive.dart';

@HiveType(typeId: 10)
enum PaymentType {
  @HiveField(0)
  cash,
  @HiveField(1)
  credit,
}

class PaymentTypeAdapter extends TypeAdapter<PaymentType> {
  @override
  final int typeId = 10;

  @override
  PaymentType read(BinaryReader reader) {
    final value = reader.readByte();
    switch (value) {
      case 0:
        return PaymentType.cash;
      case 1:
        return PaymentType.credit;
      default:
        return PaymentType.cash;
    }
  }

  @override
  void write(BinaryWriter writer, PaymentType obj) {
    switch (obj) {
      case PaymentType.cash:
        writer.writeByte(0);
        break;
      case PaymentType.credit:
        writer.writeByte(1);
        break;
    }
  }
}


