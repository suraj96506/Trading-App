import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticker_sim/core/services/storage_service.dart';
import 'package:ticker_sim/core/models/order.dart';

final ordersStreamProvider = StreamProvider.autoDispose<List<Order>>((ref) async* {
  final box = StorageService.instance.box<Order>('orders');
  yield _sorted(box);
  await for (final _ in box.watch()) {
    yield _sorted(box);
  }
});

List<Order> _sorted(dynamic box) {
  final list = box.values.toList() as List<Order>;
  list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return list;
}
