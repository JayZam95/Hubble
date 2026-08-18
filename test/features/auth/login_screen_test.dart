import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubble/features/auth/presentation/providers/auth_provider.dart';
import 'package:hubble/features/auth/presentation/screens/login_screen.dart';
import 'presentation/auth_provider_test.dart';

void main() {
  late FakeAuthRepository fakeRepository;

  setUp(() {
    fakeRepository = FakeAuthRepository();
  });

  Widget createLoginScreen() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepository),
      ],
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('Renders HUBBLE title, text fields, forgot password, and log in button', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());
      fakeRepository.emitUser(null);
      await tester.pump();

      expect(find.text('HUBBLE'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Log In'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('Submitting empty form displays email and password validation errors', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());
      fakeRepository.emitUser(null);
      await tester.pump();

      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Log In'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Submitting invalid email and short password displays format errors', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());
      fakeRepository.emitUser(null);
      await tester.pump();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'invalidemail');
      await tester.enterText(textFields.at(1), '123');

      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Log In'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
      await tester.pump();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('Tapping forgot password with empty email shows error SnackBar', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());
      fakeRepository.emitUser(null);
      await tester.pump();

      await tester.tap(find.text('Forgot Password?'));
      await tester.pump();

      expect(find.text('Please enter your email address first.'), findsOneWidget);
    });

    testWidgets('Toggling password visibility changes obscureText state', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());
      fakeRepository.emitUser(null);
      await tester.pump();

      final passwordFormField = tester.widget<EditableText>(
        find.descendant(
          of: find.byType(TextFormField).at(1),
          matching: find.byType(EditableText),
        ),
      );
      expect(passwordFormField.obscureText, isTrue);

      // Tap visibility toggle icon
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      final updatedPasswordFormField = tester.widget<EditableText>(
        find.descendant(
          of: find.byType(TextFormField).at(1),
          matching: find.byType(EditableText),
        ),
      );
      expect(updatedPasswordFormField.obscureText, isFalse);
    });
  });
}
