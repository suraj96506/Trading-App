import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import 'package:ticker_sim/core/providers/price_provider.dart';
import 'package:ticker_sim/core/models/price_tick.dart';
import '../../../core/constants/market_constants.dart';

class WatchlistRow extends ConsumerStatefulWidget {
  final String symbol;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  const WatchlistRow({super.key, required this.symbol, this.onRemove, this.onTap});

  @override
  ConsumerState<WatchlistRow> createState() => _WatchlistRowState();
}

class _WatchlistRowState extends ConsumerState<WatchlistRow> {
  Decimal? _previousLtp;
  Color _flashColor = Colors.transparent;
  Timer? _flashTimer;

  void _onTick(PriceTick tick) {
    if (_previousLtp != null) {
      final comparison = tick.ltp.compareTo(_previousLtp!);
      if (comparison > 0) {
        _flashColor = const Color(0xFF006B5C).withValues(alpha: 0.15);
      } else if (comparison < 0) {
        _flashColor = const Color(0xFFBA1A1A).withValues(alpha: 0.15);
      } else {
        _flashColor = Colors.transparent;
      }
      _flashTimer?.cancel();
      _flashTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _flashColor = Colors.transparent);
      });
    }
    _previousLtp = tick.ltp;
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tickAsync = ref.watch(priceProvider(widget.symbol));
    final companyName = kStockCompanyNames[widget.symbol] ?? widget.symbol;

    ref.listen(priceProvider(widget.symbol), (_, state) {
      final tick = state.valueOrNull;
      if (tick != null) _onTick(tick);
    });

    return KeyedSubtree(
      key: ValueKey(widget.symbol),
      child: tickAsync.when(
        data: (tick) {
          final price = tick.ltp;
          final changePercent = tick.changePercent;
          final isPositive = changePercent >= Decimal.zero;

          final badgeBg = isPositive
              ? const Color(0xFF006B5C).withValues(alpha: 0.12)
              : const Color(0xFFBA1A1A).withValues(alpha: 0.12);
          final badgeTextColor = isPositive ? const Color(0xFF006B5C) : const Color(0xFFBA1A1A);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: _flashColor != Colors.transparent
                  ? _flashColor
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Symbol & Subtitle
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.symbol,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            companyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // LTP Price
                    Expanded(
                      flex: 3,
                      child: Text(
                        '₹${price.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Change % Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                    if (widget.onRemove != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 18,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        onPressed: widget.onRemove,
                        splashRadius: 18,
                      ),
                    ],
                    // Drag Handle Icon
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.drag_handle,
                        size: 20,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(widget.symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
        ),
        error: (error, _) => Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(16),
          child: Text('${widget.symbol}: Error loading price'),
        ),
      ),
    );
  }
}
