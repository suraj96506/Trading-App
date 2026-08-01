import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import 'package:ticker_sim/core/providers/price_provider.dart';
import 'package:ticker_sim/core/models/price_tick.dart';
import '../../../core/constants/market_constants.dart';
import '../../../shared/theme/app_theme.dart';
import '../state/watchlist_row_state.dart';

class WatchlistRow extends ConsumerWidget {
  final String symbol;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  const WatchlistRow({super.key, required this.symbol, this.onRemove, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(watchlistRowProvider(symbol).notifier);
    final rowState = ref.watch(watchlistRowProvider(symbol));

    ref.listen<AsyncValue<PriceTick>>(priceProvider(symbol), (_, state) {
      final tick = state.valueOrNull;
      if (tick != null) notifier.onTick(tick);
    });

    final cs = Theme.of(context).colorScheme;
    return KeyedSubtree(
      key: ValueKey(symbol),
      child: ref.watch(priceProvider(symbol)).when(
        data: (tick) {
          final price = tick.ltp;
          final changePercent = tick.changePercent;
          final isPositive = changePercent >= Decimal.zero;

          final badgeBg = isPositive
              ? const Color(0xFF0F8E7A).withValues(alpha: 0.12)
              : const Color(0xFFE04F61).withValues(alpha: 0.12);
          final badgeTextColor = isPositive ? const Color(0xFF0F8E7A) : const Color(0xFFE04F61);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: rowState.flashColor != Colors.transparent ? rowState.flashColor : cs.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: cs.outlineVariant,
                width: 1,
              ),
              boxShadow: AppTheme.panelShadow(context),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryBlueMid, AppTheme.primaryBlueTint],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            symbol[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
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
                                Flexible(
                                  child: Text(
                                    symbol,
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: cs.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'NSE',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              kStockCompanyNames[symbol] ?? symbol,
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
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: badgeTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (onRemove != null) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          onPressed: onRemove,
                          splashRadius: 18,
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Icon(
                          Icons.drag_handle_rounded,
                          size: 20,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Text(symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
        ),
        error: (error, _) => Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Text('$symbol: Error loading price'),
        ),
      ),
    );
  }
}
