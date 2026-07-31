import 'package:hive/hive.dart';
import 'package:decimal/decimal.dart';

part 'holding.g.dart';

@HiveType(typeId: 2)
class Holding extends HiveObject {
  @HiveField(0)
  final String symbol;

  @HiveField(1)
  int quantity; // integer units

  @HiveField(2)
  Decimal avgCost; // average buy price

  Holding({required this.symbol, required this.quantity, required this.avgCost});
}
