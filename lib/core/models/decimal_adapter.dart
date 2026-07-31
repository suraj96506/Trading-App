import 'package:hive/hive.dart';
import 'package:decimal/decimal.dart';

class DecimalAdapter extends TypeAdapter<Decimal> {
  @override
  final int typeId = 100;

  @override
  Decimal read(BinaryReader reader) {
    return Decimal.parse(reader.read());
  }

  @override
  void write(BinaryWriter writer, Decimal obj) {
    writer.write(obj.toString());
  }
}
