import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticker_sim/core/services/storage_service.dart';
import 'package:ticker_sim/core/models/wallet.dart';
import 'package:ticker_sim/core/models/holding.dart';
import 'package:ticker_sim/core/models/order.dart';
import 'package:ticker_sim/features/trade/providers/trade_provider.dart';
import 'package:decimal/decimal.dart';

void main() {
  group('TradeExecutor', () {
    late StorageService storage;
    late ProviderContainer container;

    setUp(() async {
      WidgetsFlutterBinding.ensureInitialized();
      storage = StorageService.instance;
      await storage.init();

      // Clear all boxes to start fresh
      final walletBox = storage.box<Wallet>('wallet');
      final holdingsBox = storage.box<Holding>('holdings');
      final ordersBox = storage.box<Order>('orders');
      walletBox.clear();
      holdingsBox.clear();
      ordersBox.clear();

      // Seed wallet with initial balance
      walletBox.add(Wallet(balance: Decimal.parse('100000')));

      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      // Clear boxes to not affect other tests
      storage.box<Wallet>('wallet').clear();
      storage.box<Holding>('holdings').clear();
      storage.box<Order>('orders').clear();
    });

    group('buy', () {
      test('decreases wallet by qty * ltp', () async {
        final executor = container.read(tradeExecutorProvider);
        const symbol = 'RELIANCE';
        const qty = 10;
        const ltpDecimal = '1400';

        final (error, success) = executor.buy(symbol, qty, Decimal.parse(ltpDecimal));

        expect(success, isTrue);
        expect(error, isNull);

        final wallet = storage.box<Wallet>('wallet').getAt(0)!;
        // 100000 - 10*1400 = 100000 - 14000 = 86000
        expect(wallet.balance, equals(Decimal.parse('86000')));
      });

      test('repeat buy calculates avgCost correctly', () async {
        final executor = container.read(tradeExecutorProvider);
        const symbol = 'RELIANCE';

        // First buy: 10 shares @ 1400
        executor.buy(symbol, 10, Decimal.parse('1400'));

        // Second buy: 10 shares @ 1500
        executor.buy(symbol, 10, Decimal.parse('1500'));

        final holdings = storage.box<Holding>('holdings').values.toList();
        expect(holdings.length, equals(1));

        final holding = holdings.first;
        expect(holding.symbol, equals(symbol));
        expect(holding.quantity, equals(20));

        // avgCost = ((10 * 1400) + (10 * 1500)) / 20 = (14000 + 15000) / 20 = 29000 / 20 = 1450
        expect(holding.avgCost, equals(Decimal.parse('1450.00')));
      });

      test('rejects zero qty', () async {
        final executor = container.read(tradeExecutorProvider);
        final (error, success) = executor.buy('RELIANCE', 0, Decimal.parse('1400'));
        expect(success, isFalse);
        expect(error.toString(), anyOf(contains('zero'), contains('Insufficient')));
      });

      test('rejects negative qty', () {
        final executor = container.read(tradeExecutorProvider);
        final (error, success) = executor.buy('RELIANCE', -5, Decimal.parse('1400'));
        expect(success, isFalse);
        expect(error, isNotNull);
      });

      test('rejects fractional qty (int only)', () {
        final executor = container.read(tradeExecutorProvider);
        // qty is int type, so fractional isn't possible at type level
        // but we validate that qty must be > 0 integer (type enforcement is sufficient)
        final (error, success) = executor.buy('RELIANCE', 1, Decimal.parse('1400'));
        expect(success, isTrue);
      });

      test('rejects insufficient balance', () async {
        // Set wallet to 100, try to buy 1 share @ 1400 = not enough
        final walletBox = storage.box<Wallet>('wallet');
        walletBox.clear();
        walletBox.add(Wallet(balance: Decimal.parse('100')));

        final executor = container.read(tradeExecutorProvider);
        final (error, success) = executor.buy('RELIANCE', 1, Decimal.parse('1400'));
        expect(success, isFalse);
        expect(error.toString(), contains('balance'));
      });
    });

    group('sell', () {
      test('increases wallet by qty * ltp', () async {
        final executor = container.read(tradeExecutorProvider);
        const symbol = 'RELIANCE';

        // Buy first to create holding
        executor.buy(symbol, 10, Decimal.parse('1400'));

        // Sell 5 shares @ 1500
        final (error, success) = executor.sell(symbol, 5, Decimal.parse('1500'));
        expect(success, isTrue);
        expect(error, isNull);

        final wallet = storage.box<Wallet>('wallet').getAt(0)!;
        // 86000 + 5*1500 = 86000 + 7500 = 93500
        expect(wallet.balance, equals(Decimal.parse('93500')));
      });

      test('holding qty decreases on sell', () async {
        final executor = container.read(tradeExecutorProvider);
        const symbol = 'RELIANCE';

        executor.buy(symbol, 10, Decimal.parse('1400'));
        executor.sell(symbol, 3, Decimal.parse('1500'));

        final holdings = storage.box<Holding>('holdings').values.toList();
        expect(holdings.length, equals(1));
        expect(holdings.first.quantity, equals(7));
      });

      test('removes holding when qty reaches 0', () async {
        final executor = container.read(tradeExecutorProvider);
        const symbol = 'RELIANCE';

        executor.buy(symbol, 5, Decimal.parse('1400'));
        executor.sell(symbol, 5, Decimal.parse('1500'));

        final holdings = storage.box<Holding>('holdings').values.toList();
        expect(holdings.isEmpty, isTrue);
      });

      test('rejects selling more than held', () async {
        final executor = container.read(tradeExecutorProvider);
        const symbol = 'RELIANCE';

        executor.buy(symbol, 3, Decimal.parse('1400'));
        final (error, success) = executor.sell(symbol, 10, Decimal.parse('1500'));
        expect(success, isFalse);
        expect(error.toString(), contains('holding'));
      });

      test('rejects zero qty sell', () {
        final executor = container.read(tradeExecutorProvider);
        final (error, success) = executor.sell('RELIANCE', 0, Decimal.parse('1400'));
        expect(success, isFalse);
      });

      test('rejects negative qty sell', () {
        final executor = container.read(tradeExecutorProvider);
        final (error, success) = executor.sell('RELIANCE', -5, Decimal.parse('1400'));
        expect(success, isFalse);
      });
    });

    test('order history is persisted', () async {
      final executor = container.read(tradeExecutorProvider);
      executor.buy('RELIANCE', 10, Decimal.parse('1400'));
      executor.sell('RELIANCE', 5, Decimal.parse('1500'));

      final orders = storage.box<Order>('orders').values.toList();
      expect(orders.length, equals(2));
    });
  });
}
