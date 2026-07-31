import 'package:hive/hive.dart';
import 'package:decimal/decimal.dart';

part 'order.g.dart';

@HiveType(typeId: 3)
class Order extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String symbol;

  @HiveField(2)
  String side; // 'buy' or 'sell'

  @HiveField(3)
  Decimal quantity;

  @HiveField(4)
  Decimal price; // price at execution time

  @HiveField(5)
  DateTime timestamp;

  Order({
    required this.id,
    required this.symbol,
    required this.side,
    required this.quantity,
    required this.price,
    required this.timestamp,
  });
}
