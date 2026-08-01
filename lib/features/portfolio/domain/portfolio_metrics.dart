import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticker_sim/core/constants/market_constants.dart';
import 'package:ticker_sim/core/models/holding.dart';
import 'package:ticker_sim/core/providers/price_provider.dart';

class PortfolioMetrics {
  final Decimal walletBalance;
  final Decimal currentHoldingsValue;
  final Decimal totalInvested;
  final Decimal totalPortfolioValue;
  final Decimal unrealizedPnl;
  final Decimal unrealizedPnlPercent;
  final Decimal totalReturn;
  final Decimal totalReturnPercent;

  const PortfolioMetrics({
    required this.walletBalance,
    required this.currentHoldingsValue,
    required this.totalInvested,
    required this.totalPortfolioValue,
    required this.unrealizedPnl,
    required this.unrealizedPnlPercent,
    required this.totalReturn,
    required this.totalReturnPercent,
  });

  bool get isPositiveTotalReturn => totalReturn >= Decimal.zero;
  bool get isPositiveUnrealizedPnl => unrealizedPnl >= Decimal.zero;

  static PortfolioMetrics fromHoldings(
    WidgetRef ref,
    List<Holding> holdings,
    Decimal walletBalance,
  ) {
    Decimal currentHoldingsValue = Decimal.zero;
    Decimal totalInvested = Decimal.zero;

    for (final h in holdings) {
      final priceTick = ref.watch(priceProvider(h.symbol)).valueOrNull;
      final ltp = priceTick?.ltp ?? h.avgCost;
      final qty = Decimal.fromInt(h.quantity);
      currentHoldingsValue += ltp * qty;
      totalInvested += h.avgCost * qty;
    }

    final totalPortfolioValue = walletBalance + currentHoldingsValue;
    final unrealizedPnl = currentHoldingsValue - totalInvested;
    final unrealizedPnlPercent = totalInvested > Decimal.zero
        ? (unrealizedPnl * Decimal.fromInt(100) / totalInvested)
            .toDecimal(scaleOnInfinitePrecision: 2)
        : Decimal.zero;

    final initialBalance = Decimal.parse(kInitialWalletBalance);
    final totalReturn = totalPortfolioValue - initialBalance;
    final totalReturnPercent = initialBalance > Decimal.zero
        ? (totalReturn * Decimal.fromInt(100) / initialBalance)
            .toDecimal(scaleOnInfinitePrecision: 2)
        : Decimal.zero;

    return PortfolioMetrics(
      walletBalance: walletBalance,
      currentHoldingsValue: currentHoldingsValue,
      totalInvested: totalInvested,
      totalPortfolioValue: totalPortfolioValue,
      unrealizedPnl: unrealizedPnl,
      unrealizedPnlPercent: unrealizedPnlPercent,
      totalReturn: totalReturn,
      totalReturnPercent: totalReturnPercent,
    );
  }
}
