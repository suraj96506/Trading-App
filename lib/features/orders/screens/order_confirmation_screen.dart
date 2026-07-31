import 'package:flutter/material.dart';
import 'package:ticker_sim/core/models/order.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final Order order;

  const OrderConfirmationScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isBuy = order.side == 'buy';
    final sideColor = isBuy ? Colors.green : Colors.red;
    final sideLabel = isBuy ? 'BUY' : 'SELL';

    return Scaffold(
      appBar: AppBar(title: const Text('Order Confirmation')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isBuy ? Icons.check_circle : Icons.cancel,
                    size: 64,
                    color: sideColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${isBuy ? 'Bought' : 'Sold'} ${order.quantity.toStringAsFixed(0)} ${order.symbol}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  _detailRow('Side', sideLabel, sideColor),
                  _detailRow('Price', '₹${order.price.toStringAsFixed(2)}'),
                  _detailRow('Quantity', order.quantity.toStringAsFixed(0)),
                  _detailRow(
                      'Total',
                      '₹${(order.price * order.quantity).toStringAsFixed(2)}'),
                  const SizedBox(height: 24),
                  Text(
                    'Placed at ${_formatTime(order.timestamp)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, [Color? textColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}
