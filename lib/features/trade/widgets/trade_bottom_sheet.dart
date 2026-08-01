import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import 'package:ticker_sim/core/models/order.dart';
import '../providers/trade_provider.dart';
import '../../../core/providers/price_provider.dart';
import '../../orders/screens/order_confirmation_screen.dart';
import '../../../core/constants/market_constants.dart';
import '../../../shared/theme/app_theme.dart';
import '../../trade/state/trade_sheet_notifier.dart';

class TradeBottomSheet extends ConsumerStatefulWidget {
  final String symbol;
  final ScrollController? scrollController;

  const TradeBottomSheet({super.key, required this.symbol, this.scrollController});

  @override
  ConsumerState<TradeBottomSheet> createState() => _TradeBottomSheetState();
}

class _TradeBottomSheetState extends ConsumerState<TradeBottomSheet>
    with SingleTickerProviderStateMixin {
  final _qtyCtrl = TextEditingController(text: '1');
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _qtyCtrl.addListener(() {
      ref.read(tradeSheetProvider(widget.symbol).notifier).clearError();
    });
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _onTick(Decimal ltp) {
    ref.read(tradeSheetProvider(widget.symbol).notifier).onTick(ltp);
  }

  int get _qty => int.tryParse(_qtyCtrl.text.trim()) ?? 0;

  void _execute(String side) {
    if (_qty <= 0) {
      ref.read(tradeSheetProvider(widget.symbol).notifier).setError('Enter a valid positive quantity');
      return;
    }
    final trade = ref.read(tradeExecutorProvider);
    final tick = ref.read(priceProvider(widget.symbol)).valueOrNull;
    if (tick == null) {
      ref.read(tradeSheetProvider(widget.symbol).notifier).setError('Price not available yet');
      return;
    }

    final (error, success) = side == 'buy'
        ? trade.buy(widget.symbol, _qty, tick.ltp)
        : trade.sell(widget.symbol, _qty, tick.ltp);

    if (!mounted) return;
    if (success) {
      final order = Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        symbol: widget.symbol,
        side: side,
        quantity: Decimal.fromInt(_qty),
        price: tick.ltp,
        timestamp: DateTime.now(),
      );
      Navigator.of(context).pop();
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => OrderConfirmationScreen(order: order)),
          );
        }
      });
    } else {
      ref.read(tradeSheetProvider(widget.symbol).notifier).setError(error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tickAsync = ref.watch(priceProvider(widget.symbol));
    final tick = tickAsync.valueOrNull;
    final ltp = tick?.ltp ?? Decimal.zero;
    final isPos = tick == null || tick.change >= Decimal.zero;
    final gainC = AppTheme.gainColor(context);
    final lossC = AppTheme.lossColor(context);
    final priceCl = isPos ? gainC : lossC;
    final total = ltp * Decimal.fromInt(_qty > 0 ? _qty : 0);
    final companyName = kStockCompanyNames[widget.symbol] ?? widget.symbol;

    final sheetState = ref.watch(tradeSheetProvider(widget.symbol));
    final history = sheetState.priceHistory;
    final _error = sheetState.error;

    ref.listen(priceProvider(widget.symbol), (_, state) {
      final nextTick = state.valueOrNull;
      if (nextTick != null) _onTick(nextTick.ltp);
    });

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 8),
            child: Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              children: [
                Container(
                  decoration: AppTheme.heroCard(context, radius: 28),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppTheme.primaryBlueMid, AppTheme.primaryBlueTint],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                widget.symbol[0],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.symbol,
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  companyName,
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (tick != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: Text(
                                  '₹${ltp.toStringAsFixed(2)}',
                                  key: ValueKey(ltp.toString()),
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: cs.onSurface,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.pnlBg(context, isPos),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isPos ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                      size: 12,
                                      color: priceCl,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${isPos ? '+' : ''}${tick.change.toStringAsFixed(2)} (${tick.changePercent.toStringAsFixed(2)}%)',
                                      style: TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: priceCl,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 110,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: context.isDark ? 0.45 : 0.55),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.8)),
                  ),
                  child: CustomPaint(
                    painter: _TradeChartPainter(
                      data: List<double>.from(history),
                      color: priceCl,
                      isDark: context.isDark,
                    ),
                    size: Size.infinite,
                  ),
                ),
                const SizedBox(height: 18),
                Divider(color: cs.outlineVariant, height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Quantity', style: Theme.of(context).textTheme.titleSmall),
                    Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _QtyBtn(
                            icon: Icons.remove_rounded,
                            onTap: () {
                              final cur = int.tryParse(_qtyCtrl.text) ?? 1;
                              if (cur > 1) _qtyCtrl.text = '${cur - 1}';
                            },
                          ),
                          SizedBox(
                            width: 58,
                            child: TextField(
                              controller: _qtyCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          _QtyBtn(
                            icon: Icons.add_rounded,
                            onTap: () {
                              final cur = int.tryParse(_qtyCtrl.text) ?? 0;
                              _qtyCtrl.text = '${cur + 1}';
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: context.isDark ? 0.35 : 0.55),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.8)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Order Value', style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        '₹${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.lossSurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.lossBase),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(fontSize: 12, color: AppTheme.lossBase),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _ActionBtn(
                        label: 'BUY',
                        color: AppTheme.gainBase,
                        onTap: () => _execute('buy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionBtn(
                        label: 'SELL',
                        color: AppTheme.lossBase,
                        onTap: () => _execute('sell'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.32),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _TradeChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final bool isDark;

  _TradeChartPainter({
    required this.data,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) {
      final y = size.height * 0.5;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = color.withValues(alpha: isDark ? 0.85 : 0.75)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
      return;
    }

    final minV = data.reduce((a, b) => a < b ? a : b);
    final maxV = data.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);
    final step = size.width / (data.length - 1);

    final pts = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i * step;
      final y = size.height - ((data[i] - minV) / range * (size.height * 0.9) + size.height * 0.05);
      pts.add(Offset(x, y));
    }

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final cp1 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i - 1].dy);
      final cp2 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i].dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i].dx, pts[i].dy);
    }

    canvas.drawPath(
      Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: isDark ? 0.35 : 0.2),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TradeChartPainter old) =>
      old.data.length != data.length || old.color != color;
}
