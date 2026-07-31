import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import 'package:ticker_sim/core/models/order.dart';
import '../providers/trade_provider.dart';
import '../../../core/providers/price_provider.dart';
import '../../orders/screens/order_confirmation_screen.dart';
import '../../../core/constants/market_constants.dart';
import '../../../shared/theme/app_theme.dart';

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
  String? _error;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _qtyCtrl.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  int get _qty => int.tryParse(_qtyCtrl.text.trim()) ?? 0;

  void _execute(String side) {
    if (_qty <= 0) { setState(() => _error = 'Enter a valid positive quantity'); return; }
    final trade = ref.read(tradeExecutorProvider);
    final tick  = ref.read(priceProvider(widget.symbol)).valueOrNull;
    if (tick == null) { setState(() => _error = 'Price not available yet'); return; }

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
        if (mounted) Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => OrderConfirmationScreen(order: order)),
        );
      });
    } else {
      setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs  = Theme.of(context).colorScheme;
    final tick = ref.watch(priceProvider(widget.symbol)).valueOrNull;
    final ltp  = tick?.ltp ?? Decimal.zero;
    final isPos = tick == null || tick.change >= Decimal.zero;
    final gainC = AppTheme.gainColor(context);
    final lossC = AppTheme.lossColor(context);
    final priceCl = isPos ? gainC : lossC;
    final total   = ltp * Decimal.fromInt(_qty > 0 ? _qty : 0);
    final companyName = kStockCompanyNames[widget.symbol] ?? widget.symbol;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag Handle ──
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Container(
              width: 44, height: 4.5,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: EdgeInsets.fromLTRB(
                20, 8, 20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              children: [
                // ── Header ─────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.primaryBlueMid, AppTheme.primaryBlueTint],
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: Text(widget.symbol[0],
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                        const SizedBox(width: 10),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(widget.symbol,
                            style: TextStyle(fontFamily: 'Inter', fontSize: 20,
                              fontWeight: FontWeight.w800, color: cs.onSurface)),
                          Text(companyName,
                            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: cs.onSurfaceVariant)),
                        ]),
                      ]),
                    ]),
                    if (tick != null)
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('₹${ltp.toStringAsFixed(2)}',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 20,
                            fontWeight: FontWeight.w700, color: cs.onSurface,
                            fontFeatures: const [FontFeature.tabularFigures()])),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.pnlBg(context, isPos),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(isPos ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                              size: 12, color: priceCl),
                            const SizedBox(width: 2),
                            Text(
                              '${isPos ? '+' : ''}${tick.change.toStringAsFixed(2)} (${tick.changePercent.toStringAsFixed(2)}%)',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 11,
                                fontWeight: FontWeight.w700, color: priceCl)),
                          ]),
                        ),
                      ]),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Price Chart ─────────────────────────────────
                Container(
                  height: 100,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: CustomPaint(
                    painter: _TradeChartPainter(color: priceCl, isDark: context.isDark),
                    size: Size.infinite,
                  ),
                ),

                const SizedBox(height: 18),
                Divider(color: cs.outlineVariant, height: 1),
                const SizedBox(height: 16),

                // ── Quantity Row ────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Quantity', style: Theme.of(context).textTheme.titleSmall),
                    Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        _QtyBtn(
                          icon: Icons.remove_rounded,
                          onTap: () {
                            final cur = int.tryParse(_qtyCtrl.text) ?? 1;
                            if (cur > 1) _qtyCtrl.text = '${cur - 1}';
                          },
                        ),
                        SizedBox(
                          width: 54,
                          child: TextField(
                            controller: _qtyCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: 'Inter', fontSize: 17,
                              fontWeight: FontWeight.w700, color: cs.onSurface),
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
                      ]),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Total ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order Value', style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      '₹${total.toStringAsFixed(2)}',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 18,
                        fontWeight: FontWeight.w700, color: cs.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ],
                ),

                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.lossSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.lossBase),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!,
                        style: TextStyle(fontSize: 12, color: AppTheme.lossBase))),
                    ]),
                  ),
                ],

                const SizedBox(height: 20),

                // ── Action Buttons ──────────────────────────────
                Row(children: [
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
                ]),
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
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
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
  final Color color;
  final bool isDark;

  _TradeChartPainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final pts = [
      Offset(0, size.height * 0.80),
      Offset(size.width * 0.12, size.height * 0.65),
      Offset(size.width * 0.25, size.height * 0.72),
      Offset(size.width * 0.38, size.height * 0.45),
      Offset(size.width * 0.52, size.height * 0.55),
      Offset(size.width * 0.65, size.height * 0.28),
      Offset(size.width * 0.78, size.height * 0.38),
      Offset(size.width * 0.88, size.height * 0.18),
      Offset(size.width,        size.height * 0.10),
    ];

    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
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
          colors: [color.withValues(alpha: isDark ? 0.35 : 0.2), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(path, Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
