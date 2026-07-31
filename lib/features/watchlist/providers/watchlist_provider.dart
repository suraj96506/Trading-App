import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticker_sim/core/services/storage_service.dart';
import 'package:ticker_sim/core/models/watchlist.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Reads all watchlists reactively via Hive box watcher.
final watchlistsStreamProvider = StreamProvider.autoDispose<List<Watchlist>>((ref) async* {
  final box = StorageService.instance.box<Watchlist>('watchlist');
  yield box.values.toList();
  await for (final _ in box.watch()) {
    yield box.values.toList();
  }
});

/// Returns the count of watchlists.
final watchlistCountProvider = Provider<int>((ref) {
  final box = StorageService.instance.box<Watchlist>('watchlist');
  return box.length;
});

/// Creates a new watchlist and persists it to Hive.
final createWatchlistProvider = Provider<void>((ref) {
  return;
});

/// Deletes a watchlist by id.
final deleteWatchlistProvider = Provider<void Function(String id)>((ref) {
  return (String id) {
    final box = StorageService.instance.box<Watchlist>('watchlist');
    final index = box.values.toList().indexWhere((w) => w.id == id);
    if (index != -1) {
      box.deleteAt(index);
    }
  };
});

/// Renames a watchlist by id.
final renameWatchlistProvider = Provider<void Function(String id, String newName)>((ref) {
  return (String id, String newName) {
    final box = StorageService.instance.box<Watchlist>('watchlist');
    final index = box.values.toList().indexWhere((w) => w.id == id);
    if (index != -1) {
      final existing = box.getAt(index)!;
      final updated = existing.copyWith(name: newName);
      box.putAt(index, updated);
    }
  };
});

/// Saves (adds or updates) a watchlist. Used for creation and for saving reordered/updated symbol lists.
final saveWatchlistProvider = Provider<void Function(Watchlist watchlist)>((ref) {
  return (Watchlist watchlist) {
    final box = StorageService.instance.box<Watchlist>('watchlist');
    final index = box.values.toList().indexWhere((w) => w.id == watchlist.id);
    if (index != -1) {
      box.putAt(index, watchlist);
    } else {
      box.add(watchlist);
    }
  };
});

/// Generates a unique id for a new watchlist using the uuid package.
String generateWatchlistId() => _uuid.v4();
