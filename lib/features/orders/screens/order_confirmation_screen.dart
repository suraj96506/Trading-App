import 'package:flutter/material.dart';
import 'package:ticker_sim/core/models/order.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final Order order;

  const OrderConfirmationScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isBuy = order.side == 'buy';
    final sideColor = isBuy ? const Color(0xFF006B5C) : const Color(0xFFBA1A1A);
    final sideLabel = isBuy ? 'BUY' : 'SELL';

    return Scaffold(
      appBar: AppBar(title: const Text('Order Confirmation')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: sideColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isBuy ? Icons.check_circle_outline : Icons.swap_horiz,
                    size: 48,
                    color: sideColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Order Executed Successfully',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${isBuy ? 'Bought' : 'Sold'} ${order.quantity.toStringAsFixed(0)} ${order.symbol}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                _detailRow(context, 'Side', sideLabel, textColor: sideColor),
                _detailRow(context, 'Symbol', order.symbol),
                _detailRow(context, 'Execution Price', '₹${order.price.toStringAsFixed(2)}'),
                _detailRow(context, 'Quantity', order.quantity.toStringAsFixed(0)),
                _detailRow(
                  context,
                  'Total Value',
                  '₹${(order.price * order.quantity).toStringAsFixed(2)}',
                  isBold: true,
                ),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'Placed at ${_formatTime(order.timestamp)}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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

  Widget _detailRow(BuildContext context, String label, String value,
      {Color? textColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: textColor ?? Theme.of(context).colorScheme.onSurface,
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
