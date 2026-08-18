import 'package:flutter/material.dart';

/// App-wide design system color tokens for Hubble.
/// Unified across light & dark themes, glassmorphism, glowing micro-interactions,
/// semantic badges, and card surfaces.
class AppColors {
  // Brand Colors (Emerald & Slate Palette)
  static const Color primary = Color(0xFF10B981); // Emerald 500 (Signature Green)
  static const Color primaryLight = Color(0xFF34D399); // Emerald 400
  static const Color primaryDark = Color(0xFF047857); // Emerald 700
  static const Color primaryContainer = Color(0xFFD1FAE5); // Emerald 100
  static const Color primaryContainerDark = Color(0xFF064E3B); // Emerald 900
  static const Color secondary = Color(0xFF047857); // Emerald 700
  static const Color secondaryLight = Color(0xFF059669); // Emerald 600
  static const Color accent = Color(0xFFF59E0B); // Amber 500 (Gold/Money Accent)
  static const Color accentLight = Color(0xFFFBBF24); // Amber 400
  static const Color accentDark = Color(0xFFD97706); // Amber 600

  // Glowing Accent Colors for micro-interactions
  static const Color primaryGlow = Color(0x3310B981); // Emerald Glow 20%
  static const Color primaryGlowStrong = Color(0x6610B981); // Emerald Glow 40%
  static const Color accentGlow = Color(0x33F59E0B); // Amber Glow 20%
  static const Color secondaryGlow = Color(0x33047857); // Dark Green Glow 20%
  static const Color errorGlow = Color(0x33EF4444); // Red Glow 20%

  // Dark Theme Colors (Deep Midnight Slate)
  static const Color bgDark = Color(0xFF0F172A); // Slate 900 (Main dark background)
  static const Color bgDarkDeep = Color(0xFF020617); // Slate 950 (Deepest dark)
  static const Color bgDarkCard = Color(0xFF1E293B); // Slate 800 (Card surface)
  static const Color bgDarkElevated = Color(0xFF334155); // Slate 700 (Elevated items / dialogs)
  static const Color bgDarkBorder = Color(0xFF334155); // Slate 700 border
  static const Color textDarkPrimary = Color(0xFFF8FAFC); // Slate 50 (High-emphasis text)
  static const Color textDarkSecondary = Color(0xFF94A3B8); // Slate 400 (Medium-emphasis text)
  static const Color textDarkMuted = Color(0xFF64748B); // Slate 500 (Low-emphasis text / disabled)

  // Light Theme Colors (Crisp Modern Slate)
  static const Color bgLight = Color(0xFFF8FAFC); // Slate 50 (Main light background)
  static const Color bgLightCard = Color(0xFFFFFFFF); // Pure White (Card surface)
  static const Color bgLightElevated = Color(0xFFF1F5F9); // Slate 100 (Subtle elevated surfaces)
  static const Color bgLightBorder = Color(0xFFE2E8F0); // Slate 200 (Clean light border)
  static const Color textLightPrimary = Color(0xFF0F172A); // Slate 900 (High-emphasis text)
  static const Color textLightSecondary = Color(0xFF64748B); // Slate 500 (Medium-emphasis text)
  static const Color textLightMuted = Color(0xFF94A3B8); // Slate 400 (Low-emphasis text / disabled)

  // Common Semantic Colors
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successLight = Color(0xFFD1FAE5); // Emerald 100
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorLight = Color(0xFFFEE2E2); // Red 100
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningLight = Color(0xFFFEF3C7); // Amber 100
  static const Color info = Color(0xFF3B82F6); // Blue 500
  static const Color infoLight = Color(0xFFDBEAFE); // Blue 100

  // Glassmorphic Gradients
  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient primaryVerticalGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Gradient accentGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const Gradient darkBackgroundGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF020617)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Gradient lightBackgroundGradient = LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFEDF2F7)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Gradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF162032)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient lightCardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient glassBorderDark = LinearGradient(
    colors: [Color(0x33FFFFFF), Color(0x05FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient glassBorderLight = LinearGradient(
    colors: [Color(0xCCFFFFFF), Color(0x40FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient emeraldShimmerGradient = LinearGradient(
    colors: [
      Color(0x0010B981),
      Color(0x3310B981),
      Color(0x0010B981),
    ],
    stops: [0.1, 0.5, 0.9],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );

  // Convenience aliases used across transport, bookings, and marketplace screens
  static const Color backgroundDark = bgDark;
  static const Color backgroundLight = bgLight;
  static const Color surfaceDark = bgDarkCard;
  static const Color surfaceLight = bgLightCard;

  // Shadow Helper Utilities
  static List<BoxShadow> glowShadow({
    Color color = primary,
    double opacity = 0.25,
    double blurRadius = 16,
    Offset offset = const Offset(0, 4),
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blurRadius,
        offset: offset,
      ),
    ];
  }

  static List<BoxShadow> cardShadow({bool isDark = true}) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ];
  }

  static List<BoxShadow> elevatedShadow({bool isDark = true}) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
        blurRadius: 24,
        spreadRadius: 2,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static List<BoxShadow> subtleShadow({bool isDark = true}) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }
}
