import 'package:hive_flutter/hive_flutter.dart';
import 'package:decimal/decimal.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/wallet.dart';
import '../../../core/models/holding.dart';
import '../../../core/models/order.dart';
import '../../../core/services/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService.instance);

class TradeExecutor {
  TradeExecutor(this._storage);

  final StorageService _storage;

  Box<Wallet> get _walletBox => _storage.box<Wallet>('wallet');
  Box<Holding> get _holdingsBox => _storage.box<Holding>('holdings');
  Box<Order> get _ordersBox => _storage.box<Order>('orders');

  bool _hasSufficientBalance(Decimal totalCost) {
    if (_walletBox.isEmpty) return false;
    return _walletBox.getAt(0)!.balance >= totalCost;
  }

  bool _hasSufficientQuantity(String symbol, int qty) {
    final holding = _findHolding(symbol);
    return holding != null && holding.quantity >= qty;
  }

  Holding? _findHolding(String symbol) {
    for (var i = 0; i < _holdingsBox.length; i++) {
      final h = _holdingsBox.getAt(i);
      if (h!.symbol == symbol) return h;
    }
    return null;
  }

  (Object? error, bool success) buy(String symbol, int qty, Decimal price) {
    if (qty <= 0) return ('Quantity must be a positive integer', false);
    final totalCost = Decimal.fromInt(qty) * price;
    if (!_hasSufficientBalance(totalCost)) {
      return ('Insufficient balance', false);
    }
    _walletBox.getAt(0)!.subtract(totalCost);
    _walletBox.getAt(0)!.save();

    final existing = _findHolding(symbol);
    if (existing != null) {
      final totalQty = existing.quantity + qty;
      existing.avgCost = (((existing.avgCost * Decimal.fromInt(existing.quantity)) + totalCost) / Decimal.fromInt(totalQty)).toDecimal();
      existing.quantity = totalQty;
      existing.save();
    } else {
      _holdingsBox.add(Holding(
        symbol: symbol,
        quantity: qty,
        avgCost: price,
      ));
    }

    _ordersBox.add(Order(
      id: const Uuid().v4(),
      symbol: symbol,
      side: 'buy',
      quantity: Decimal.fromInt(qty),
      price: price,
      timestamp: DateTime.now(),
    ));

    return (null, true);
  }

  (Object? error, bool success) sell(String symbol, int qty, Decimal price) {
    if (qty <= 0) return ('Quantity must be a positive integer', false);
    if (!_hasSufficientQuantity(symbol, qty)) {
      return ('Insufficient holding quantity', false);
    }
    final holding = _findHolding(symbol)!;
    final proceeds = Decimal.fromInt(qty) * price;
    _walletBox.getAt(0)!.add(proceeds);
    _walletBox.getAt(0)!.save();

    holding.quantity -= qty;
    if (holding.quantity == 0) {
      _holdingsBox.delete(holding.key);
    } else {
      holding.save();
    }

    _ordersBox.add(Order(
      id: const Uuid().v4(),
      symbol: symbol,
      side: 'sell',
      quantity: Decimal.fromInt(qty),
      price: price,
      timestamp: DateTime.now(),
    ));

    return (null, true);
  }
}

final tradeExecutorProvider = Provider<TradeExecutor>((ref) {
  return TradeExecutor(ref.watch(storageServiceProvider));
});
