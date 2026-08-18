import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubble/features/auth/domain/models/user_model.dart';
import 'package:hubble/features/auth/presentation/providers/auth_provider.dart';
import 'package:hubble/features/marketplace/domain/models/listing_model.dart';
import 'package:hubble/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:hubble/features/settings/presentation/screens/manage_listings_screen.dart';

// Helper to create mock UserModel
UserModel createMockUserModel({
  required String uid,
  required String email,
  required String displayName,
  required UserRole role,
}) {
  return UserModel(
    uid: uid,
    email: email,
    displayName: displayName,
    role: role,
    createdAt: DateTime.now(),
    personalInfo: PersonalInfo(
      firstName: displayName.split(' ').first,
      lastName: displayName.split(' ').last,
      phoneNumber: '+260971234567',
      email: email,
      isVerified: true,
      profileImageURL: '',
    ),
    currentLocation: CurrentLocation(latitude: 0.0, longitude: 0.0, geohash: ''),
    clientProfile: ClientProfile(ratingAsClient: 0.0, totalBookingsMade: 0),
    providerProfile: ProviderProfile(
      isActive: role == UserRole.provider,
      professionTitle: 'Tailor',
      category: 'Clothing',
      hourlyRate: 120.0,
      currency: 'ZMW',
      bio: 'Fashion designer expert',
      ratingAsProvider: 4.9,
      totalJobsCompleted: 8,
      portfolioImages: [],
      businessType: 'shop',
      listingsCount: 1,
    ),
    financialLedger: FinancialLedger(
      currency: 'ZMW',
      availableBalance: 0.0,
      vaultSettings: VaultSettings(isAutoSaveEnabled: false, autoSavePercentage: 0.0, vaultBalance: 0.0),
      investmentPortfolio: InvestmentPortfolio(isActive: false, brokeragePartnerId: null, totalEstimatedValue: 0.0, assets: []),
    ),
  );
}

class FakeAuthNotifier extends AuthNotifier {
  final UserModel _user;
  FakeAuthNotifier(this._user);

  @override
  AuthState build() {
    return AuthState(user: _user, isLoading: false);
  }
}

void main() {
  group('ManageListingsScreen Widget Tests', () {
    late UserModel mockShopUser;
    late ListingModel mockListing;

    setUp(() {
      mockShopUser = createMockUserModel(
        uid: 'shop_123',
        email: 'store@hubble.com',
        displayName: 'Mega Electronics',
        role: UserRole.provider,
      );

      mockListing = ListingModel(
        id: 'list_99',
        providerId: 'shop_123',
        providerName: 'Mega Electronics',
        providerImage: '',
        title: 'Custom Gaming PC',
        description: 'Super fast custom core i9 computer.',
        price: 18500.0,
        listingType: ListingType.product,
        billingType: BillingType.perItem,
        category: 'Hardware',
        images: [],
        stockCount: 5,
        createdAt: DateTime.now(),
      );
    });

    testWidgets('Renders empty catalog layout when listings are empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(() => FakeAuthNotifier(mockShopUser)),
            providerListingsProvider('shop_123').overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(
            home: ManageListingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Storefront Catalog Manager'), findsOneWidget);
      expect(find.text('No catalog items match this filter.'), findsOneWidget);
      expect(find.textContaining('create new products'), findsOneWidget);
    });

    testWidgets('Renders catalog items and stock labels correctly for active listings', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(() => FakeAuthNotifier(mockShopUser)),
            providerListingsProvider('shop_123').overrideWith((ref) => Future.value([mockListing])),
          ],
          child: const MaterialApp(
            home: ManageListingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Custom Gaming PC'), findsOneWidget);
      expect(find.text('Hardware · Item'), findsOneWidget);
      expect(find.text('Stock: 5 left'), findsOneWidget);
      expect(find.text('K 18500'), findsOneWidget);
    });
  });
}
