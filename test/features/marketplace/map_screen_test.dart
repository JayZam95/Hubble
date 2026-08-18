import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hubble/features/marketplace/presentation/screens/map_screen.dart';
import 'package:hubble/features/marketplace/presentation/providers/search_provider.dart';
import 'package:hubble/features/auth/domain/models/user_model.dart';
import 'package:hubble/features/auth/presentation/providers/auth_provider.dart';
import '../auth/presentation/auth_provider_test.dart';

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late UserModel mockCurrentUser;
  late UserModel mockProvider1;
  late UserModel mockProvider2;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
    mockCurrentUser = createMockUserModel(
      uid: 'user_curr',
      email: 'user@hubble.com',
      displayName: 'Current User',
      role: UserRole.client,
    );
    fakeAuthRepository.emitUser(mockCurrentUser);

    mockProvider1 = createMockUserModel(
      uid: 'provider_1',
      email: 'alice@hubble.com',
      displayName: 'Alice Plumber',
      role: UserRole.provider,
    ).copyWith(
      providerProfile: ProviderProfile(
        isActive: true,
        professionTitle: 'Master Plumber',
        category: 'Plumbing',
        hourlyRate: 150.0,
        currency: 'ZMW',
        bio: 'Experienced plumber',
        ratingAsProvider: 4.8,
        reviewCount: 10,
        totalJobsCompleted: 25,
        portfolioImages: [],
        businessType: 'individual',
        listingsCount: 2,
        isLocationShared: true,
      ),
    );

    mockProvider2 = createMockUserModel(
      uid: 'provider_2',
      email: 'bob@hubble.com',
      displayName: 'Bob Electrician',
      role: UserRole.provider,
    ).copyWith(
      providerProfile: ProviderProfile(
        isActive: true,
        professionTitle: 'Certified Electrician',
        category: 'Electrical',
        hourlyRate: 200.0,
        currency: 'ZMW',
        bio: 'Fast electrical repairs',
        ratingAsProvider: 4.9,
        reviewCount: 15,
        totalJobsCompleted: 40,
        portfolioImages: [],
        businessType: 'shop',
        listingsCount: 5,
        isLocationShared: true,
      ),
    );
  });

  tearDown(() {
    fakeAuthRepository.dispose();
  });

  Widget createMapScreen({List<UserModel>? providers}) {
    final list = providers ?? [mockProvider1, mockProvider2];
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        searchResultsProvider.overrideWith((ref) => Future.value(list)),
      ],
      child: const MaterialApp(
        home: MapScreen(),
      ),
    );
  }

  group('MapScreen Widget & Marker Tests', () {
    testWidgets('Renders MapScreen layout, FlutterMap, search bar, and provider markers count', (WidgetTester tester) async {
      await tester.pumpWidget(createMapScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Providers Near You'), findsOneWidget);
      expect(find.text('Search providers...'), findsOneWidget);
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(TileLayer), findsOneWidget);

      expect(find.text('2 Providers Nearby'), findsOneWidget);
    });

    testWidgets('Renders empty list when no providers are returned', (WidgetTester tester) async {
      await tester.pumpWidget(createMapScreen(providers: []));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('0 Providers Nearby'), findsOneWidget);
      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets('MapScreen renders search bar placeholder', (WidgetTester tester) async {
      await tester.pumpWidget(createMapScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Search providers...'), findsOneWidget);
    });
  });
}
