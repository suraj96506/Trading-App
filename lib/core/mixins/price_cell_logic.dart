import 'dart:async';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticker_sim/features/market/state/price_cell_state.dart';
import '../../core/models/price_tick.dart';

/// Mixin that encapsulates the mutable logic used by a price‑cell.
/// It can be applied to any [StateNotifier] that holds a [PriceCellState].
mixin PriceCellLogicMixin on StateNotifier<PriceCellState> {
  Decimal? _previousLtp;
  Timer? _flashTimer;
  Timer? _debounceTimer;
  bool _needsUpdate = false;

  /// Called by the owner when a new [PriceTick] arrives.
  void handleTick(PriceTick tick) {
    // ---------- history handling ----------
    final ltpDouble = double.tryParse(tick.ltp.toString()) ?? 0.0;
    final List<double> newHistory = List.of(state.history);
    if (newHistory.isEmpty || (newHistory.last - ltpDouble).abs() > 0.001) {
      newHistory.add(ltpDouble);
      if (newHistory.length > 20) newHistory.removeAt(0);
    }

    // ---------- flash flag handling ----------
    if (_previousLtp != null) {
      final cmp = tick.ltp.compareTo(_previousLtp!);
      if (cmp != 0) {
        // set flash flags according to direction
        state = state.copyWith(
            flashPositive: cmp > 0,
            flashNegative: cmp < 0,
            history: newHistory);
        _needsUpdate = true;
        _scheduleDebounce();
        // schedule timer to clear flash after 700 ms
        _flashTimer?.cancel();
        _flashTimer = Timer(const Duration(milliseconds: 700), () {
          state = state.copyWith(flashPositive: false, flashNegative: false);
          _needsUpdate = true;
          _scheduleDebounce();
        });
      }
    }

    // ---------- final snapshot update ----------
    _previousLtp = tick.ltp;
    state = state.copyWith(
      ltp: tick.ltp,
      change: tick.change,
      changePct: tick.changePercent,
      history: newHistory,
    );
  }

  /// Debounce helper that batches UI updates.
  void _scheduleDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 120), () {
      if (_needsUpdate) {
        // Emit the current state to force a rebuild.
        state = state;
        _needsUpdate = false;
      }
    });
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }
}
