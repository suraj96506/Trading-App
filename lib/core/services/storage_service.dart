import 'package:hive_flutter/hive_flutter.dart';
// Model imports
import '../models/watchlist.dart';
import '../models/wallet.dart';
import '../models/holding.dart';
import '../models/order.dart';
import '../models/decimal_adapter.dart';

// Core storage service handling Hive initialization and box access.


class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  /// Initialize Hive and open required boxes.
  Future<void> init() async {
    await Hive.initFlutter();
    // Register adapters for models (generated files).
    // DecimalAdapter must be registered before model adapters that use Decimal.
    Hive.registerAdapter(DecimalAdapter());
    Hive.registerAdapter(WatchlistAdapter());
    Hive.registerAdapter(WalletAdapter());
    Hive.registerAdapter(HoldingAdapter());
    Hive.registerAdapter(OrderAdapter());

    await Future.wait([
      Hive.openBox<Watchlist>('watchlist'),
      Hive.openBox<Wallet>('wallet'),
      Hive.openBox<Holding>('holdings'),
      Hive.openBox<Order>('orders'),
    ]);
  }

  Box<T> box<T>(String name) => Hive.box<T>(name);
}
