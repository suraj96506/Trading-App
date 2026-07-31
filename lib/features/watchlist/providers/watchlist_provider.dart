import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticker_sim/core/services/storage_service.dart';
import 'package:ticker_sim/core/models/watchlist.dart';

final watchlistsStreamProvider = StreamProvider.autoDispose<List<Watchlist>>((ref) async* {
  final box = StorageService.instance.box<Watchlist>('watchlist');
  yield box.values.toList();
  await for (final _ in box.watch()) {
    yield box.values.toList();
  }
});
