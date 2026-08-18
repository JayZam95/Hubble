import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubble/features/profile/presentation/screens/profile_screen.dart';
import 'package:hubble/features/auth/presentation/providers/auth_provider.dart';
import 'package:hubble/features/auth/domain/models/user_model.dart';
import '../auth/presentation/auth_provider_test.dart';

void main() {
  late FakeAuthRepository fakeRepository;

  setUp(() {
    fakeRepository = FakeAuthRepository();
  });

  Widget createProfileScreen() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepository),
      ],
      child: const MaterialApp(
        home: ProfileScreen(),
      ),
    );
  }

  testWidgets('ProfileScreen renders user details', (WidgetTester tester) async {
    await tester.pumpWidget(createProfileScreen());
    
    final user = createMockUserModel(
      uid: 'my_uid',
      email: 'user@hubble.com',
      displayName: 'Test User',
      role: UserRole.client,
    );
    fakeRepository.emitUser(user);
    
    await tester.pumpAndSettle();

    expect(find.text('Test User'), findsWidgets);
    expect(find.text('user@hubble.com'), findsOneWidget);
    expect(find.text('OVERVIEW'), findsWidgets); // Used in section title and tab bar
  });
}
