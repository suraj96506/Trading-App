import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

@immutable
class PriceCellState {
  final Decimal ltp;
  final Decimal change;
  final Decimal changePct;
  final bool flashPositive;
  final bool flashNegative;
  final List<double> history; // max 20 points for sparkline

  const PriceCellState({
    required this.ltp,
    required this.change,
    required this.changePct,
    this.flashPositive = false,
    this.flashNegative = false,
    this.history = const [],
  });

  PriceCellState copyWith({
    Decimal? ltp,
    Decimal? change,
    Decimal? changePct,
    bool? flashPositive,
    bool? flashNegative,
    List<double>? history,
  }) =>
      PriceCellState(
        ltp: ltp ?? this.ltp,
        change: change ?? this.change,
        changePct: changePct ?? this.changePct,
        flashPositive: flashPositive ?? this.flashPositive,
        flashNegative: flashNegative ?? this.flashNegative,
        history: history ?? this.history,
      );
}
