import 'package:hive/hive.dart';
import 'package:decimal/decimal.dart';

part 'wallet.g.dart';

@HiveType(typeId: 1)
class Wallet extends HiveObject {
  @HiveField(0)
  Decimal balance;

  Wallet({required this.balance});

  // Convenience method to adjust balance
  void add(Decimal amount) => balance += amount;
  void subtract(Decimal amount) => balance -= amount;
}
