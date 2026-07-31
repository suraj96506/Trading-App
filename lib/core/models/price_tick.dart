import 'package:decimal/decimal.dart';

class PriceTick {
  final String symbol;
  final Decimal ltp; // last traded price
  final Decimal change; // absolute change from previous tick
  final Decimal changePercent; // percentage change
  final DateTime timestamp;

  const PriceTick({
    required this.symbol,
    required this.ltp,
    required this.change,
    required this.changePercent,
    required this.timestamp,
  });

  PriceTick copyWith({
    Decimal? ltp,
    Decimal? change,
    Decimal? changePercent,
    DateTime? timestamp,
  }) {
    return PriceTick(
      symbol: symbol,
      ltp: ltp ?? this.ltp,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() => 'PriceTick(symbol: $symbol, ltp: $ltp, change: $change, changePercent: $changePercent, timestamp: $timestamp)';
}
