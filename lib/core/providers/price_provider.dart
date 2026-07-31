import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/price_feed_service.dart';
import '../models/price_tick.dart';

/// Provides the latest `PriceTick` for a given `symbol`.
/// Uses the global `priceFeedServiceProvider` and filters by symbol.
final priceProvider = StreamProvider.autoDispose.family<PriceTick, String>((ref, symbol) {
  // Listen to the shared price feed service directly.
  final service = ref.watch(priceFeedServiceProvider);
  // Emit only ticks for the requested symbol.
  return service.stream.where((tick) => tick.symbol == symbol);
});
