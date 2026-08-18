import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubble/features/marketplace/presentation/screens/storefront_setup_screen.dart';
import 'package:hubble/features/auth/presentation/providers/auth_provider.dart';
import 'package:hubble/features/auth/domain/models/user_model.dart';
import '../auth/presentation/auth_provider_test.dart';

void main() {
  Widget createStorefrontSetupScreen(UserModel? mockUser) {
    final fakeRepository = FakeAuthRepository();
    fakeRepository.emitUser(mockUser);

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepository),
      ],
      child: const MaterialApp(
        home: StorefrontSetupScreen(),
      ),
    );
  }

  group('StorefrontSetupScreen Widget Tests', () {
    late UserModel activeUser;

    setUp(() {
      activeUser = createMockUserModel(
        uid: 'test_provider_123',
        email: 'provider@hubble.com',
        displayName: 'John Provider',
        role: UserRole.provider,
      );
    });

    testWidgets('Renders StorefrontSetupScreen wizard', (WidgetTester tester) async {
      await tester.pumpWidget(createStorefrontSetupScreen(activeUser));
      await tester.pumpAndSettle();

      expect(find.text('Choose your account type'), findsOneWidget);
      expect(find.text('How do you want to operate on Hubble?'), findsOneWidget);
      expect(find.text('Continue'), findsWidgets);
    });
  });
}

