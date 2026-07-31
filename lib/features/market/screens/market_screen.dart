import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import 'package:ticker_sim/core/constants/market_constants.dart';
import '../../trade/widgets/trade_bottom_sheet.dart';
import '../widgets/price_cell.dart';
import '../../../shared/theme/app_theme.dart';

enum MarketSortOption { symbol, price, change }

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  String _searchQuery = '';
  MarketSortOption _sort = MarketSortOption.symbol;
  bool _ascending = true;

  void _openTradeSheet(String symbol) {
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
  Widget build(BuildContext context) {
    List<String> symbols = kStartingPrices.keys.toList();
    final cs = Theme.of(context).colorScheme;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      symbols = symbols.where((s) {
        return s.toLowerCase().contains(q) ||
            (kStockCompanyNames[s] ?? '').toLowerCase().contains(q);
      }).toList();
    }

    symbols.sort((a, b) {
      int res;
      switch (_sort) {
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
      return _ascending ? res : -res;
    });

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryBlueMid,
          onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Market Overview',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${symbols.length} securities',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      // Search
                      TextField(
                        onChanged: (v) => setState(() => _searchQuery = v.trim()),
                        decoration: const InputDecoration(
                          hintText: 'Search stocks, indices or ETFs...',
                          prefixIcon: Icon(Icons.search_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Sort chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _SortChip('Symbol', MarketSortOption.symbol, _sort, _ascending, _onSort),
                            const SizedBox(width: 8),
                            _SortChip('Price',  MarketSortOption.price,  _sort, _ascending, _onSort),
                            const SizedBox(width: 8),
                            _SortChip('% Change',MarketSortOption.change, _sort, _ascending, _onSort),
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
                    child: Text('No stocks found',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: symbols.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => PriceCell(
                      symbol: symbols[i],
                      onTap: () => _openTradeSheet(symbols[i]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSort(MarketSortOption opt) => setState(() {
    if (_sort == opt) {
      _ascending = !_ascending;
    } else {
      _sort = opt;
      _ascending = true;
    }
  });
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
    final cs  = Theme.of(context).colorScheme;
    final sel = current == option;
    return InkWell(
      onTap: () => onTap(option),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: sel
              ? AppTheme.primaryBlueMid.withValues(alpha: 0.14)
              : cs.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: sel ? AppTheme.primaryBlueMid.withValues(alpha: 0.6) : cs.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                color: sel ? AppTheme.primaryBlue : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              sel ? (ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded) : Icons.unfold_more_rounded,
              size: 13,
              color: sel ? AppTheme.primaryBlue : cs.outline,
            ),
          ],
        ),
      ),
    );
  }
}
