import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubble/features/chat/presentation/screens/new_chat_screen.dart';
import 'package:hubble/features/auth/presentation/providers/auth_provider.dart';
import 'package:hubble/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:hubble/features/marketplace/data/repositories/marketplace_repository.dart';
import 'package:hubble/features/auth/domain/models/user_model.dart';
import '../auth/presentation/auth_provider_test.dart';

class FakeMarketplaceRepository implements MarketplaceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  
  @override
  Future<List<UserModel>> searchProviders(String query) async {
    return [];
  }
}

void main() {
  late FakeAuthRepository fakeAuth;
  late FakeMarketplaceRepository fakeMarketplace;

  setUp(() {
    fakeAuth = FakeAuthRepository();
    fakeMarketplace = FakeMarketplaceRepository();
  });

  Widget createNewChatScreen() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuth),
        marketplaceRepositoryProvider.overrideWithValue(fakeMarketplace),
      ],
      child: const MaterialApp(
        home: NewChatScreen(),
      ),
    );
  }

  testWidgets('NewChatScreen renders search input', (WidgetTester tester) async {
    await tester.pumpWidget(createNewChatScreen());
    
    final user = createMockUserModel(
      uid: 'my_uid',
      email: 'user@hubble.com',
      displayName: 'Test User',
      role: UserRole.client,
    );
    fakeAuth.emitUser(user);
    
    await tester.pumpAndSettle();

    expect(find.text('New Chat'), findsWidgets);
    expect(find.byType(TextField), findsOneWidget);
  });
}
