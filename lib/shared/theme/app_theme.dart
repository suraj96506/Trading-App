import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Precision Fiscal – Professional Fintech Design System
class AppTheme {
  // ── Brand Core ──────────────────────────────────────────────
  static const primaryBlue     = Color(0xFF003178);
  static const primaryBlueMid  = Color(0xFF0D47A1);
  static const primaryBlueTint = Color(0xFF1565C0);

  // ── Semantic: Gain (teal/green) ─────────────────────────────
  static const gainDark   = Color(0xFF00695C);
  static const gainBase   = Color(0xFF00897B);
  static const gainLight  = Color(0xFF00BFA5);
  static const gainSurface = Color(0xFFE0F2F1);

  // ── Semantic: Loss (red) ────────────────────────────────────
  static const lossDark   = Color(0xFFB71C1C);
  static const lossBase   = Color(0xFFBA1A1A);
  static const lossLight  = Color(0xFFEF5350);
  static const lossSurface = Color(0xFFFFEBEE);

  // ── Accent / Warning ────────────────────────────────────────
  static const amber = Color(0xFFFFC107);

  // ════════════════════════════════════════════════════════════
  //  LIGHT PALETTE
  // ════════════════════════════════════════════════════════════
  static const _lBg          = Color(0xFFF4F6FB);
  static const _lSurface     = Color(0xFFFFFFFF);
  static const _lSurfaceVar  = Color(0xFFF0F2F8);
  static const _lContainer   = Color(0xFFE8ECF6);
  static const _lContHigh    = Color(0xFFDDE3F3);
  static const _lOnSurface   = Color(0xFF0E1626);
  static const _lOnSurfVar   = Color(0xFF3D4A6B);
  static const _lOutline     = Color(0xFF6E7FA8);
  static const _lOutlineVar  = Color(0xFFCED5E8);

  // ════════════════════════════════════════════════════════════
  //  DARK PALETTE
  // ════════════════════════════════════════════════════════════
  static const _dBg          = Color(0xFF0A0D14);
  static const _dSurface     = Color(0xFF111827);
  static const _dSurfaceVar  = Color(0xFF1A2133);
  static const _dContainer   = Color(0xFF1E2840);
  static const _dContHigh    = Color(0xFF253050);
  static const _dOnSurface   = Color(0xFFE4EAF8);
  static const _dOnSurfVar   = Color(0xFF8A9CC4);
  static const _dOutline     = Color(0xFF4A5A82);
  static const _dOutlineVar  = Color(0xFF253050);

  // ════════════════════════════════════════════════════════════
  static final ThemeData lightTheme = _build(Brightness.light);
  static final ThemeData darkTheme  = _build(Brightness.dark);

