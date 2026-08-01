import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticker_sim/core/models/holding.dart';
import 'package:ticker_sim/core/providers/price_provider.dart';
import 'package:ticker_sim/features/portfolio/providers/portfolio_provider.dart';
import 'package:ticker_sim/features/portfolio/state/portfolio_screen_notifier.dart';
import 'package:ticker_sim/features/trade/providers/trade_provider.dart';
import 'package:ticker_sim/features/trade/widgets/trade_bottom_sheet.dart';
import 'package:decimal/decimal.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/constants/market_constants.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletStreamProvider);
    final holdingsAsync = ref.watch(holdingsStreamProvider);
    final sortOption = ref.watch(sortOptionProvider);
    final portfolioState = ref.watch(portfolioScreenProvider);
    final portfolioNotifier = ref.read(portfolioScreenProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    void openTradeSheet(String symbol) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, sc) => TradeBottomSheet(symbol: symbol, scrollController: sc),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.pageGradient(context)),
        child: SafeArea(
          child: walletAsync.when(
            data: (wallet) => holdingsAsync.when(
              data: (holdings) {
                Decimal totalInvested = Decimal.zero;
                for (final h in holdings) {
                  totalInvested += h.avgCost * Decimal.fromInt(h.quantity);
                }

                final sorted = _sortedHoldings(holdings, sortOption, ref);

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: AppTheme.heroCard(context, radius: 28),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(16),
                                                gradient: const LinearGradient(
                                                  colors: [AppTheme.primaryBlueMid, AppTheme.primaryBlueTint],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                              ),
                                              child: const Icon(Icons.account_balance_wallet_rounded,
                                                  color: Colors.white),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Portfolio',
                                              style: Theme.of(context).textTheme.headlineMedium,
                                            ),
                                          ],
                                        ),
                                        if (holdings.isNotEmpty)
                                          _SellAllButton(
                                            loading: portfolioState.sellAllLoading,
                                            onTap: () => portfolioNotifier.confirmSellAll(holdings, context),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _PortfolioSummaryCard(
                                      walletBalance: wallet.balance,
                                      totalInvested: totalInvested,
                                      holdings: holdings,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Holdings (${holdings.length})',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                SegmentedButton<SortOption>(
                                  showSelectedIcon: false,
                                  style: ButtonStyle(
                                    visualDensity: VisualDensity.compact,
                                    padding: WidgetStateProperty.all(
                                      const EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                  ),
                                  segments: const [
                                    ButtonSegment(
                                      value: SortOption.byPnl,
                                      label: Text('P&L', style: TextStyle(fontSize: 11)),
                                    ),
                                    ButtonSegment(
                                      value: SortOption.bySymbol,
                                      label: Text('A-Z', style: TextStyle(fontSize: 11)),
                                    ),
                                    ButtonSegment(
                                      value: SortOption.byValue,
                                      label: Text('Value', style: TextStyle(fontSize: 11)),
                                    ),
                                  ],
                                  selected: {sortOption},
                                  onSelectionChanged: (sel) =>
                                      ref.read(sortOptionProvider.notifier).state = sel.first,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 10)),
                    if (holdings.isEmpty)
                      SliverFillRemaining(child: _EmptyPortfolio(cs: cs))
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverList.separated(
                          itemCount: sorted.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _HoldingRowTile(
                            holding: sorted[i],
                            onTrade: () => openTradeSheet(sorted[i].symbol),
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ),
      ),
    );
  }

  List<Holding> _sortedHoldings(List<Holding> holdings, SortOption sortOption, WidgetRef ref) {
    final sorted = List<Holding>.from(holdings);
    switch (sortOption) {
      case SortOption.bySymbol:
        sorted.sort((a, b) => a.symbol.compareTo(b.symbol));
        break;
      case SortOption.byValue:
        sorted.sort((a, b) {
          final aV = a.avgCost * Decimal.fromInt(a.quantity);
          final bV = b.avgCost * Decimal.fromInt(b.quantity);
          return bV.compareTo(aV);
        });
        break;
      case SortOption.byPnl:
        sorted.sort((a, b) {
          final aPrice = ref.watch(priceProvider(a.symbol)).valueOrNull?.ltp ?? a.avgCost;
          final bPrice = ref.watch(priceProvider(b.symbol)).valueOrNull?.ltp ?? b.avgCost;
          final aPnl = (aPrice * Decimal.fromInt(a.quantity)) - (a.avgCost * Decimal.fromInt(a.quantity));
          final bPnl = (bPrice * Decimal.fromInt(b.quantity)) - (b.avgCost * Decimal.fromInt(b.quantity));
          return bPnl.compareTo(aPnl);
        });
        break;
    }
    return sorted;
  }
}

