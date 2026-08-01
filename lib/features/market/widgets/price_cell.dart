import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import '../../../core/providers/price_provider.dart';
import '../../../core/models/price_tick.dart';
import 'price_cell_state.dart';
import '../../../core/constants/market_constants.dart';
import '../../../shared/theme/app_theme.dart';

class PriceCell extends ConsumerStatefulWidget {
  final String symbol;
  final VoidCallback? onTap;

  const PriceCell({super.key, required this.symbol, this.onTap});

  @override
  ConsumerState<PriceCell> createState() => _PriceCellState();
}

class _PriceCellState extends ConsumerState<PriceCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    // Listen to flash changes to trigger animation
    // Listening to price ticks and delegating to notifier
    ref.listen<AsyncValue<PriceTick>>(priceProvider(widget.symbol), (_, state) {
      final tick = state.valueOrNull;
      if (tick != null) {
        ref.read(priceCellProvider(widget.symbol).notifier).onTick(tick);
      }
    });

    // Listen for flash changes to trigger animation
    ref.listen<PriceCellState>(priceCellProvider(widget.symbol), (prev, next) {
      if (next.flashPositive || next.flashNegative) {
        _pulseCtrl.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cellState = ref.watch(priceCellProvider(widget.symbol));
    final tickAsync = ref.watch(priceProvider(widget.symbol));
    final tick = tickAsync.valueOrNull;
    if (tick == null) {
      return tickAsync.when(
        data: (_) => _buildSkeleton(context, cs),
        loading: () => _buildSkeleton(context, cs),
        error: (e, _) => _buildError(context, cs),
      );
    }
    return _buildCard(context, cs, tick, cellState);
  }

  Widget _buildCard(BuildContext context, ColorScheme cs, PriceTick tick, PriceCellState cellState) {
    final price = tick.ltp;
    final change = tick.change;
    final changePct = tick.changePercent;
    final isPos = change >= Decimal.zero;

    final gainC = AppTheme.gainColor(context);
    final lossC = AppTheme.lossColor(context);
    final gainBg = AppTheme.gainBg(context);
    final lossBg = AppTheme.lossBg(context);

    // Use provider state for flash backgrounds
    Color? flashBg;
    if (cellState.flashPositive) flashBg = gainBg;
    if (cellState.flashNegative) flashBg = lossBg;

    final companyName = kStockCompanyNames[widget.symbol] ?? widget.symbol;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: flashBg ?? cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: flashBg != null
              ? (isPos ? gainC : lossC).withValues(alpha: 0.3)
              : cs.outlineVariant,
          width: 1,
        ),
        boxShadow: AppTheme.panelShadow(context),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryBlueMid, AppTheme.primaryBlueTint],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlueMid.withValues(alpha: 0.26),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.symbol.substring(0, 1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.symbol,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            companyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11.5,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.15),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: Text(
                            '₹${price.toStringAsFixed(2)}',
                            key: ValueKey(price.toString()),
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _PillBadge(
                          isPositive: isPos,
                          text: '${isPos ? '+' : ''}${changePct.toStringAsFixed(2)}%',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: context.isDark ? 0.45 : 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 42,
                        child: cellState.history.length >= 2
                            ? CustomPaint(
                                painter: _SparkPainter(
                                  data: List.from(cellState.history),
                                  color: isPos ? gainC : lossC,
                                  isDark: context.isDark,
                                ),
                                size: Size.infinite,
                              )
                            : Center(
                                child: Container(
                                  height: 1,
                                  color: cs.outlineVariant,
                                ),
                              ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            isPos ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            size: 12,
                            color: isPos ? gainC : lossC,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${isPos ? '+' : ''}${change.toStringAsFixed(2)} today',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isPos ? gainC : lossC,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Tap for trade',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context, ColorScheme cs) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 13, width: 80, color: cs.surfaceContainerHighest, margin: const EdgeInsets.only(bottom: 6)),
                Container(height: 10, width: 130, color: cs.outlineVariant),
              ],
            ),
          ),
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, ColorScheme cs) {
    return Container(
      height: 70,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: cs.error),
          const SizedBox(width: 8),
          Text(
            '${widget.symbol}: unavailable',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  final bool isPositive;
  final String text;

  const _PillBadge({required this.isPositive, required this.text});

  @override
  Widget build(BuildContext context) {
    final gainC = AppTheme.gainColor(context);
    final lossC = AppTheme.lossColor(context);
    final gainBg = AppTheme.gainBg(context);
    final lossBg = AppTheme.lossBg(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPositive ? gainBg : lossBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isPositive ? gainC : lossC,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final bool isDark;

  _SparkPainter({required this.data, required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

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

    final fillPath = Path.from(path)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: isDark ? 0.3 : 0.18),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.data.length != data.length || old.color != color;
}
