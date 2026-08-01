import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Precision Fiscal - Professional Fintech Design System
class AppTheme {
  static const primaryBlue = Color(0xFF0B3A67);
  static const primaryBlueMid = Color(0xFF175EA8);
  static const primaryBlueTint = Color(0xFF3D8BFF);
  static const cyanGlow = Color(0xFF52D6FF);

  static const gainDark = Color(0xFF0B6B5D);
  static const gainBase = Color(0xFF12A38A);
  static const gainLight = Color(0xFF3CD3B3);
  static const gainSurface = Color(0xFFE3FBF6);

  static const lossDark = Color(0xFF9C1C34);
  static const lossBase = Color(0xFFE04F61);
  static const lossLight = Color(0xFFFF7A88);
  static const lossSurface = Color(0xFFFFECEF);

  static const amber = Color(0xFFFFC857);

  static const _lBg = Color(0xFFF5F7FC);
  static const _lSurface = Color(0xFFFFFFFF);
  static const _lSurfaceVar = Color(0xFFF1F5FB);
  static const _lContHigh = Color(0xFFDCE5F2);
  static const _lOnSurface = Color(0xFF0D1728);
  static const _lOnSurfVar = Color(0xFF4A5875);
  static const _lOutline = Color(0xFF7183A6);
  static const _lOutlineVar = Color(0xFFD1D9E8);

  static const _dBg = Color(0xFF070B12);
  static const _dSurface = Color(0xFF0F1725);
  static const _dSurfaceVar = Color(0xFF162033);
  static const _dContHigh = Color(0xFF243453);
  static const _dOnSurface = Color(0xFFE7EEFF);
  static const _dOnSurfVar = Color(0xFF93A4C4);
  static const _dOutline = Color(0xFF4A5A7E);
  static const _dOutlineVar = Color(0xFF243453);

  static final ThemeData lightTheme = _build(Brightness.light);
  static final ThemeData darkTheme = _build(Brightness.dark);

  static ThemeData _build(Brightness br) {
    final isLight = br == Brightness.light;

    final bg = isLight ? _lBg : _dBg;
    final surface = isLight ? _lSurface : _dSurface;
    final surfVar = isLight ? _lSurfaceVar : _dSurfaceVar;
    final contHigh = isLight ? _lContHigh : _dContHigh;
    final onSurf = isLight ? _lOnSurface : _dOnSurface;
    final onSurfVar = isLight ? _lOnSurfVar : _dOnSurfVar;
    final outline = isLight ? _lOutline : _dOutline;
    final outlineV = isLight ? _lOutlineVar : _dOutlineVar;

    final base = isLight
        ? GoogleFonts.manropeTextTheme()
        : GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme);

