import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'orders_screen_state.dart';

/// StateNotifier managing search & filter for the Orders screen.
class OrdersScreenNotifier extends StateNotifier<OrdersScreenState> {
  OrdersScreenNotifier() : super(const OrdersScreenState());

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query.trim());
  }

  void setFilter(OrderFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }
}

/// Provider — auto-disposed so state resets when screen is off-stack.
final ordersScreenProvider =
    StateNotifierProvider.autoDispose<OrdersScreenNotifier, OrdersScreenState>(
  (ref) => OrdersScreenNotifier(),
);
