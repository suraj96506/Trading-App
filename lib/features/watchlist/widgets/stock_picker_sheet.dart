import 'package:flutter/material.dart';
import 'package:ticker_sim/core/constants/market_constants.dart';

class StockPickerSheet extends StatelessWidget {
  final List<String> selectedSymbols;
  final void Function(String symbol) onToggle;

  const StockPickerSheet({
    super.key,
    required this.selectedSymbols,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Stocks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: kStartingPrices.length,
                itemBuilder: (context, index) {
                  final symbol = kStartingPrices.keys.elementAt(index);
                  final isSelected = selectedSymbols.contains(symbol);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          isSelected ? Colors.blue : Colors.grey.shade200,
                      child: Text(symbol[0],
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black)),
                    ),
                    title: Text(symbol,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '₹${kStartingPrices[symbol]!.toStringAsFixed(2)}'),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.circle_outlined, color: Colors.grey),
                    onTap: () => onToggle(symbol),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
