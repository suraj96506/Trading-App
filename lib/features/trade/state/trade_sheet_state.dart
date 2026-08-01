import 'package:flutter/foundation.dart';

@immutable
class TradeSheetState {
  final List<double> priceHistory;
  final String? error;

  const TradeSheetState({
    this.priceHistory = const [],
    this.error,
  });

  TradeSheetState copyWith({
    List<double>? priceHistory,
    String? error,
    bool clearError = false,
  }) {
    return TradeSheetState(
      priceHistory: priceHistory ?? this.priceHistory,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
