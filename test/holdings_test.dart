import 'package:flutter_test/flutter_test.dart';
import 'package:ticker_sim/core/models/holding.dart';
import 'package:decimal/decimal.dart';

void main() {
  group('Holdings P&L Calculations', () {
    test('PnL in rupees equals (ltp - avgCost) * qty', () {
      const qty = 10;
      const avgCost = 1400;
      const ltp = 1500;

      final currentValue = Decimal.parse(ltp.toString()) * Decimal.fromInt(qty);
      final costBasis = Decimal.parse(avgCost.toString()) * Decimal.fromInt(qty);
      final pnl = currentValue - costBasis;

      // (1500 - 1400) * 10 = 100 * 10 = 1000
      expect(pnl, equals(Decimal.parse('1000')));
    });

    test('PnL percent equals ((ltp - avgCost) / avgCost) * 100', () {
      const avgCost = 1400;
      const ltp = 1500;

      final pnl = Decimal.parse(ltp.toString()) - Decimal.parse(avgCost.toString());
      final pnlPercent = (pnl * Decimal.fromInt(100)) / Decimal.parse(avgCost.toString());

      // (1500 - 1400) / 1400 * 100 = 100/1400 * 100 = 7.1428...%
      expect(pnlPercent.toDouble(), closeTo(7.14, 0.01));
    });

    test('aggregate summary equals sum of individual rows', () {
      final holdings = [
        Holding(symbol: 'RELIANCE', quantity: 10, avgCost: Decimal.parse('1400')),
        Holding(symbol: 'TCS', quantity: 5, avgCost: Decimal.parse('3200')),
        Holding(symbol: 'INFY', quantity: 20, avgCost: Decimal.parse('1500')),
      ];

      final totalQty = holdings.fold<int>(
        0,
        (sum, h) => sum + h.quantity,
      );
      expect(totalQty, equals(35));

      final totalCostBasis = holdings.fold<Decimal>(
        Decimal.zero,
        (sum, h) => sum + (h.avgCost * Decimal.fromInt(h.quantity)),
      );
      // 10*1400 + 5*3200 + 20*1500 = 14000 + 16000 + 30000 = 60000
      expect(totalCostBasis, equals(Decimal.parse('60000')));
    });

    test('empty holdings list returns zero aggregate', () {
      final holdings = <Holding>[];
      final totalCostBasis = holdings.fold<Decimal>(
        Decimal.zero,
        (sum, h) => sum + (h.avgCost * Decimal.fromInt(h.quantity)),
      );
      expect(totalCostBasis, equals(Decimal.zero));
    });
  });

  group('Holdings Sorting', () {
    test('sort by symbol alphabetically', () {
      final holdings = [
        Holding(symbol: 'TCS', quantity: 5, avgCost: Decimal.parse('3200')),
        Holding(symbol: 'RELIANCE', quantity: 10, avgCost: Decimal.parse('1400')),
        Holding(symbol: 'INFY', quantity: 20, avgCost: Decimal.parse('1500')),
      ];

      holdings.sort((a, b) => a.symbol.compareTo(b.symbol));

      expect(holdings.map((h) => h.symbol).toList(),
          equals(['INFY', 'RELIANCE', 'TCS']));
    });

    test('sort by value descending (avgCost * qty)', () {
      final holdings = [
        Holding(symbol: 'RELIANCE', quantity: 10, avgCost: Decimal.parse('1400')),  // 14000
        Holding(symbol: 'TCS', quantity: 5, avgCost: Decimal.parse('3200')),      // 16000
        Holding(symbol: 'INFY', quantity: 20, avgCost: Decimal.parse('1500')),    // 30000
      ];

      holdings.sort((a, b) {
        final aValue = a.avgCost * Decimal.fromInt(a.quantity);
        final bValue = b.avgCost * Decimal.fromInt(b.quantity);
        return bValue.compareTo(aValue); // descending
      });

      expect(holdings.map((h) => h.symbol).toList(),
          equals(['INFY', 'TCS', 'RELIANCE']));
    });
  });
}
