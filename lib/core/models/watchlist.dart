import 'package:hive/hive.dart';

part 'watchlist.g.dart';

@HiveType(typeId: 0)
class Watchlist extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<String> symbols; // ordered list of stock symbols

  Watchlist({required this.id, required this.name, required this.symbols});

  Watchlist copyWith({String? id, String? name, List<String>? symbols}) {
    return Watchlist(
      id: id ?? this.id,
      name: name ?? this.name,
      symbols: symbols ?? this.symbols,
    );
  }
}
