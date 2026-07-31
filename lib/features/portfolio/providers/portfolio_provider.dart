import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticker_sim/core/services/storage_service.dart';
import 'package:ticker_sim/core/models/wallet.dart';
import 'package:ticker_sim/core/models/holding.dart';
import 'package:decimal/decimal.dart';

enum SortOption { byPnl, bySymbol, byValue }

final sortOptionProvider = StateProvider<SortOption>((ref) => SortOption.byPnl);

final walletStreamProvider = StreamProvider.autoDispose<Wallet>((ref) async* {
  final box = StorageService.instance.box<Wallet>('wallet');
  yield box.getAt(0) ?? Wallet(balance: Decimal.zero);
  await for (final _ in box.watch()) {
    yield box.getAt(0) ?? Wallet(balance: Decimal.zero);
  }
});

final holdingsStreamProvider = StreamProvider.autoDispose<List<Holding>>((ref) async* {
  final box = StorageService.instance.box<Holding>('holdings');
  yield box.values.toList();
  await for (final _ in box.watch()) {
    yield box.values.toList();
  }
});
