import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubble/core/presentation/screens/main_layout.dart';
import 'package:hubble/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:hubble/features/chat/presentation/providers/chat_provider.dart';
import 'package:hubble/features/bookings/presentation/providers/booking_provider.dart';
import 'package:hubble/features/auth/presentation/providers/auth_provider.dart';
import 'package:hubble/features/auth/domain/models/user_model.dart';
import '../../../features/auth/presentation/auth_provider_test.dart';

void main() {
  late FakeAuthRepository fakeRepository;

  setUp(() {
    fakeRepository = FakeAuthRepository();
  });

  Widget createMainLayout() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepository),
        liveCategoriesProvider.overrideWith((ref) => Future.value(['Tutoring'])),
        inboxStreamProvider.overrideWith((ref) => Stream.value([])),
        clientBookingsStreamProvider.overrideWith((ref) => Stream.value([])),
        providerBookingsStreamProvider.overrideWith((ref) => Stream.value([])),
      ],
      child: const MaterialApp(
        home: MainLayout(),
      ),
    );
  }

  testWidgets('MainLayout renders BottomNavigationBar and Explore screen initially', (WidgetTester tester) async {
    await tester.pumpWidget(createMainLayout());
    
    final user = createMockUserModel(
      uid: 'my_uid',
      email: 'user@hubble.com',
      displayName: 'My Name',
      role: UserRole.client,
    );
    fakeRepository.emitUser(user);

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Bookings'), findsOneWidget);
    expect(find.text('Inbox'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    
    expect(find.text('Explore Categories'), findsOneWidget);
  });
}
