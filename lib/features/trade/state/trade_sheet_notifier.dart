import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'trade_sheet_state.dart';

/// StateNotifier for a single trade sheet instance.
/// Manages price history sparkline and error state.
/// Uses .family so each symbol gets its own isolated notifier.
class TradeSheetNotifier extends StateNotifier<TradeSheetState> {
  TradeSheetNotifier() : super(const TradeSheetState());

  /// Called on each price tick to update the sparkline.
  void onTick(Decimal ltp) {
    final value = double.tryParse(ltp.toString()) ?? 0.0;
    final history = List<double>.from(state.priceHistory);
    if (history.isEmpty || (history.last - value).abs() > 0.001) {
      history.add(value);
      if (history.length > 20) history.removeAt(0);
      state = state.copyWith(priceHistory: history);
    }
  }

  /// Sets or clears the current error message.
  void setError(String? error) {
    state = error == null
        ? state.copyWith(clearError: true)
        : state.copyWith(error: error);
  }

  /// Clears the error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// A family provider so each symbol gets its own isolated state.
/// Auto-disposed when the bottom sheet is dismissed.
final tradeSheetProvider = StateNotifierProvider.autoDispose
    .family<TradeSheetNotifier, TradeSheetState, String>(
  (ref, symbol) => TradeSheetNotifier(),
);
