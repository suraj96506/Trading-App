import 'package:flutter/material.dart';
import '../widgets/trade_form.dart';

class BuySellScreen extends StatelessWidget {
  final String symbol;
  const BuySellScreen({super.key, required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Trade $symbol')),
      body: TradeForm(symbol: symbol),
    );
  }
}
