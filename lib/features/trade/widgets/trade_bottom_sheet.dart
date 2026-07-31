import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import 'package:ticker_sim/core/models/order.dart';
import '../providers/trade_provider.dart';
import '../../../core/providers/price_provider.dart';
import '../../orders/screens/order_confirmation_screen.dart';

class TradeBottomSheet extends ConsumerStatefulWidget {
  final String symbol;

  const TradeBottomSheet({super.key, required this.symbol});

  @override
  ConsumerState<TradeBottomSheet> createState() => _TradeBottomSheetState();
}

class _TradeBottomSheetState extends ConsumerState<TradeBottomSheet> {
  final _qtyCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _execute(String side) {
    final qtyText = _qtyCtrl.text.trim();
    if (qtyText.isEmpty) {
      setState(() => _error = 'Enter quantity');
      return;
    }
    final qty = int.tryParse(qtyText);
    if (qty == null || qty <= 0) {
      setState(() => _error = 'Enter a valid positive integer');
      return;
    }

    final trade = ref.read(tradeExecutorProvider);
    final tick = ref.read(priceProvider(widget.symbol)).valueOrNull;
    if (tick == null) {
      setState(() => _error = 'Price not available');
      return;
    }

    final (error, success) = side == 'buy'
        ? trade.buy(widget.symbol, qty, tick.ltp)
        : trade.sell(widget.symbol, qty, tick.ltp);

    if (!mounted) return;

    if (success) {
      final order = Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        symbol: widget.symbol,
        side: side,
        quantity: Decimal.fromInt(qty),
        price: tick.ltp,
        timestamp: DateTime.now(),
      );
      Navigator.of(context).pop();
      // Small delay to let the bottom sheet close before navigating
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OrderConfirmationScreen(order: order),
            ),
          );
        }
      });
    } else {
      setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final tickAsync = ref.watch(priceProvider(widget.symbol));
    final tick = tickAsync.valueOrNull;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Trade ${widget.symbol}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          if (tick != null)
            Text(
              'Price: \u20B9${tick.ltp.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _qtyCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantity',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 8),
          if (tick != null)
            Text(
              'Total: \u20B9${(Decimal.fromInt(int.tryParse(_qtyCtrl.text.trim()) ?? 0) * tick.ltp).toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _execute('buy'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Buy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => _execute('sell'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Sell'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
