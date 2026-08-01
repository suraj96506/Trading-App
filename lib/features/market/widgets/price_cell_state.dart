import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import '../../../core/providers/price_provider.dart';
import '../../../core/models/price_tick.dart';
import '../../../core/constants/market_constants.dart';
import '../../../shared/theme/app_theme.dart';

// State class for a single price cell.
@immutable
class PriceCellState {
  final List<double> history;
  final bool flashPositive;
  final bool flashNegative;
  final Decimal? previousLtp;
  const PriceCellState({
    this.history = const [],
    this.flashPositive = false,
    this.flashNegative = false,
    this.previousLtp,
  });

  PriceCellState copyWith({
    List<double>? history,
    bool? flashPositive,
    bool? flashNegative,
    Decimal? previousLtp,
  }) {
    return PriceCellState(
      history: history ?? this.history,
      flashPositive: flashPositive ?? this.flashPositive,
      flashNegative: flashNegative ?? this.flashNegative,
      previousLtp: previousLtp ?? this.previousLtp,
    );
  }
}

class PriceCellNotifier extends StateNotifier<PriceCellState> {
  PriceCellNotifier() : super(const PriceCellState());
  Timer? _flashTimer;
  Timer? _debounceTimer;
  bool _needsUpdate = false;

  void _scheduleDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 120), () {
      if (_needsUpdate) {
        // Trigger a state change to rebuild UI.
        state = state.copyWith();
        _needsUpdate = false;
      }
    });
  }

  void onTick(PriceTick tick) {
    final ltpDouble = double.tryParse(tick.ltp.toString()) ?? 0.0;
    final List<double> newHistory = List<double>.from(state.history);
    if (newHistory.isEmpty || (newHistory.last - ltpDouble).abs() > 0.001) {
      newHistory.add(ltpDouble);
      if (newHistory.length > 20) newHistory.removeAt(0);
    }

    bool flashPos = false;
    bool flashNeg = false;
    Decimal? prev = state.previousLtp;
    if (prev != null) {
      final cmp = tick.ltp.compareTo(prev);
      if (cmp != 0) {
        flashPos = cmp > 0;
        flashNeg = cmp < 0;
        _flashTimer?.cancel();
        _flashTimer = Timer(const Duration(milliseconds: 700), () {
          // Reset flash flags after timeout.
          state = state.copyWith(flashPositive: false, flashNegative: false);
        });
      }
    }

    // Update state with new values.
    state = state.copyWith(
      history: newHistory,
      flashPositive: flashPos,
      flashNegative: flashNeg,
      previousLtp: tick.ltp,
    );
    _needsUpdate = true;
    _scheduleDebounce();
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }
}

// Provider family keyed by symbol.
final priceCellProvider = StateNotifierProvider.family<PriceCellNotifier, PriceCellState, String>((ref, symbol) {
  return PriceCellNotifier();
});
