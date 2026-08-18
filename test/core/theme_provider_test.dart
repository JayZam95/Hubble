import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hubble/core/theme/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeNotifier & themeProvider Unit Tests', () {
    test('Initial theme mode is ThemeMode.light for executive business theme', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeProvider), equals(ThemeMode.light));
    });

    test('ThemeNotifier always enforces ThemeMode.light', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeProvider.notifier);
      await notifier.setDarkMode(true);

      expect(container.read(themeProvider), equals(ThemeMode.light));
    });
  });
}
