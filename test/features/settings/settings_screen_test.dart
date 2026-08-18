import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubble/features/auth/domain/models/user_model.dart';
import 'package:hubble/features/auth/presentation/providers/auth_provider.dart';
import 'package:hubble/features/settings/presentation/screens/settings_screen.dart';

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
      isVerified: false,
      profileImageURL: '',
    ),
    currentLocation: CurrentLocation(latitude: 0.0, longitude: 0.0, geohash: ''),
    clientProfile: ClientProfile(ratingAsClient: 0.0, totalBookingsMade: 0),
    providerProfile: ProviderProfile(
      isActive: role == UserRole.provider,
      professionTitle: '',
      category: '',
      hourlyRate: 0.0,
      currency: 'ZMW',
      bio: '',
      ratingAsProvider: 0.0,
      totalJobsCompleted: 0,
      portfolioImages: [],
      businessType: 'individual',
      listingsCount: 0,
    ),
    financialLedger: FinancialLedger(
      currency: 'ZMW',
      availableBalance: 0.0,
      vaultSettings: VaultSettings(isAutoSaveEnabled: true, autoSavePercentage: 0.25, vaultBalance: 0.0),
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

  @override
  Future<void> signOut() async {
    state = AuthState(user: null, isLoading: false);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isPasswordResetSent: true);
  }
}

void main() {
  group('SettingsScreen Widget Tests', () {
    testWidgets('Renders profiles summary, role switches, and vault configurations', (WidgetTester tester) async {
      final user = createMockUserModel(
        uid: 'client_uid',
        email: 'alice@hubble.com',
        displayName: 'Alice Buyer',
        role: UserRole.client,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(() => FakeAuthNotifier(user)),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify profile info
      expect(find.text('Alice Buyer'), findsWidgets);
      expect(find.text('alice@hubble.com'), findsOneWidget);

      // Verify toggles
      expect(find.text('MARKETPLACE LISTING MODE'), findsOneWidget);
      expect(find.text('Client Mode Active'), findsOneWidget);

      // Scroll and verify Financial Vault configurations
      final vaultFinder = find.text('SAVINGS VAULT ALLOCATION');
      await tester.dragUntilVisible(
        vaultFinder,
        find.byType(ListView),
        const Offset(0, -500),
      );
      
      expect(vaultFinder, findsOneWidget);
      expect(find.text('Vault Auto-Save'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);

      // Verify security items
      final changePasswordFinder = find.text('Change Password');
      await tester.dragUntilVisible(
        changePasswordFinder,
        find.byType(ListView),
        const Offset(0, -500),
      );
      
      expect(changePasswordFinder, findsOneWidget);
      expect(find.text('Sign Out Session'), findsOneWidget);
    });

    testWidgets('Renders settings screen safely under edge-case user states without any crashes', (WidgetTester tester) async {
      // Create user with verified profile, active provider mode, autoSave disabled, and out of bounds percentage
      final edgeCaseUser = UserModel(
        uid: 'provider_uid',
        email: 'bob@hubble.com',
        displayName: 'Bob Builder',
        role: UserRole.provider,
        createdAt: DateTime.now(),
        personalInfo: PersonalInfo(
          firstName: 'Bob',
          lastName: 'Builder',
          phoneNumber: '+260971234567',
          email: 'bob@hubble.com',
          isVerified: true,
          profileImageURL: 'https://invalid-image-placeholder-url.com/bob.jpg',
        ),
        currentLocation: CurrentLocation(latitude: -15.3, longitude: 28.3, geohash: 'khgabc'),
        clientProfile: ClientProfile(ratingAsClient: 0.0, totalBookingsMade: 0),
        providerProfile: ProviderProfile(
          isActive: true,
          professionTitle: 'Carpenter',
          category: 'Home Cleaning',
          hourlyRate: 150.0,
          currency: 'ZMW',
          bio: 'Specialist carpenter',
          ratingAsProvider: 4.8,
          totalJobsCompleted: 15,
          portfolioImages: ['https://invalid-portfolio.jpg'],
          businessType: 'individual',
          listingsCount: 0,
        ),
        financialLedger: FinancialLedger(
          currency: 'ZMW',
          availableBalance: 2500.0,
          vaultSettings: VaultSettings(
            isAutoSaveEnabled: true,
            autoSavePercentage: 120.0, // whole percentage > 100, extremely out-of-bounds
            vaultBalance: 500.0,
          ),
          investmentPortfolio: InvestmentPortfolio(isActive: false, totalEstimatedValue: 0.0, assets: []),
        ),
        kycStatus: 'verified',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(() => FakeAuthNotifier(edgeCaseUser)),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 1));

      // Verify that it renders successfully
      expect(find.text('Bob Builder'), findsWidgets);
      
      final storefrontFinder = find.text('Hiring Storefront Active');
      await tester.dragUntilVisible(storefrontFinder, find.byType(ListView), const Offset(0, -500));
      expect(storefrontFinder, findsOneWidget);
      
      final verificationFinder = find.text('Verification Complete');
      await tester.dragUntilVisible(verificationFinder, find.byType(ListView), const Offset(0, -500));
      expect(verificationFinder, findsOneWidget);
      
      final hundredPercentFinder = find.text('100%');
      await tester.dragUntilVisible(hundredPercentFinder, find.byType(ListView), const Offset(0, -500));
      expect(hundredPercentFinder, findsOneWidget); // Clamped at 100%
      
      final storefrontPresFinder = find.text('Storefront Presentation');
      await tester.dragUntilVisible(storefrontPresFinder, find.byType(ListView), const Offset(0, -500));
      expect(storefrontPresFinder, findsOneWidget);
    });
  });
}
