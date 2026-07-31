import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticker_sim/core/constants/market_constants.dart';
import '../../trade/widgets/trade_bottom_sheet.dart';
import '../widgets/price_cell.dart';

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  void _showTrade(BuildContext context, String symbol) {
    showModalBottomSheet(
      context: context,
      builder: (_) => TradeBottomSheet(symbol: symbol),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symbols = kStartingPrices.keys.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Market')),
      body: ListView.builder(
        itemCount: symbols.length,
        itemBuilder: (context, index) {
          final symbol = symbols[index];
          return PriceCell(
            symbol: symbol,
            onTap: () => _showTrade(context, symbol),
          );
        },
      ),
    );
  }
}
