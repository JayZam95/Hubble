import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubble/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:hubble/features/auth/presentation/providers/auth_provider.dart';
import 'package:hubble/features/auth/domain/models/user_model.dart';
import '../auth/presentation/auth_provider_test.dart';

void main() {
  late FakeAuthRepository fakeRepository;

  setUp(() {
    fakeRepository = FakeAuthRepository();
  });

  Widget createWalletScreen() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepository),
      ],
      child: const MaterialApp(
        home: WalletScreen(),
      ),
    );
  }

  testWidgets('WalletScreen renders balance cards', (WidgetTester tester) async {
    await tester.pumpWidget(createWalletScreen());
    
    final user = createMockUserModel(
      uid: 'my_uid',
      email: 'user@hubble.com',
      displayName: 'Test User',
      role: UserRole.client,
    );
    fakeRepository.emitUser(user);
    
    await tester.pumpAndSettle();

    expect(find.text('Available Balance'), findsOneWidget);
    expect(find.text('Vault (Escrow) Balance'), findsOneWidget);
  });
}
