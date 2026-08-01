import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import 'package:ticker_sim/core/constants/market_constants.dart';
import 'package:ticker_sim/features/market/state/market_screen_notifier.dart';
import 'package:ticker_sim/features/market/state/market_screen_state.dart';
import '../../trade/widgets/trade_bottom_sheet.dart';
import '../widgets/price_cell.dart';
import '../../../shared/theme/app_theme.dart';

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  void _openTradeSheet(BuildContext context, String symbol) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenState = ref.watch(marketScreenProvider);
    final notifier = ref.read(marketScreenProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    List<String> symbols = kStartingPrices.keys.toList();

    if (screenState.searchQuery.isNotEmpty) {
      final q = screenState.searchQuery.toLowerCase();
      symbols = symbols.where((s) {
        return s.toLowerCase().contains(q) ||
            (kStockCompanyNames[s] ?? '').toLowerCase().contains(q);
      }).toList();
    }

    symbols.sort((a, b) {
      int res;
      switch (screenState.sort) {
        case MarketSortOption.symbol:
          res = a.compareTo(b);
          break;
        case MarketSortOption.price:
          res = (kStartingPrices[a] ?? Decimal.zero)
              .compareTo(kStartingPrices[b] ?? Decimal.zero);
          break;
        case MarketSortOption.change:
          res = a.compareTo(b);
          break;
      }
      return screenState.ascending ? res : -res;
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.pageGradient(context)),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppTheme.primaryBlueMid,
            onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                                      child: const Icon(Icons.show_chart_rounded, color: Colors.white),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Market',
                                            style: TextStyle(
                                              fontFamily: 'Manrope',
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.8,
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text('Market Overview',
                                              style: Theme.of(context).textTheme.headlineMedium),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${symbols.length} securities in motion',
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _MetricPill(label: 'Live feed', value: 'Single source'),
                                    _MetricPill(label: 'Sort', value: screenState.sort.name.toUpperCase()),
                                    _MetricPill(label: 'Theme', value: context.isDark ? 'DARK' : 'LIGHT'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          onChanged: notifier.setSearchQuery,
                          decoration: const InputDecoration(
                            hintText: 'Search stocks, indices or ETFs...',
                            prefixIcon: Icon(Icons.search_rounded, size: 20),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _SortChip('Symbol', MarketSortOption.symbol, screenState.sort, screenState.ascending, notifier.setSort),
                              const SizedBox(width: 8),
                              _SortChip('Price', MarketSortOption.price, screenState.sort, screenState.ascending, notifier.setSort),
                              const SizedBox(width: 8),
                              _SortChip('% Change', MarketSortOption.change, screenState.sort, screenState.ascending, notifier.setSort),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                if (symbols.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(22),
                              decoration: AppTheme.glassPanel(context, radius: 24),
                              child: Icon(Icons.search_off_rounded,
                                  size: 48, color: cs.onSurfaceVariant),
                            ),
                            const SizedBox(height: 18),
                            Text('No stocks found',
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 6),
                            Text(
                              'Try a different symbol or company name.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: symbols.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => RepaintBoundary(
                        child: PriceCell(
                          symbol: symbols[i],
                          onTap: () => _openTradeSheet(context, symbols[i]),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final MarketSortOption option;
  final MarketSortOption current;
  final bool ascending;
  final ValueChanged<MarketSortOption> onTap;

  const _SortChip(this.label, this.option, this.current, this.ascending, this.onTap);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sel = current == option;
    return InkWell(
      onTap: () => onTap(option),
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: sel
              ? const LinearGradient(
                  colors: [AppTheme.primaryBlueMid, AppTheme.primaryBlueTint],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: sel ? null : cs.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: sel ? Colors.transparent : cs.outlineVariant,
          ),
          boxShadow: sel
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlueMid.withValues(alpha: 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                color: sel ? Colors.white : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              sel ? (ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded) : Icons.unfold_more_rounded,
              size: 13,
              color: sel ? Colors.white : cs.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetricPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: context.isDark ? 0.65 : 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.8)),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(text: '$label\n'),
            TextSpan(
              text: value,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
