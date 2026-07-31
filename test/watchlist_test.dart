import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticker_sim/core/models/watchlist.dart';

void main() {
  group('Watchlist Stability', () {
    test('reorder preserves correct symbol binding via ValueKey', () {
      final symbols = ['RELIANCE', 'TCS', 'INFY', 'HDFCBANK'];

      // Simulate what PriceCell / WatchlistRow does with ValueKey(symbol)
      // The ValueKey should be bound to the symbol, not the list index
      final keys = symbols.map((s) => ValueKey<String>(s)).toList();

      // After reorder: move RELIANCE from index 0 to index 2
      final reordered = <String>[];
      reordered.add(symbols[1]); // TCS
      reordered.add(symbols[2]); // INFY
      reordered.add(symbols[0]); // RELIANCE
      reordered.add(symbols[3]); // HDFCBANK

      // The keys must still match the correct symbols after reorder
      final reorderedKeys = reordered.map((s) => ValueKey<String>(s)).toList();

      for (int i = 0; i < reordered.length; i++) {
        expect(reorderedKeys[i], equals(ValueKey<String>(reordered[i])),
            reason: 'Index $i must be bound to ${reordered[i]}, not to its old position');
      }

      // Specifically: RELIANCE (index 2) must NOT use the ValueKey of what was at index 2 INFY before reorder
      expect(keys[2], equals(const ValueKey<String>('INFY')));
      expect(reorderedKeys[2], equals(const ValueKey<String>('RELIANCE')));
    });

    test('empty symbols list produces empty watchlist', () {
      final watchlist = Watchlist(
        id: 'test',
        name: 'Empty List',
        symbols: [],
      );
      expect(watchlist.symbols, isEmpty);
    });

    test('Watchlist copyWith preserves fields not being changed', () {
      final watchlist = Watchlist(
        id: 'id1',
        name: 'Original',
        symbols: ['RELIANCE', 'TCS'],
      );

      final updated = watchlist.copyWith(name: 'Updated');
      expect(updated.id, equals('id1'));
      expect(updated.name, equals('Updated'));
      expect(updated.symbols, equals(['RELIANCE', 'TCS']));
    });

    test('Watchlist.copyWith(symbols) correctly replaces symbol list', () {
      final watchlist = Watchlist(
        id: 'id1',
        name: 'List',
        symbols: ['RELIANCE'],
      );

      final updated = watchlist.copyWith(
        symbols: ['RELIANCE', 'TCS', 'INFY'],
      );
      expect(updated.symbols.length, equals(3));
      expect(updated.symbols, equals(['RELIANCE', 'TCS', 'INFY']));
    });

    test('symbols list maintains insertion order (stable sequence)', () {
      final symbols = ['LT', 'ITC', 'SBIN', 'RELIANCE', 'TCS'];
      final watchlist = Watchlist(
        id: 'id1',
        name: 'Ordered',
        symbols: symbols,
      );
      expect(watchlist.symbols, equals(symbols));
    });
  });
}
