import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticker_sim/core/models/watchlist.dart';
import 'package:flutter/foundation.dart';

@immutable
class WatchlistScreenState {
  final int selectedTabIndex;
  final List<String> symbols;
  final List<String> savedSymbols;
  final bool hasUnsavedChanges;
  final String? currentWatchlistId;

  const WatchlistScreenState({
    this.selectedTabIndex = 0,
    this.symbols = const [],
    this.savedSymbols = const [],
    this.hasUnsavedChanges = false,
    this.currentWatchlistId,
  });

  WatchlistScreenState copyWith({
    int? selectedTabIndex,
    List<String>? symbols,
    List<String>? savedSymbols,
    bool? hasUnsavedChanges,
    String? currentWatchlistId,
  }) {
    return WatchlistScreenState(
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      symbols: symbols ?? this.symbols,
      savedSymbols: savedSymbols ?? this.savedSymbols,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      currentWatchlistId: currentWatchlistId ?? this.currentWatchlistId,
    );
  }

  bool listEquals(List<String> a, List<String> b) => const ListEquality().equals(a, b);
}
