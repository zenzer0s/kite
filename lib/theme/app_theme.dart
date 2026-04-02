import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── DARK ────────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF9AA8FF),
        onPrimary: Color(0xFF001D8B),
        primaryContainer: Color(0xFF6C63FF),
        secondary: Color(0xFFBF81FF),
        secondaryContainer: Color(0xFF7701D0),
        tertiary: Color(0xFF4ADE80),
        error: Color(0xFFFF6B6B),
        surface: Color(0xFF0A0B10),
        surfaceContainerLow: Color(0xFF0F111A),
        surfaceContainer: Color(0xFF151824),
        surfaceContainerHigh: Color(0xFF1A1D28),
        surfaceContainerHighest: Color(0xFF212630),
        onSurface: Color(0xFFE8EAF6),
        onSurfaceVariant: Color(0xFFA9ABB4),
        outline: Color(0xFF73757E),
        outlineVariant: Color(0xFF454850),
      ),
      scaffoldBackgroundColor: const Color(0xFF0A0B10),
    );
    return _applyTextAndComponents(base);
  }

  // ── LIGHT ───────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF4A41CC),
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFF5C52E8),
        secondary: Color(0xFF7C3AED),
        secondaryContainer: Color(0xFFEDE9FE),
        tertiary: Color(0xFF16A34A),
        error: Color(0xFFDC2626),
        surface: Color(0xFFF5F6FF),
        surfaceContainerLow: Color(0xFFFFFFFF),
        surfaceContainer: Color(0xFFEEEFF8),
        surfaceContainerHigh: Color(0xFFE4E5F0),
        surfaceContainerHighest: Color(0xFFD9DAE8),
        onSurface: Color(0xFF0F1023),
        onSurfaceVariant: Color(0xFF3B3D52),
        outline: Color(0xFF8B8DA0),
        outlineVariant: Color(0xFFCDCEDC),
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F6FF),
    );
    return _applyTextAndComponents(base);
  }

  // ── Shared styles ────────────────────────────────────────────────────────────
  static ThemeData _applyTextAndComponents(ThemeData base) {
    final isDark = base.brightness == Brightness.dark;

    return base.copyWith(
      textTheme: TextTheme(
        displayLarge: GoogleFonts.chakraPetch(
            fontSize: 56, fontWeight: FontWeight.bold, letterSpacing: -1.5),
        displayMedium: GoogleFonts.chakraPetch(
            fontSize: 45, fontWeight: FontWeight.bold, letterSpacing: -1),
        displaySmall: GoogleFonts.chakraPetch(
            fontSize: 36, fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.chakraPetch(
            fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.chakraPetch(
            fontSize: 28, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.chakraPetch(
            fontSize: 22, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.chakraPetch(
            fontSize: 16, fontWeight: FontWeight.normal, letterSpacing: 0.5),
        bodyMedium: GoogleFonts.chakraPetch(
            fontSize: 14, fontWeight: FontWeight.normal, letterSpacing: 0.25),
        labelLarge: GoogleFonts.chakraPetch(
            fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.25),
        labelMedium: GoogleFonts.chakraPetch(
            fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        labelSmall: GoogleFonts.chakraPetch(
            fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
      ),

      cardTheme: CardThemeData(
        color: base.colorScheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: base.colorScheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: base.colorScheme.primaryContainer, width: 1.5),
        ),
        hintStyle: TextStyle(color: base.colorScheme.outline),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: base.colorScheme.surfaceContainerHigh,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.chakraPetch(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: base.colorScheme.primary);
          }
          return GoogleFonts.chakraPetch(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: base.colorScheme.onSurfaceVariant);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: base.colorScheme.primary, size: 20);
          }
          return IconThemeData(color: base.colorScheme.onSurfaceVariant, size: 20);
        }),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: base.colorScheme.primary,
          foregroundColor: base.colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9999)),
          textStyle: GoogleFonts.chakraPetch(
              fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),

      // For the bottom nav bar blur container
      extensions: [
        ZenithColors(
          bg: isDark ? const Color(0xFF0A0B10) : const Color(0xFFF5F6FF),
          surface: isDark ? const Color(0xFF0F111A) : const Color(0xFFFFFFFF),
          surfaceAlt: isDark ? const Color(0xFF151824) : const Color(0xFFEEEFF8),
          accent: isDark ? const Color(0xFF6C63FF) : const Color(0xFF4A41CC),
          accentSoft: isDark ? const Color(0xFFC8C4FF) : const Color(0xFF5C52E8),
          textPrimary: isDark ? const Color(0xFFE8EAF6) : const Color(0xFF0F1023),
          textMuted: isDark
              ? const Color(0xFFE8EAF6).withValues(alpha: 0.45)
              : const Color(0xFF0F1023).withValues(alpha: 0.5),
          textDim: isDark
              ? const Color(0xFFE8EAF6).withValues(alpha: 0.25)
              : const Color(0xFF0F1023).withValues(alpha: 0.3),
          green: const Color(0xFF4ADE80),
          red: const Color(0xFFFF6B6B),
          border: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
          navBar: isDark
              ? const Color(0xFF131721).withValues(alpha: 0.88)
              : const Color(0xFFFFFFFF).withValues(alpha: 0.88),
        ),
      ],
    );
  }
}

// ── Custom theme extension ────────────────────────────────────────────────────
class ZenithColors extends ThemeExtension<ZenithColors> {
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color accent;
  final Color accentSoft;
  final Color textPrimary;
  final Color textMuted;
  final Color textDim;
  final Color green;
  final Color red;
  final Color border;
  final Color navBar;

  const ZenithColors({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.accent,
    required this.accentSoft,
    required this.textPrimary,
    required this.textMuted,
    required this.textDim,
    required this.green,
    required this.red,
    required this.border,
    required this.navBar,
  });

  @override
  ZenithColors copyWith({
    Color? bg, Color? surface, Color? surfaceAlt, Color? accent,
    Color? accentSoft, Color? textPrimary, Color? textMuted, Color? textDim,
    Color? green, Color? red, Color? border, Color? navBar,
  }) {
    return ZenithColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      textDim: textDim ?? this.textDim,
      green: green ?? this.green,
      red: red ?? this.red,
      border: border ?? this.border,
      navBar: navBar ?? this.navBar,
    );
  }

  @override
  ZenithColors lerp(ZenithColors? other, double t) {
    if (other == null) return this;
    return ZenithColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
      green: Color.lerp(green, other.green, t)!,
      red: Color.lerp(red, other.red, t)!,
      border: Color.lerp(border, other.border, t)!,
      navBar: Color.lerp(navBar, other.navBar, t)!,
    );
  }
}

/// Convenience accessor
extension ZenithColorsX on BuildContext {
  ZenithColors get zc =>
      Theme.of(this).extension<ZenithColors>()!;
}
