import 'package:flutter/foundation.dart';

enum OrderFilter { all, buy, sell }

@immutable
class OrdersScreenState {
  final String searchQuery;
  final OrderFilter filter;

  const OrdersScreenState({
    this.searchQuery = '',
    this.filter = OrderFilter.all,
  });

  OrdersScreenState copyWith({
    String? searchQuery,
    OrderFilter? filter,
  }) {
    return OrdersScreenState(
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
    );
  }
}
