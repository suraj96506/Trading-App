import 'dart:async';
import 'dart:ui';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/market_constants.dart';
import '../../../core/models/price_tick.dart';
import '../../../core/providers/price_provider.dart';
import '../../../shared/theme/app_theme.dart';

class PriceCell extends ConsumerStatefulWidget {
  final String symbol;
  final VoidCallback? onTap;

  const PriceCell({super.key, required this.symbol, this.onTap});

  @override
  ConsumerState<PriceCell> createState() => _PriceCellState();
}

class _PriceCellState extends ConsumerState<PriceCell> {
  final List<double> _history = [];
  Decimal? _previousLtp;
  bool _flashPositive = false;
  bool _flashNegative = false;
  Timer? _flashTimer;

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  void _onTick(PriceTick tick) {
    final value = double.tryParse(tick.ltp.toString()) ?? 0.0;
    if (_history.isEmpty || (_history.last - value).abs() > 0.001) {
      setState(() {
        _history.add(value);
        if (_history.length > 24) _history.removeAt(0);
      });
    }

    if (_previousLtp != null) {
      final cmp = tick.ltp.compareTo(_previousLtp!);
      if (cmp != 0) {
        setState(() {
          _flashPositive = cmp > 0;
          _flashNegative = cmp < 0;
        });
        _flashTimer?.cancel();
        _flashTimer = Timer(const Duration(milliseconds: 650), () {
          if (mounted) {
            setState(() {
              _flashPositive = false;
              _flashNegative = false;
            });
          }
        });
      }
    }
    _previousLtp = tick.ltp;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tickAsync = ref.watch(priceProvider(widget.symbol));

    ref.listen(priceProvider(widget.symbol), (_, next) {
      final tick = next.valueOrNull;
      if (tick != null) _onTick(tick);
    });

    return tickAsync.when(
      data: (tick) => _buildCard(context, cs, tick),
      loading: () => _buildSkeleton(context, cs),
      error: (_, __) => _buildError(context, cs),
    );
  }

  Widget _buildCard(BuildContext context, ColorScheme cs, PriceTick tick) {
    final price = tick.ltp;
    final change = tick.change;
    final changePct = tick.changePercent;
    final isUp = change.compareTo(Decimal.zero) >= 0;

    final gainC = AppTheme.gainColor(context);
    final lossC = AppTheme.lossColor(context);
    final gainBg = AppTheme.gainBg(context);
    final lossBg = AppTheme.lossBg(context);
    final flashBg = _flashPositive ? gainBg : _flashNegative ? lossBg : null;
    final companyName = kStockCompanyNames[widget.symbol] ?? widget.symbol;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: flashBg ?? cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: flashBg != null
              ? (isUp ? gainC : lossC).withValues(alpha: 0.3)
              : cs.outlineVariant,
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
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.symbol[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
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
                          isPositive: isUp,
                          text: '${isUp ? '+' : ''}${changePct.toStringAsFixed(2)}%',
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
                        child: CustomPaint(
                          painter: _SparkPainter(
                            data: _history,
                            color: isUp ? gainC : lossC,
                            isDark: context.isDark,
                          ),
                          size: Size.infinite,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            size: 12,
                            color: isUp ? gainC : lossC,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${isUp ? '+' : ''}${change.toStringAsFixed(2)} today',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isUp ? gainC : lossC,
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
    if (data.length < 2) {
      final y = size.height * 0.5;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = color.withValues(alpha: isDark ? 0.85 : 0.75)
          ..strokeWidth = 2
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
