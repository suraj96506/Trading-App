import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _rotateAnim;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    _scaleAnim = Tween<double>(begin: 0.86, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _rotateAnim = Tween<double>(begin: -0.05, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    _completeTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _completeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disableMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.pageGradient(context)),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -60,
              child: _Orb(color: AppTheme.primaryBlueMid.withValues(alpha: 0.18), size: 180),
            ),
            Positioned(
              bottom: -70,
              left: -50,
              child: _Orb(color: AppTheme.cyanGlow.withValues(alpha: 0.12), size: 150),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final fade = disableMotion ? 1.0 : _fadeAnim.value;
                  final scale = disableMotion ? 1.0 : _scaleAnim.value;
                  final rotate = disableMotion ? 0.0 : _rotateAnim.value;

                  return Opacity(
                    opacity: fade,
                    child: Transform.scale(
                      scale: scale,
                      child: Transform.rotate(
                        angle: rotate,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(32),
                                gradient: const LinearGradient(
                                  colors: [AppTheme.primaryBlueMid, AppTheme.primaryBlueTint],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryBlueMid.withValues(alpha: 0.35),
                                    blurRadius: 28,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.trending_up_rounded, size: 46, color: Colors.white),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              'TickerSim',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.1,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: cs.surface.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.8)),
                              ),
                              child: Text(
                                'Paper Trading Reimagined',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.35,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: 210,
                              child: LinearProgressIndicator(
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(999),
                                backgroundColor: cs.outlineVariant.withValues(alpha: 0.35),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Loading market session...',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Opacity(
                              opacity: 0,
                              child: Text('Market'),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _Orb extends StatelessWidget {
  final Color color;
  final double size;

  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
          stops: const [0.0, 1.0],
        ),
      ),
      child: Transform.rotate(
        angle: math.pi / 7,
        child: const SizedBox.shrink(),
      ),
    );
  }
}
