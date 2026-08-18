import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Hubble Design System & Application Theme Engine.
/// Provides consistent typography, color tokens, fluid page transitions,
/// micro-interaction shadows, card themes, and glassmorphic decoration helpers.
class AppTheme {
  // ---------------------------------------------------------------------------
  // Page Transitions Theme
  // ---------------------------------------------------------------------------

  /// Fluid, platform-adapted page transitions across iOS, Android, and Desktop.
  static const PageTransitionsTheme _pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(
        allowEnterRouteSnapshotting: false,
      ),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: ZoomPageTransitionsBuilder(
        allowEnterRouteSnapshotting: false,
      ),
      TargetPlatform.linux: ZoomPageTransitionsBuilder(
        allowEnterRouteSnapshotting: false,
      ),
      TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(
        allowEnterRouteSnapshotting: false,
      ),
    },
  );

  // ---------------------------------------------------------------------------
  // Dark Theme
  // ---------------------------------------------------------------------------

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.bgDark,
      pageTransitionsTheme: _pageTransitionsTheme,
      
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.textDarkPrimary,
        primaryContainer: AppColors.primaryContainerDark,
        onPrimaryContainer: AppColors.primaryLight,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textDarkPrimary,
        secondaryContainer: AppColors.bgDarkElevated,
        onSecondaryContainer: AppColors.textDarkPrimary,
        tertiary: AppColors.accent,
        onTertiary: Colors.black,
        surface: AppColors.bgDarkCard,
        onSurface: AppColors.textDarkPrimary,
        surfaceContainerHighest: AppColors.bgDarkElevated,
        surfaceContainerLow: AppColors.bgDark,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.bgDarkBorder,
        outlineVariant: Color(0x1FFFFFFF),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        iconTheme: IconThemeData(color: AppColors.textDarkPrimary),
        actionsIconTheme: IconThemeData(color: AppColors.textDarkPrimary),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textDarkPrimary,
          letterSpacing: -0.3,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.bgDarkCard,
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgDarkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        prefixIconColor: AppColors.textDarkSecondary,
        suffixIconColor: AppColors.textDarkSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2.0,
          ),
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textDarkSecondary,
        ),
        labelStyle: AppTextStyles.label.copyWith(
          color: AppColors.textDarkSecondary,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.bgDarkElevated,
          disabledForegroundColor: AppColors.textDarkMuted,
          minimumSize: const Size(double.infinity, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.buttonText,
          elevation: 4,
          shadowColor: AppColors.primaryGlow,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.buttonText,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.buttonText,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.bgDarkElevated,
        refreshBackgroundColor: AppColors.bgDarkCard,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgDarkCard,
        selectedColor: AppColors.primary,
        secondarySelectedColor: AppColors.secondary,
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textDarkPrimary,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: AppTextStyles.bodySmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bgDarkCard,
        modalBackgroundColor: AppColors.bgDarkCard,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.textDarkMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bgDarkCard,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        titleTextStyle: AppTextStyles.heading2.copyWith(
          color: AppColors.textDarkPrimary,
        ),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textDarkSecondary,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.bgDarkBorder,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bgDarkElevated,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
      ),

      tabBarTheme: TabBarThemeData(
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textDarkSecondary,
        labelStyle: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTextStyles.label,
        dividerColor: Colors.transparent,
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.textDarkPrimary, fontWeight: FontWeight.w800),
        headlineLarge: TextStyle(color: AppColors.textDarkPrimary, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: AppColors.textDarkPrimary, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: AppColors.textDarkPrimary, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: AppColors.textDarkPrimary, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: AppColors.textDarkPrimary, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: AppColors.textDarkPrimary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: AppColors.textDarkPrimary),
        bodyMedium: TextStyle(color: AppColors.textDarkSecondary),
        bodySmall: TextStyle(color: AppColors.textDarkMuted),
        labelLarge: TextStyle(color: AppColors.textDarkPrimary, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(color: AppColors.textDarkSecondary),
        labelSmall: TextStyle(color: AppColors.textDarkMuted),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Light Theme
  // ---------------------------------------------------------------------------

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.bgLight,
      pageTransitionsTheme: _pageTransitionsTheme,

      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.bgLightElevated,
        onSecondaryContainer: AppColors.textLightPrimary,
        tertiary: AppColors.accent,
        onTertiary: Colors.white,
        surface: AppColors.bgLightCard,
        onSurface: AppColors.textLightPrimary,
        surfaceContainerHighest: AppColors.bgLightElevated,
        surfaceContainerLow: AppColors.bgLight,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.bgLightBorder,
        outlineVariant: Color(0x0F000000),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        iconTheme: IconThemeData(color: AppColors.textLightPrimary),
        actionsIconTheme: IconThemeData(color: AppColors.textLightPrimary),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textLightPrimary,
          letterSpacing: -0.3,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.bgLightCard,
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgLightElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        prefixIconColor: AppColors.textLightSecondary,
        suffixIconColor: AppColors.textLightSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.bgLightBorder,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2.0,
          ),
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textLightSecondary,
        ),
        labelStyle: AppTextStyles.label.copyWith(
          color: AppColors.textLightSecondary,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.bgLightElevated,
          disabledForegroundColor: AppColors.textLightMuted,
          minimumSize: const Size(double.infinity, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.buttonText,
          elevation: 2,
          shadowColor: AppColors.primaryGlow,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.buttonText,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.buttonText,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.bgLightElevated,
        refreshBackgroundColor: AppColors.bgLightCard,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgLightElevated,
        selectedColor: AppColors.primary,
        secondarySelectedColor: AppColors.secondary,
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textLightPrimary,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: AppTextStyles.bodySmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.bgLightBorder),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bgLightCard,
        modalBackgroundColor: AppColors.bgLightCard,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.textLightMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bgLightCard,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        titleTextStyle: AppTextStyles.heading2.copyWith(
          color: AppColors.textLightPrimary,
        ),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textLightSecondary,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.bgLightBorder,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textLightPrimary,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
      ),

      tabBarTheme: TabBarThemeData(
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textLightSecondary,
        labelStyle: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTextStyles.label,
        dividerColor: Colors.transparent,
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.textLightPrimary, fontWeight: FontWeight.w800),
        headlineLarge: TextStyle(color: AppColors.textLightPrimary, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: AppColors.textLightPrimary, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: AppColors.textLightPrimary, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: AppColors.textLightPrimary, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: AppColors.textLightPrimary, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: AppColors.textLightPrimary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: AppColors.textLightPrimary),
        bodyMedium: TextStyle(color: AppColors.textLightSecondary),
        bodySmall: TextStyle(color: AppColors.textLightMuted),
        labelLarge: TextStyle(color: AppColors.textLightPrimary, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(color: AppColors.textLightSecondary),
        labelSmall: TextStyle(color: AppColors.textLightMuted),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Custom Decoration Helpers
  // ---------------------------------------------------------------------------

  /// Glassmorphic container decoration helper
  static BoxDecoration glassDecoration({
    bool isDark = true,
    double borderRadius = 20.0,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ??
            (isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.4)),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// Card decoration with subtle glow options
  static BoxDecoration cardDecoration({
    bool isDark = true,
    double borderRadius = 20.0,
    Color? glowColor,
    BorderSide? border,
  }) {
    final effectiveBorder = border ??
        BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          width: 1.0,
        );

    return BoxDecoration(
      color: isDark ? AppColors.bgDarkCard : Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.fromBorderSide(effectiveBorder),
      boxShadow: [
        if (glowColor != null)
          BoxShadow(
            color: glowColor.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        else
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
      ],
    );
  }

  /// Subtle glowing decoration for active tabs, buttons, or badges
  static BoxDecoration glowDecoration({
    Color color = AppColors.primary,
    double borderRadius = 20.0,
    double opacity = 0.25,
    double blurRadius = 16.0,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: blurRadius,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static Gradient get primaryGradient => AppColors.primaryGradient;
  static Gradient get darkBackgroundGradient => AppColors.darkBackgroundGradient;
  static Gradient get lightBackgroundGradient => AppColors.lightBackgroundGradient;
}