  static ThemeData _build(Brightness br) {
    final isLight = br == Brightness.light;

    final bg        = isLight ? _lBg        : _dBg;
    final surface   = isLight ? _lSurface   : _dSurface;
    final surfVar   = isLight ? _lSurfaceVar: _dSurfaceVar;
    final container = isLight ? _lContainer : _dContainer;
    final contHigh  = isLight ? _lContHigh  : _dContHigh;
    final onSurf    = isLight ? _lOnSurface : _dOnSurface;
    final onSurfVar = isLight ? _lOnSurfVar : _dOnSurfVar;
    final outline   = isLight ? _lOutline   : _dOutline;
    final outlineV  = isLight ? _lOutlineVar: _dOutlineVar;

    final base = isLight
        ? GoogleFonts.interTextTheme()
        : GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    final cs = ColorScheme(
      brightness:           br,
      primary:              primaryBlue,
      onPrimary:            Colors.white,
      primaryContainer:     primaryBlueMid,
      onPrimaryContainer:   const Color(0xFFD0DCFF),
      secondary:            gainBase,
      onSecondary:          Colors.white,
      secondaryContainer:   gainSurface,
      onSecondaryContainer: gainDark,
      tertiary:             amber,
      onTertiary:           const Color(0xFF1A1000),
      tertiaryContainer:    const Color(0xFFFFF3CD),
      onTertiaryContainer:  const Color(0xFF4A3000),
      error:                lossBase,
      onError:              Colors.white,
      errorContainer:       lossSurface,
      onErrorContainer:     lossDark,
      surface:              surface,
      onSurface:            onSurf,
      onSurfaceVariant:     onSurfVar,
      outline:              outline,
      outlineVariant:       outlineV,
      shadow:               Colors.black,
      scrim:                Colors.black,
      inverseSurface:       isLight ? _dSurface : _lSurface,
      onInverseSurface:     isLight ? _dOnSurface : _lOnSurface,
      inversePrimary:       const Color(0xFFB0C6FF),
      surfaceTint:          primaryBlueTint,
    );

    return ThemeData(
      useMaterial3:           true,
      brightness:             br,
      colorScheme:            cs,
      scaffoldBackgroundColor: bg,

      // ── SystemUI ──────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:    surface,
        elevation:          0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor:   Colors.transparent,
        iconTheme:          IconThemeData(color: primaryBlue),
        actionsIconTheme:   IconThemeData(color: onSurfVar),
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent)
            : SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w700,
          color: primaryBlue,
        ),
      ),

      // ── Text ──────────────────────────────────────────────
      textTheme: base.copyWith(
        displayLarge:  base.displayLarge?.copyWith(fontWeight: FontWeight.w700, color: onSurf),
        headlineLarge: base.headlineLarge?.copyWith(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: onSurf),
        headlineMedium:base.headlineMedium?.copyWith(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: onSurf),
        headlineSmall: base.headlineSmall?.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: onSurf),
        titleLarge:    base.titleLarge?.copyWith(fontSize: 17, fontWeight: FontWeight.w600, color: onSurf),
        titleMedium:   base.titleMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: onSurf),
        titleSmall:    base.titleSmall?.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: onSurf),
        bodyLarge:     base.bodyLarge?.copyWith(fontSize: 16, color: onSurf),
        bodyMedium:    base.bodyMedium?.copyWith(fontSize: 14, color: onSurfVar),
        bodySmall:     base.bodySmall?.copyWith(fontSize: 12, color: onSurfVar),
        labelLarge:    base.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: onSurf),
        labelMedium:   base.labelMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.2, color: onSurfVar),
        labelSmall:    base.labelSmall?.copyWith(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: onSurfVar),
      ),

      // ── Cards ──────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation:    0,
        color:        surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: outlineV, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Inputs ─────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:      true,
        fillColor:   surfVar,
        border:      OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: outlineV)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: outlineV)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryBlueMid, width: 1.5)),
        errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: lossBase)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: TextStyle(color: outline, fontSize: 14),
        prefixIconColor: outline,
      ),

      // ── Buttons ────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlueMid,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryBlueMid,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: BorderSide(color: outlineV, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: onSurfVar,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // ── Navigation Bar ─────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:   surface,
        elevation:         0,
        height:            62,
        indicatorColor:    primaryBlueMid.withValues(alpha: 0.15),
        indicatorShape:    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final sel = s.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
            color: sel ? primaryBlue : onSurfVar,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((s) {
          final sel = s.contains(WidgetState.selected);
          return IconThemeData(color: sel ? primaryBlue : onSurfVar, size: 22);
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      // ── Divider ────────────────────────────────────────────
      dividerTheme: DividerThemeData(color: outlineV, thickness: 1, space: 1),

      // ── Segmented Button ───────────────────────────────────
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
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          textStyle: WidgetStateProperty.all(GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
          visualDensity: VisualDensity.compact,
        ),
      ),

      // ── SnackBar ───────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isLight ? _dSurface : contHigh,
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: isLight ? _dOnSurface : onSurf),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      // ── Dialog ────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: onSurf),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: onSurfVar),
      ),

      // ── BottomSheet ────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // ── Chip ──────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor:   surfVar,
        selectedColor:     primaryBlueMid.withValues(alpha: 0.15),
        side:              BorderSide(color: outlineV),
        shape:             RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle:        GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: onSurf),
        secondaryLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: primaryBlue),
        padding:           const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // ── FloatingActionButton ───────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryBlueMid,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      // ── ListTile ──────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        tileColor: surface,
        iconColor: onSurfVar,
        titleTextStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: onSurf),
        subtitleTextStyle: GoogleFonts.inter(fontSize: 13, color: onSurfVar),
      ),

      splashFactory: InkRipple.splashFactory,
    );
  }

  // ── Semantic helpers for widgets ──────────────────────────────
  static Color gainColor(BuildContext ctx) => ctx.isDark ? gainLight : gainDark;
  static Color lossColor(BuildContext ctx) => ctx.isDark ? lossLight : lossBase;
  static Color gainBg(BuildContext ctx)    => ctx.isDark
      ? gainBase.withValues(alpha: 0.18)
      : gainSurface;
  static Color lossBg(BuildContext ctx)    => ctx.isDark
      ? lossBase.withValues(alpha: 0.18)
      : lossSurface;

  static Color pnlColor(BuildContext ctx, bool positive) =>
      positive ? gainColor(ctx) : lossColor(ctx);
  static Color pnlBg(BuildContext ctx, bool positive) =>
      positive ? gainBg(ctx) : lossBg(ctx);
}

extension BrightnessX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
