import 'dart:async';
import 'dart:math';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/market_constants.dart';
import '../models/price_tick.dart';

// Singleton price feed service generating PriceTick events.
class PriceFeedService {
  PriceFeedService._internal();
  static final PriceFeedService _instance = PriceFeedService._internal();
  factory PriceFeedService() => _instance;

  final _controller = StreamController<PriceTick>.broadcast();
  Timer? _timer;

  // Start the periodic feed.
  void start({int intervalMs = 500}) {
    _timer ??= Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      for (final symbol in kStartingPrices.keys) {
        final last = _lastPrices[symbol] ?? kStartingPrices[symbol]!;
        // Simple random walk +/-0.5%
        final delta = (Decimal.fromInt(Random().nextInt(101) - 50) /
                Decimal.fromInt(10000))
            .toDecimal(scaleOnInfinitePrecision: 8);
        final rawPrice = last * (Decimal.one + delta);
        final newPrice =
            Decimal.parse(rawPrice.toStringAsFixed(2));
        final change = newPrice - kStartingPrices[symbol]!;
        final changePercent = (change / kStartingPrices[symbol]!)
            .toDecimal(scaleOnInfinitePrecision: 4) *
            Decimal.fromInt(100);
        final tick = PriceTick(
          symbol: symbol,
          ltp: newPrice,
          change: change,
          changePercent: changePercent,
          timestamp: DateTime.now(),
        );
        _lastPrices[symbol] = newPrice;
        _controller.add(tick);
      }
    });
  }

  // Expose the broadcast stream.
  Stream<PriceTick> get stream => _controller.stream;

  // Internal map to keep last price per symbol.
  final Map<String, Decimal> _lastPrices = {};

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}

// Riverpod provider for the service singleton.
final priceFeedServiceProvider = Provider<PriceFeedService>((ref) {
  final service = PriceFeedService();
  // Start feed when provider is first read.
  service.start();
  ref.onDispose(() => service.dispose());
  return service;
});

// StreamProvider emitting all ticks.
final priceFeedStreamProvider = StreamProvider.autoDispose<PriceTick>((ref) {
  final service = ref.watch(priceFeedServiceProvider);
  return service.stream;
});
