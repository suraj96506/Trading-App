import 'package:flutter_riverpod/flutter_riverpod.dart';

class StockPickerState {
  final Set<String> selected;
  final String query;

  const StockPickerState({
    required this.selected,
    required this.query,
  });

  StockPickerState copyWith({
    Set<String>? selected,
    String? query,
  }) {
    return StockPickerState(
      selected: selected ?? this.selected,
      query: query ?? this.query,
    );
  }
}

class StockPickerNotifier extends StateNotifier<StockPickerState> {
  StockPickerNotifier(List<String> initialSymbols)
      : super(StockPickerState(
          selected: Set.from(initialSymbols),
          query: '',
        ));

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void toggleSymbol(String symbol) {
    final newSelected = Set<String>.from(state.selected);
    if (newSelected.contains(symbol)) {
      newSelected.remove(symbol);
    } else {
      newSelected.add(symbol);
    }
    state = state.copyWith(selected: newSelected);
  }

  void toggleAll(List<String> allSymbols) {
    if (state.selected.length == allSymbols.length) {
      state = state.copyWith(selected: {});
    } else {
      state = state.copyWith(selected: Set.from(allSymbols));
    }
  }
}

final stockPickerProvider = StateNotifierProvider.family.autoDispose<StockPickerNotifier, StockPickerState, List<String>>((ref, initialSymbols) {
  return StockPickerNotifier(initialSymbols);
});
