import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubble/features/auth/presentation/providers/auth_provider.dart';
import 'package:hubble/features/auth/presentation/screens/login_screen.dart';
import 'auth_provider_test.dart'; // import FakeAuthRepository

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

  testWidgets('Renders Hubble title and onboarding text', (WidgetTester tester) async {
    await tester.pumpWidget(createLoginScreen());
    fakeRepository.emitUser(null); // Emit after listener starts
    await tester.pump(Duration.zero);
    await tester.pump();
    
    expect(find.text('HUBBLE'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('Submitting empty form shows validation errors', (WidgetTester tester) async {
    await tester.pumpWidget(createLoginScreen());
    fakeRepository.emitUser(null); // Emit after listener starts
    await tester.pump(Duration.zero);
    await tester.pump();
    
    // Ensure button is scrolled into view before tapping
    await tester.ensureVisible(find.byType(ElevatedButton));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });

  testWidgets('Submitting invalid email shows format error', (WidgetTester tester) async {
    await tester.pumpWidget(createLoginScreen());
    fakeRepository.emitUser(null); // Emit after listener starts
    await tester.pump(Duration.zero);
    await tester.pump();
    
    await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
    await tester.enterText(find.byType(TextFormField).last, 'pass');
    
    // Ensure button is scrolled into view before tapping
    await tester.ensureVisible(find.byType(ElevatedButton));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    
    expect(find.text('Please enter a valid email address'), findsOneWidget);
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
  });
}
