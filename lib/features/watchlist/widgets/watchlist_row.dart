import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import 'package:ticker_sim/core/providers/price_provider.dart';
import 'package:ticker_sim/core/models/price_tick.dart';

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
        _flashColor = Colors.green.withValues(alpha: 0.35);
      } else if (comparison < 0) {
        _flashColor = Colors.red.withValues(alpha: 0.35);
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

    ref.listen(priceProvider(widget.symbol), (_, state) {
      final tick = state.valueOrNull;
      if (tick != null) _onTick(tick);
    });

    return KeyedSubtree(
      key: ValueKey(widget.symbol),
      child: tickAsync.when(
        data: (tick) {
          final price = tick.ltp;
          final change = tick.change;
          final changePercent = tick.changePercent;

          Color changeColor = Colors.grey;
          if (change > Decimal.zero) {
            changeColor = Colors.green;
          } else if (change < Decimal.zero) {
            changeColor = Colors.red;
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            color: _flashColor,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(widget.symbol[0],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              title: Text(widget.symbol,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Row(
                children: [
                  Text('₹${price.toStringAsFixed(2)}'),
                  const SizedBox(width: 8),
                  Text(
                    '${change.toStringAsFixed(2)} (${changePercent.toStringAsFixed(2)}%)',
                    style: TextStyle(color: changeColor),
                  ),
                ],
              ),
              trailing: widget.onRemove != null
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: widget.onRemove,
                    )
                  : null,
              onTap: widget.onTap,
            ),
          );
        },
        loading: () => ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Text(widget.symbol[0],
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          title: Text(widget.symbol,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Loading...'),
          trailing: widget.onRemove != null
              ? IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: widget.onRemove,
                )
              : null,
        ),
        error: (error, _) => ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Text(widget.symbol[0],
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          title: Text(widget.symbol,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Error: $error'),
          trailing: widget.onRemove != null
              ? IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: widget.onRemove,
                )
              : null,
        ),
      ),
    );
  }
}