    final cs = ColorScheme(
      brightness: br,
      primary: primaryBlue,
      onPrimary: Colors.white,
      primaryContainer: primaryBlueMid,
      onPrimaryContainer: const Color(0xFFD0DCFF),
      secondary: gainBase,
      onSecondary: Colors.white,
      secondaryContainer: gainSurface,
      onSecondaryContainer: gainDark,
      tertiary: amber,
      onTertiary: const Color(0xFF1A1000),
      tertiaryContainer: const Color(0xFFFFF3CD),
      onTertiaryContainer: const Color(0xFF4A3000),
      error: lossBase,
      onError: Colors.white,
      errorContainer: lossSurface,
      onErrorContainer: lossDark,
      surface: surface,
      onSurface: onSurf,
      onSurfaceVariant: onSurfVar,
      outline: outline,
      outlineVariant: outlineV,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isLight ? _dSurface : _lSurface,
      onInverseSurface: isLight ? _dOnSurface : _lOnSurface,
      inversePrimary: const Color(0xFFB0C6FF),
      surfaceTint: primaryBlueTint,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: br,
      colorScheme: cs,
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: primaryBlue),
        actionsIconTheme: IconThemeData(color: onSurfVar),
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent)
            : SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: primaryBlue,
        ),
      ),
      textTheme: base.copyWith(
        displayLarge: base.displayLarge?.copyWith(fontWeight: FontWeight.w800, color: onSurf),
        headlineLarge: base.headlineLarge?.copyWith(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.7,
          color: onSurf,
        ),
        headlineMedium: base.headlineMedium?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: onSurf,
        ),
        headlineSmall: base.headlineSmall?.copyWith(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: onSurf,
        ),
        titleLarge: base.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w700, color: onSurf),
        titleMedium: base.titleMedium?.copyWith(fontSize: 15.5, fontWeight: FontWeight.w700, color: onSurf),
        titleSmall: base.titleSmall?.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: onSurf),
        bodyLarge: base.bodyLarge?.copyWith(fontSize: 16, color: onSurf),
        bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, color: onSurfVar),
        bodySmall: base.bodySmall?.copyWith(fontSize: 12, color: onSurfVar),
        labelLarge: base.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: onSurf),
        labelMedium: base.labelMedium?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: onSurfVar,
        ),
        labelSmall: base.labelSmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: onSurfVar,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: outlineV, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfVar,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outlineV),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outlineV),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryBlueMid, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: lossBase),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: outline, fontSize: 14),
        prefixIconColor: outline,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlueMid,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryBlueMid,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: BorderSide(color: outlineV, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          textStyle: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: onSurfVar,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        height: 70,
        indicatorColor: primaryBlueMid.withValues(alpha: 0.14),
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final sel = s.contains(WidgetState.selected);
          return GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
            color: sel ? primaryBlue : onSurfVar,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((s) {
          final sel = s.contains(WidgetState.selected);
          return IconThemeData(color: sel ? primaryBlue : onSurfVar, size: 22);
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      dividerTheme: DividerThemeData(color: outlineV, thickness: 1, space: 1),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.selected)) return primaryBlueMid.withValues(alpha: 0.15);
            return surfVar;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.selected)) return primaryBlue;
            return onSurfVar;
          }),
          side: WidgetStateProperty.all(BorderSide(color: outlineV)),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          visualDensity: VisualDensity.compact,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isLight ? _dSurface : contHigh,
        contentTextStyle: GoogleFonts.manrope(fontSize: 14, color: isLight ? _dOnSurface : onSurf),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: onSurf),
        contentTextStyle: GoogleFonts.manrope(fontSize: 14, color: onSurfVar),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfVar,
        selectedColor: primaryBlueMid.withValues(alpha: 0.15),
        side: BorderSide(color: outlineV),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: onSurf),
        secondaryLabelStyle: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: primaryBlue),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryBlueMid,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        tileColor: surface,
        iconColor: onSurfVar,
        titleTextStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: onSurf),
        subtitleTextStyle: GoogleFonts.manrope(fontSize: 13, color: onSurfVar),
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }

  static LinearGradient pageGradient(BuildContext ctx) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: ctx.isDark
            ? const [Color(0xFF060A11), Color(0xFF0D1320), Color(0xFF111A2C)]
            : const [Color(0xFFF8FAFF), Color(0xFFF0F5FD), Color(0xFFEAF0FB)],
      );

  static List<BoxShadow> panelShadow(BuildContext ctx) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: ctx.isDark ? 0.35 : 0.06),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  static BoxDecoration glassPanel(BuildContext ctx, {double radius = 24}) {
    final cs = Theme.of(ctx).colorScheme;
    return BoxDecoration(
      color: cs.surface.withValues(alpha: ctx.isDark ? 0.78 : 0.88),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: cs.outlineVariant.withValues(alpha: ctx.isDark ? 0.35 : 0.9)),
      boxShadow: panelShadow(ctx),
    );
  }

  static BoxDecoration heroCard(BuildContext ctx, {double radius = 24}) {
    final cs = Theme.of(ctx).colorScheme;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: ctx.isDark
            ? [
                const Color(0xFF18253D),
                const Color(0xFF0F1725),
                cs.primary.withValues(alpha: 0.18),
              ]
            : [
                const Color(0xFFFFFFFF),
                const Color(0xFFF5F8FF),
                cs.primary.withValues(alpha: 0.08),
              ],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: cs.outlineVariant.withValues(alpha: ctx.isDark ? 0.28 : 0.9)),
      boxShadow: panelShadow(ctx),
    );
  }

  static Color gainColor(BuildContext ctx) => ctx.isDark ? gainLight : gainDark;
  static Color lossColor(BuildContext ctx) => ctx.isDark ? lossLight : lossBase;
  static Color gainBg(BuildContext ctx) => ctx.isDark ? gainBase.withValues(alpha: 0.18) : gainSurface;
  static Color lossBg(BuildContext ctx) => ctx.isDark ? lossBase.withValues(alpha: 0.18) : lossSurface;

  static Color pnlColor(BuildContext ctx, bool positive) => positive ? gainColor(ctx) : lossColor(ctx);
  static Color pnlBg(BuildContext ctx, bool positive) => positive ? gainBg(ctx) : lossBg(ctx);
}

extension BrightnessX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
