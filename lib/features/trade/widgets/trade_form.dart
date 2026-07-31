import 'package:flutter/material.dart';
import 'trade_bottom_sheet.dart';

class TradeForm extends StatelessWidget {
  final String symbol;

  const TradeForm({super.key, required this.symbol});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TradeBottomSheet(symbol: symbol),
      ),
    );
  }
}