class _SellAllButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _SellAllButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.lossBase.withValues(alpha: 0.12),
          border: Border.all(color: AppTheme.lossBase.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: loading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.lossBase,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sell_rounded, size: 15, color: AppTheme.lossBase),
                  const SizedBox(width: 5),
                  Text(
                    'Sell All',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.lossBase,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _EmptyPortfolio extends StatelessWidget {
  final ColorScheme cs;

  const _EmptyPortfolio({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.glassPanel(context, radius: 24),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 44,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your portfolio is empty',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Start by buying stocks from the Market tab.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Head to the Market tab to start trading!')),
                  );
                },
                icon: const Icon(Icons.trending_up_rounded, size: 18),
                label: const Text('Explore Market'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortfolioSummaryCard extends ConsumerWidget {
  final Decimal walletBalance;
  final Decimal totalInvested;
  final List<Holding> holdings;

  const _PortfolioSummaryCard({
    required this.walletBalance,
    required this.totalInvested,
    required this.holdings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Decimal currentHoldingsValue = Decimal.zero;
    for (final h in holdings) {
      final priceTick = ref.watch(priceProvider(h.symbol)).valueOrNull;
      final ltp = priceTick?.ltp ?? h.avgCost;
      currentHoldingsValue += ltp * Decimal.fromInt(h.quantity);
    }

    final totalPortfolioValue = walletBalance + currentHoldingsValue;
    final totalPnl = currentHoldingsValue - totalInvested;
    final totalReturn = totalPortfolioValue - Decimal.parse(kInitialWalletBalance);
    final totalReturnPercent = Decimal.parse(kInitialWalletBalance) > Decimal.zero
        ? (totalReturn * Decimal.fromInt(100) / Decimal.parse(kInitialWalletBalance))
            .toDecimal(scaleOnInfinitePrecision: 2)
        : Decimal.zero;
    final isPositiveReturn = totalReturn >= Decimal.zero;
    final isPositivePnl = totalPnl >= Decimal.zero;
    final pnlPercent = totalInvested > Decimal.zero
        ? (totalPnl * Decimal.fromInt(100) / totalInvested)
            .toDecimal(scaleOnInfinitePrecision: 2)
        : Decimal.zero;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryBlueMid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TOTAL PORTFOLIO VALUE',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '₹${totalPortfolioValue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isPositiveReturn
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppTheme.lossBase.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositiveReturn ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${isPositiveReturn ? '+' : ''}${totalReturnPercent.toStringAsFixed(2)}%',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Total return from initial balance',
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.18)),
            const SizedBox(height: 14),
            Row(
              children: [
                _StatCol(
                  label: 'Wallet Cash',
                  value: '₹${walletBalance.toStringAsFixed(2)}',
                  valueColor: Colors.white,
                ),
                const SizedBox(width: 24),
                _StatCol(
                  label: 'Invested',
                  value: '₹${totalInvested.toStringAsFixed(2)}',
                  valueColor: Colors.white,
                ),
                const Spacer(),
                _StatCol(
                  label: 'Total P&L',
                  value: '${isPositivePnl ? '+' : ''}₹${totalPnl.toStringAsFixed(2)}',
                  valueColor: isPositivePnl ? AppTheme.gainLight : AppTheme.lossLight,
                  align: CrossAxisAlignment.end,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final CrossAxisAlignment align;

  const _StatCol({
    required this.label,
    required this.value,
    required this.valueColor,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _HoldingRowTile extends ConsumerWidget {
  final Holding holding;
  final VoidCallback onTrade;

  const _HoldingRowTile({required this.holding, required this.onTrade});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceAsync = ref.watch(priceProvider(holding.symbol));
    final cs = Theme.of(context).colorScheme;
    final companyName = kStockCompanyNames[holding.symbol] ?? holding.symbol;

    return priceAsync.when(
      data: (tick) {
        final currentValue = tick.ltp * Decimal.fromInt(holding.quantity);
        final costBasis = holding.avgCost * Decimal.fromInt(holding.quantity);
        final pnl = currentValue - costBasis;
        final pnlPct = costBasis > Decimal.zero
            ? (pnl * Decimal.fromInt(100) / costBasis)
                .toDecimal(scaleOnInfinitePrecision: 2)
            : Decimal.zero;

        final isPos = pnl >= Decimal.zero;
        final gainC = AppTheme.gainColor(context);
        final lossC = AppTheme.lossColor(context);
        final pnlColor = isPos ? gainC : lossC;

        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant),
            boxShadow: AppTheme.panelShadow(context),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryBlueMid, AppTheme.primaryBlueTint],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        holding.symbol[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                holding.symbol,
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'NSE',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            companyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isPos ? '+' : ''}₹${pnl.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: pnlColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.pnlBg(context, isPos),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${isPos ? '+' : ''}${pnlPct.toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: pnlColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _MiniStat('Qty', '${holding.quantity}', cs),
                    _MiniStat('Avg', '₹${holding.avgCost.toStringAsFixed(2)}', cs),
                    _MiniStat('LTP', '₹${tick.ltp.toStringAsFixed(2)}', cs),
                    _MiniStat('Value', '₹${currentValue.toStringAsFixed(0)}', cs),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onTrade,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Buy More'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.gainBase,
                          side: BorderSide(color: AppTheme.gainBase.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onTrade,
                        icon: const Icon(Icons.sell_rounded, size: 16),
                        label: const Text('Sell'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.lossBase,
                          side: BorderSide(color: AppTheme.lossBase.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Text(holding.symbol, style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurface)),
            const Spacer(),
            const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Text('${holding.symbol}: Error loading price',
            style: TextStyle(color: cs.error, fontSize: 13)),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;

  const _MiniStat(this.label, this.value, this.cs);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 10,
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
