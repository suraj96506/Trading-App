import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'market_screen_state.dart';

/// StateNotifier managing search, sort, and filter for the Market screen.
class MarketScreenNotifier extends StateNotifier<MarketScreenState> {
  MarketScreenNotifier() : super(const MarketScreenState());

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query.trim());
  }

  void setSort(MarketSortOption option) {
    if (state.sort == option) {
      state = state.copyWith(ascending: !state.ascending);
    } else {
      state = state.copyWith(sort: option, ascending: true);
    }
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }
}

/// Provider — auto-disposed so state resets when screen is off-stack.
final marketScreenProvider =
    StateNotifierProvider.autoDispose<MarketScreenNotifier, MarketScreenState>(
  (ref) => MarketScreenNotifier(),
);
