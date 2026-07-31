import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/price_provider.dart';
import '../../../core/models/price_tick.dart';
import 'package:decimal/decimal.dart';
import '../../../shared/theme/app_theme.dart';

import '../../../core/constants/market_constants.dart';

class PriceCell extends ConsumerStatefulWidget {
  final String symbol;
  final VoidCallback? onTap;

  const PriceCell({super.key, required this.symbol, this.onTap});

  @override
  ConsumerState<PriceCell> createState() => _PriceCellState();
}

class _PriceCellState extends ConsumerState<PriceCell>
    with SingleTickerProviderStateMixin {
  Decimal? _previousLtp;
  bool _flashPositive = false;
  bool _flashNegative = false;
  Timer? _flashTimer;
  final List<double> _history = [];
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  void _onTick(PriceTick tick) {
    final ltpDouble = double.tryParse(tick.ltp.toString()) ?? 0.0;
    if (_history.isEmpty || (_history.last - ltpDouble).abs() > 0.001) {
      setState(() => _history.add(ltpDouble));
      if (_history.length > 20) _history.removeAt(0);
    }

    if (_previousLtp != null) {
      final cmp = tick.ltp.compareTo(_previousLtp!);
      if (cmp != 0) {
        setState(() {
          _flashPositive = cmp > 0;
          _flashNegative = cmp < 0;
        });
        _pulseCtrl.forward(from: 0);
        _flashTimer?.cancel();
        _flashTimer = Timer(const Duration(milliseconds: 700), () {
          if (mounted) setState(() { _flashPositive = false; _flashNegative = false; });
        });
      }
    }
    _previousLtp = tick.ltp;
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tickAsync = ref.watch(priceProvider(widget.symbol));
    final cs = Theme.of(context).colorScheme;

    ref.listen(priceProvider(widget.symbol), (_, state) {
      final tick = state.valueOrNull;
      if (tick != null) _onTick(tick);
    });

    return tickAsync.when(
      data: (tick) => _buildCard(context, cs, tick),
      loading: () => _buildSkeleton(context, cs),
      error: (e, _) => _buildError(context, cs),
    );
  }

  Widget _buildCard(BuildContext context, ColorScheme cs, PriceTick tick) {
    final price = tick.ltp;
    final change = tick.change;
    final changePct = tick.changePercent;
    final isPos = change >= Decimal.zero;

    final gainC  = AppTheme.gainColor(context);
    final lossC  = AppTheme.lossColor(context);
    final gainBg = AppTheme.gainBg(context);
    final lossBg = AppTheme.lossBg(context);

    Color? flashBg;
    if (_flashPositive) flashBg = gainBg;
    if (_flashNegative) flashBg = lossBg;

    final companyName = kStockCompanyNames[widget.symbol] ?? widget.symbol;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: flashBg ?? cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: flashBg != null
              ? (isPos ? gainC : lossC).withValues(alpha: 0.4)
              : cs.outlineVariant,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Symbol Avatar
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryBlueMid, AppTheme.primaryBlueTint],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.symbol.substring(0, 1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.symbol,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            companyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
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
                        Text(
                          '₹${price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 3),
                        _PillBadge(
                          isPositive: isPos,
                          text: '${isPos ? '+' : ''}${changePct.toStringAsFixed(2)}%',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Sparkline
                SizedBox(
                  height: 38,
                  child: _history.length >= 2
                      ? CustomPaint(
                          painter: _SparkPainter(
                            data: List.from(_history),
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isPos ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      size: 12,
                      color: isPos ? gainC : lossC,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${isPos ? '+' : ''}${change.toStringAsFixed(2)} today',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isPos ? gainC : lossC,
                      ),
                    ),
                  ],
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
      height: 120,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(9),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(height: 13, width: 80, color: cs.surfaceContainerHighest, margin: const EdgeInsets.only(bottom: 6)),
            Container(height: 10, width: 130, color: cs.outlineVariant),
          ],
        )),
        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
      ]),
    );
  }

  Widget _buildError(BuildContext context, ColorScheme cs) {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(children: [
        Icon(Icons.error_outline, size: 18, color: cs.error),
        const SizedBox(width: 8),
        Text('${widget.symbol}: unavailable', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
      ]),
    );
  }
}

/// Small colored pill badge
class _PillBadge extends StatelessWidget {
  final bool isPositive;
  final String text;

  const _PillBadge({required this.isPositive, required this.text});

  @override
  Widget build(BuildContext context) {
    final gainC  = AppTheme.gainColor(context);
    final lossC  = AppTheme.lossColor(context);
    final gainBg = AppTheme.gainBg(context);
    final lossBg = AppTheme.lossBg(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: isPositive ? gainBg : lossBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isPositive ? gainC : lossC,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Smooth sparkline painter with gradient fill
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
    final step  = size.width / (data.length - 1);

    final pts = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i * step;
      final y = size.height - ((data[i] - minV) / range * (size.height * 0.9) + size.height * 0.05);
      pts.add(Offset(x, y));
    }

    // Smooth path using cubic bezier
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final cp1 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i - 1].dy);
      final cp2 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i].dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i].dx, pts[i].dy);
    }

    // Draw gradient fill
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

    // Draw line
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
