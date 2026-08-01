import 'package:flutter/foundation.dart';

enum MarketSortOption { symbol, price, change }

@immutable
class MarketScreenState {
  final String searchQuery;
  final MarketSortOption sort;
  final bool ascending;

  const MarketScreenState({
    this.searchQuery = '',
    this.sort = MarketSortOption.symbol,
    this.ascending = true,
  });

  MarketScreenState copyWith({
    String? searchQuery,
    MarketSortOption? sort,
    bool? ascending,
  }) {
    return MarketScreenState(
      searchQuery: searchQuery ?? this.searchQuery,
      sort: sort ?? this.sort,
      ascending: ascending ?? this.ascending,
    );
  }
}
