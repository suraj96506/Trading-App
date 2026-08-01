import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import 'package:ticker_sim/core/models/price_tick.dart';

// State representing the flash color for a watchlist row.
class WatchlistRowState {
  final Color flashColor;
  const WatchlistRowState({required this.flashColor});

  // Convenience constructors
  factory WatchlistRowState.transparent() => const WatchlistRowState(flashColor: Colors.transparent);
  factory WatchlistRowState.positive() => WatchlistRowState(flashColor: const Color(0xFF0F8E7A).withValues(alpha: 0.12));
  factory WatchlistRowState.negative() => WatchlistRowState(flashColor: const Color(0xFFE04F61).withValues(alpha: 0.12));
}

class WatchlistRowNotifier extends StateNotifier<WatchlistRowState> {
  Decimal? _lastPrice;

  WatchlistRowNotifier() : super(WatchlistRowState.transparent());

  void onTick(PriceTick tick) {
    if (_lastPrice != null && state.flashColor == Colors.transparent) {
      if (tick.ltp > _lastPrice!) {
        flashPositive();
      } else if (tick.ltp < _lastPrice!) {
        flashNegative();
      }
    }
    _lastPrice = tick.ltp;
  }

  // Trigger a flash for positive change.
  void flashPositive() {
    state = WatchlistRowState.positive();
    _resetAfter(const Duration(milliseconds: 450));
  }

  // Trigger a flash for negative change.
  void flashNegative() {
    state = WatchlistRowState.negative();
    _resetAfter(const Duration(milliseconds: 450));
  }

  void _resetAfter(Duration d) async {
    await Future.delayed(d);
    // Ensure widget is still mounted via provider autoDispose.
    state = WatchlistRowState.transparent();
  }
}

// Provider family keyed by symbol.
final watchlistRowProvider = StateNotifierProvider.autoDispose.family<WatchlistRowNotifier, WatchlistRowState, String>((ref, symbol) {
  return WatchlistRowNotifier();
});
