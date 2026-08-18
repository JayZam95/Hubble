import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubble/features/auth/domain/models/user_model.dart';
import 'package:hubble/features/auth/presentation/providers/auth_provider.dart';
import 'package:hubble/features/marketplace/domain/models/listing_model.dart';
import 'package:hubble/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:hubble/features/profile/domain/models/review_model.dart';
import 'package:hubble/features/profile/presentation/providers/review_provider.dart';
import 'package:hubble/features/profile/presentation/screens/public_profile_screen.dart';
import 'package:hubble/features/profile/presentation/screens/retail_storefront_screen.dart';
import 'package:hubble/features/profile/presentation/screens/tutor_profile_screen.dart';
import 'package:hubble/features/profile/presentation/screens/handyman_profile_screen.dart';
import 'package:hubble/features/profile/presentation/screens/driver_profile_screen.dart';
import 'package:hubble/features/profile/presentation/screens/doctor_profile_screen.dart';
import 'package:hubble/features/profile/presentation/screens/service_portfolio_screen.dart';
import '../auth/presentation/auth_provider_test.dart';

void main() {
  UserModel createProviderUser({
    required String category,
    required String professionTitle,
    String businessType = 'individual',
  }) {
    final baseUser = createMockUserModel(
      uid: 'provider_123',
      email: 'provider@test.com',
      displayName: 'Jane Doe',
      role: UserRole.provider,
    );

    return baseUser.copyWith(
      providerProfile: ProviderProfile(
        isActive: true,
        professionTitle: professionTitle,
        category: category,
        hourlyRate: 150.0,
        currency: 'K',
        bio: 'Test provider bio',
        ratingAsProvider: 4.9,
        totalJobsCompleted: 50,
        portfolioImages: [],
        businessType: businessType,
        listingsCount: 2,
      ),
    );
  }

  Widget createTestWidget(UserModel user) {
    final fakeAuthRepo = FakeAuthRepository();
    fakeAuthRepo.emitUser(user);

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        reviewProvider(user.uid).overrideWith((ref) => Stream<List<ReviewModel>>.value([])),
        providerListingsProvider(user.uid).overrideWith((ref) async => <ListingModel>[]),
      ],
      child: MaterialApp(
        home: PublicProfileScreen(providerUser: user),
      ),
    );
  }

  group('PublicProfileScreen Polymorphic Routing Tests', () {
    testWidgets('routes to RetailStorefrontScreen for shop businessType', (tester) async {
      final user = createProviderUser(
        category: 'Electronics',
        professionTitle: 'Gadget Store',
        businessType: 'shop',
      );
      await tester.pumpWidget(createTestWidget(user));
      expect(find.byType(RetailStorefrontScreen), findsOneWidget);
    });

    testWidgets('routes to TutorProfileScreen for Education & Tutoring category', (tester) async {
      final user = createProviderUser(
        category: 'Education & Tutoring',
        professionTitle: 'High School Math Instructor',
      );
      await tester.pumpWidget(createTestWidget(user));
      expect(find.byType(TutorProfileScreen), findsOneWidget);
    });

    testWidgets('routes to HandymanProfileScreen for Plumbing & Home Repair', (tester) async {
      final user = createProviderUser(
        category: 'Plumbing & Home Repair',
        professionTitle: 'Certified Master Electrician',
      );
      await tester.pumpWidget(createTestWidget(user));
      expect(find.byType(HandymanProfileScreen), findsOneWidget);
    });

    testWidgets('routes to DriverProfileScreen for Transport & Delivery', (tester) async {
      final user = createProviderUser(
        category: 'Transport & Delivery',
        professionTitle: 'Cab & Airport Driver',
      );
      await tester.pumpWidget(createTestWidget(user));
      expect(find.byType(DriverProfileScreen), findsOneWidget);
    });

    testWidgets('routes to DoctorProfileScreen for Medical & Healthcare', (tester) async {
      final user = createProviderUser(
        category: 'Medical & Healthcare',
        professionTitle: 'Consultant Physician',
      );
      await tester.pumpWidget(createTestWidget(user));
      expect(find.byType(DoctorProfileScreen), findsOneWidget);
    });

    testWidgets('routes to ServicePortfolioScreen for Other Services', (tester) async {
      final user = createProviderUser(
        category: 'Events & Entertainment',
        professionTitle: 'Event Photographer',
      );
      await tester.pumpWidget(createTestWidget(user));
      expect(find.byType(ServicePortfolioScreen), findsOneWidget);
    });
  });
}
