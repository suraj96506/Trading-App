import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/price_provider.dart';
import '../../../core/models/price_tick.dart';
import 'package:decimal/decimal.dart';

class PriceCell extends ConsumerStatefulWidget {
  final String symbol;
  final VoidCallback? onTap;

  const PriceCell({super.key, required this.symbol, this.onTap});

  @override
  ConsumerState<PriceCell> createState() => _PriceCellState();
}

class _PriceCellState extends ConsumerState<PriceCell> {
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

    return tickAsync.when(
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
            onTap: widget.onTap,
          ),
        );
      },
      loading: () =>
          ListTile(title: Text(widget.symbol), subtitle: const Text('Loading...')),
      error: (error, _) =>
          ListTile(title: Text(widget.symbol), subtitle: Text('Error: $error')),
    );
  }
}
