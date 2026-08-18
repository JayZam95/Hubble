import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubble/main.dart';
import 'package:hubble/features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/auth_provider_test.dart'; // import FakeAuthRepository

void main() {
  testWidgets('App initialization smoke test - redirects to LoginScreen', (WidgetTester tester) async {
    final fakeRepository = FakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepository),
        ],
        child: const MyApp(hasSeenOnboarding: true),
      ),
    );

    // Emit unauthenticated user state AFTER the stream listener is initialized
    fakeRepository.emitUser(null);

    // Tick microtasks and resolve stream changes
    await tester.pump(Duration.zero);
    await tester.pump();

    // Verify it renders the AuthGate redirecting to RoleSelectionScreen landing page
    expect(find.text('Welcome to Hubble'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });
}
