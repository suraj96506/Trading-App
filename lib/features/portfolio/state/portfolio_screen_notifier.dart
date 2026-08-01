import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticker_sim/core/models/holding.dart';
import 'package:ticker_sim/core/providers/price_provider.dart';
import 'package:ticker_sim/features/trade/providers/trade_provider.dart';
import 'package:ticker_sim/shared/theme/app_theme.dart';
import 'portfolio_screen_state.dart';

/// StateNotifier managing UI state for the Portfolio screen.
class PortfolioScreenNotifier extends StateNotifier<PortfolioScreenState> {
  final Ref _ref;

  PortfolioScreenNotifier(this._ref) : super(const PortfolioScreenState());

  Future<void> confirmSellAll(
    List<Holding> holdings,
    BuildContext context,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Sell All Holdings'),
        content: Text(
          'This will immediately sell all ${holdings.length} position(s) at '
          'current market prices. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.lossBase),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sell All'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    state = state.copyWith(sellAllLoading: true);

    final trade = _ref.read(tradeExecutorProvider);
    int count = 0;
    for (final h in holdings) {
      final tick = _ref.read(priceProvider(h.symbol)).valueOrNull;
      if (tick != null) {
        final (_, ok) = trade.sell(h.symbol, h.quantity, tick.ltp);
        if (ok) count++;
      }
    }

    state = state.copyWith(sellAllLoading: false);

    if (!context.mounted) return;
    HapticFeedback.mediumImpact();
    messenger.showSnackBar(
      SnackBar(content: Text('Sold $count holding(s) at market price')),
    );
  }
}

/// Provider — kept alive (portfolio is a persistent tab).
final portfolioScreenProvider =
    StateNotifierProvider<PortfolioScreenNotifier, PortfolioScreenState>(
  (ref) => PortfolioScreenNotifier(ref),
);
