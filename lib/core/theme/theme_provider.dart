import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod notifier managing application theme mode (enforces executive Light theme default).
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ThemeMode.light;
  }

  Future<void> setDarkMode(bool isDark) async {
    state = ThemeMode.light;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    state = ThemeMode.light;
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
