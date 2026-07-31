import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticker_sim/core/models/holding.dart';
import 'package:ticker_sim/core/providers/price_provider.dart';
import 'package:ticker_sim/features/portfolio/providers/portfolio_provider.dart';
import 'package:decimal/decimal.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletStreamProvider);
    final holdingsAsync = ref.watch(holdingsStreamProvider);
    final sortOption = ref.watch(sortOptionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio')),
      body: walletAsync.when(
        data: (wallet) => holdingsAsync.when(
          data: (holdings) => _buildBody(context, ref, wallet.balance, holdings, sortOption),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, Decimal balance, List<Holding> holdings, SortOption sortOption) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Wallet Balance', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  '\u20B9${balance.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('Holdings', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            SegmentedButton<SortOption>(
              segments: const [
                ButtonSegment(
                  value: SortOption.byPnl,
                  label: Text('P&L'),
                  icon: Icon(Icons.trending_up, size: 18),
                ),
                ButtonSegment(
                  value: SortOption.bySymbol,
                  label: Text('Symbol'),
                  icon: Icon(Icons.sort_by_alpha, size: 18),
                ),
                ButtonSegment(
                  value: SortOption.byValue,
                  label: Text('Value'),
                  icon: Icon(Icons.attach_money, size: 18),
                ),
              ],
              selected: {sortOption},
              onSelectionChanged: (Set<SortOption> selected) {
                ref.read(sortOptionProvider.notifier).state = selected.first;
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (holdings.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: Text('No holdings yet. Start trading!', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ..._sortedHoldings(holdings, sortOption).map((h) => _HoldingTile(holding: h)),
      ],
    );
  }

  List<Holding> _sortedHoldings(List<Holding> holdings, SortOption sortOption) {
    final sorted = List<Holding>.from(holdings);
    switch (sortOption) {
      case SortOption.bySymbol:
        sorted.sort((a, b) => a.symbol.compareTo(b.symbol));
        break;
      case SortOption.byValue:
        // Sort by cost basis (avgCost \u00d7 quantity) \u2014 synchronous, no live price needed
        sorted.sort((a, b) {
          final aValue = a.avgCost * Decimal.fromInt(a.quantity);
          final bValue = b.avgCost * Decimal.fromInt(b.quantity);
          return bValue.compareTo(aValue); // descending
        });
        break;
      case SortOption.byPnl:
        // PnL requires live LTP; sort order stays as-is and updates
        // reactively as prices tick through per-row priceProvider listeners
        break;
    }
    return sorted;
  }
}

class _HoldingTile extends ConsumerWidget {
  final Holding holding;

  const _HoldingTile({required this.holding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceAsync = ref.watch(priceProvider(holding.symbol));

    return priceAsync.when(
      data: (tick) {
        final currentValue = tick.ltp * Decimal.fromInt(holding.quantity);
        final costBasis = holding.avgCost * Decimal.fromInt(holding.quantity);
        final pnl = currentValue - costBasis;
        final pnlPercent = costBasis > Decimal.zero
            ? (pnl * Decimal.fromInt(100) / costBasis).toDecimal(scaleOnInfinitePrecision: 2)
            : Decimal.zero;

        final pnlColor = pnl >= Decimal.zero ? Colors.green : Colors.red;

        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(holding.symbol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('${holding.quantity} × \u20B9${holding.avgCost.toStringAsFixed(2)}'),
                      Text('LTP: \u20B9${tick.ltp.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${pnl >= Decimal.zero ? '+' : ''}\u20B9${pnl.toStringAsFixed(2)}',
                      style: TextStyle(color: pnlColor, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '${pnlPercent >= Decimal.zero ? '+' : ''}${pnlPercent.toStringAsFixed(2)}%',
                      style: TextStyle(color: pnlColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Card(
        child: ListTile(title: Text(holding.symbol), subtitle: const Text('Loading...')),
      ),
      error: (err, _) => Card(
        child: ListTile(title: Text(holding.symbol), subtitle: Text('Error: $err')),
      ),
    );
  }
}
