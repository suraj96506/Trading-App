import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticker_sim/core/services/price_feed_service.dart';
import 'package:ticker_sim/core/constants/market_constants.dart';
import 'package:ticker_sim/core/models/price_tick.dart';
import 'package:decimal/decimal.dart';

void main() {
  group('PriceFeedService', () {
    late PriceFeedService service;

    setUp(() {
      service = PriceFeedService();
    });

    tearDown(() {
      service.dispose();
    });

    test('starts emitting ticks within reasonable time', () async {
      service.start(intervalMs: 100);
      final ticks = <String>[];
      final subscription = service.stream.listen((tick) {
        ticks.add(tick.symbol);
      });
      // Wait for at least one complete round (10 symbols)
      await Future.delayed(const Duration(seconds: 1));
      subscription.cancel();
      expect(ticks.length, greaterThan(0));
      // All starting symbols should appear
      for (final symbol in kStartingPrices.keys) {
        expect(ticks, contains(symbol));
      }
    });

    test('same stock → same LTP across multiple subscribers', () async {
      service.start(intervalMs: 100);
      final tick1Completer = Completer<String>();
      final tick2Completer = Completer<String>();

      final sub1 = service.stream.listen((tick) {
        if (tick.symbol == 'RELIANCE' && !tick1Completer.isCompleted) {
          tick1Completer.complete(tick.ltp.toStringAsFixed(2));
        }
      });

      final sub2 = service.stream.listen((tick) {
        if (tick.symbol == 'RELIANCE' && !tick2Completer.isCompleted) {
          tick2Completer.complete(tick.ltp.toStringAsFixed(2));
        }
      });

      // Wait for both subscribers to receive a RELIANCE tick
      final ltp1 = await tick1Completer.future;
      final ltp2 = await tick2Completer.future;

      sub1.cancel();
      sub2.cancel();

      expect(ltp1, equals(ltp2), reason: 'All subscribers must see same LTP for RELIANCE');
    });

    test('every tick includes all 10 symbols', () async {
      service.start(intervalMs: 100);
      final received = <String>{};
      final completer = Completer<void>();

      late StreamSubscription subscription;
      subscription = service.stream.listen((tick) {
        received.add(tick.symbol);
        if (received.length == kStartingPrices.length) {
          completer.complete();
          subscription.cancel();
        }
      });

      await completer.future;
      expect(received.length, equals(kStartingPrices.length));
    });

    test('ltp changes are bounded by ±0.5%', () async {
      service.start(intervalMs: 100);
      PriceTick? firstTick;
      final completer = Completer<void>();

      late StreamSubscription subscription;
      subscription = service.stream.listen((tick) {
        if (tick.symbol == 'RELIANCE') {
          if (firstTick == null) {
            firstTick = tick;
          } else {
            final maxDelta = firstTick!.ltp * Decimal.parse('0.005');
            final actualDelta = (tick.ltp - firstTick!.ltp).abs();
            expect(
              actualDelta <= maxDelta + Decimal.parse('0.01'),
              isTrue,
              reason: 'Price change $actualDelta should be within ±0.5% of last price ${firstTick!.ltp}',
            );
            subscription.cancel();
            completer.complete();
          }
        }
      });

      await completer.future;
    });

    test('setInterval updates intervalMs dynamically', () {
      service.start(intervalMs: 500);
      expect(service.intervalMs, equals(500));
      service.setInterval(200);
      expect(service.intervalMs, equals(200));
    });
  });
}
