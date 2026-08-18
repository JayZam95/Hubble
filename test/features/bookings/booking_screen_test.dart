import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubble/features/auth/domain/models/user_model.dart';
import 'package:hubble/features/auth/presentation/providers/auth_provider.dart';
import 'package:hubble/features/bookings/domain/models/booking_model.dart';
import 'package:hubble/features/bookings/data/repositories/booking_repository.dart';
import 'package:hubble/features/bookings/presentation/providers/booking_provider.dart';
import 'package:hubble/features/bookings/presentation/screens/booking_list_screen.dart';
import 'package:hubble/features/bookings/presentation/screens/booking_detail_screen.dart';

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

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {}
}

// Manual Stub Mock class to avoid mockito codegen dependencies
class FakeBookingRepository implements BookingRepository {
  final _clientStreamController = StreamController<List<BookingModel>>.broadcast();
  final _providerStreamController = StreamController<List<BookingModel>>.broadcast();

  final List<BookingStatus> updatedStatuses = [];
  final List<String> updatedBookingIds = [];
  final List<String> updatedUserIds = [];

  void emitClientBookings(List<BookingModel> list) {
    _clientStreamController.add(list);
  }

  void emitProviderBookings(List<BookingModel> list) {
    _providerStreamController.add(list);
  }

  @override
  Stream<List<BookingModel>> getBookingsStream({required String userId, required bool isClient}) {
    return isClient ? _clientStreamController.stream : _providerStreamController.stream;
  }

  @override
  Future<String> createBooking({
    required String clientId,
    required String clientName,
    required String providerId,
    required String providerName,
    required String serviceCategory,
    required double agreedPrice,
    required String jobDescription,
    required DateTime scheduledFor,
    String? listingId,
    String paymentMethod = 'escrow',
    String billingType = 'fixed',
    int quantity = 1,
  }) async { return 'fake_booking_id'; }

  @override
  Future<void> updateBookingStatus({
    required String bookingId,
    required String userId,
    required BookingStatus newStatus,
  }) async {
    updatedBookingIds.add(bookingId);
    updatedUserIds.add(userId);
    updatedStatuses.add(newStatus);
  }

  void dispose() {
    _clientStreamController.close();
    _providerStreamController.close();
  }
}

void main() {
  group('Booking List and Detail Screen Widget Tests', () {
    late FakeBookingRepository fakeRepository;
    late BookingModel pendingBooking;

    setUp(() {
      fakeRepository = FakeBookingRepository();

      pendingBooking = BookingModel(
        bookingId: 'booking_1',
        clientId: 'client_uid',
        providerId: 'provider_uid',
        clientName: 'Alice Buyer',
        providerName: 'Bob Builder',
        serviceCategory: 'Home Repair',
        status: BookingStatus.PENDING,
        jobDescription: 'Fix the leaky pipes.',
        financials: BookingFinancials(
          agreedPrice: 150.0,
          platformFee: 15.0,
          providerPayout: 135.0,
          isHeldInEscrow: true,
        ),
        timestamps: BookingTimestamps(
          requestedAt: DateTime.now(),
          scheduledFor: DateTime.now().add(const Duration(days: 1)),
        ),
      );
    });

    tearDown(() {
      fakeRepository.dispose();
    });

    testWidgets('Renders tabs and lists correct counterparty name for client purchases', (WidgetTester tester) async {
      final user = createMockUserModel(
        uid: 'client_uid',
        email: 'alice@hubble.com',
        displayName: 'Alice Buyer',
        role: UserRole.client,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingRepositoryProvider.overrideWithValue(fakeRepository),
            authStateProvider.overrideWith(() => FakeAuthNotifier(user)),
            clientBookingsStreamProvider.overrideWith((ref) => Stream.value([pendingBooking])),
            providerBookingsStreamProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: BookingListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Purchases'), findsOneWidget);
      expect(find.text('Sales'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);

      expect(find.text('Home Repair'), findsOneWidget);
      expect(find.text('Bob Builder'), findsOneWidget);
      expect(find.text('K 150.00'), findsOneWidget);
    });

    testWidgets('Renders secure checkout detail screen and cancels pending booking', (WidgetTester tester) async {
      final user = createMockUserModel(
        uid: 'client_uid',
        email: 'alice@hubble.com',
        displayName: 'Alice Buyer',
        role: UserRole.client,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingRepositoryProvider.overrideWithValue(fakeRepository),
            authStateProvider.overrideWith(() => FakeAuthNotifier(user)),
            clientBookingsStreamProvider.overrideWith((ref) => Stream.value([pendingBooking])),
            providerBookingsStreamProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            home: BookingDetailScreen(bookingId: pendingBooking.bookingId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Fix the leaky pipes.'), findsOneWidget);
      expect(find.text('K 150.00'), findsAtLeast(1));
      expect(find.text('K 15.00'), findsOneWidget);
      expect(find.text('K 135.00'), findsOneWidget);

      final cancelButton = find.byKey(const Key('booking_action_cancel'));
      expect(cancelButton, findsOneWidget);
      await tester.ensureVisible(cancelButton);
      await tester.pumpAndSettle();

      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      expect(fakeRepository.updatedBookingIds.first, pendingBooking.bookingId);
      expect(fakeRepository.updatedUserIds.first, 'client_uid');
      expect(fakeRepository.updatedStatuses.first, BookingStatus.CANCELLED);
    });
    testWidgets('Provider accepts active bookings', (WidgetTester tester) async {
      final user = createMockUserModel(
        uid: 'bob_uid',
        email: 'bob@hubble.com',
        displayName: 'Bob Builder',
        role: UserRole.provider,
      );

      final providerBooking = BookingModel(
        bookingId: pendingBooking.bookingId,
        clientId: 'client_uid',
        providerId: 'bob_uid',
        clientName: pendingBooking.clientName,
        providerName: pendingBooking.providerName,
        serviceCategory: pendingBooking.serviceCategory,
        status: pendingBooking.status,
        jobDescription: pendingBooking.jobDescription,
        financials: pendingBooking.financials,
        timestamps: pendingBooking.timestamps,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingRepositoryProvider.overrideWithValue(fakeRepository),
            authStateProvider.overrideWith(() => FakeAuthNotifier(user)),
            clientBookingsStreamProvider.overrideWith((ref) => Stream.value([providerBooking])),
            providerBookingsStreamProvider.overrideWith((ref) => Stream.value([providerBooking])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: BookingDetailScreen(bookingId: providerBooking.bookingId),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final acceptButton = find.byKey(const Key('booking_action_accept'));
      expect(acceptButton, findsOneWidget);
      await tester.ensureVisible(acceptButton);
      await tester.pumpAndSettle();

      await tester.tap(acceptButton);
      await tester.pumpAndSettle();

      expect(fakeRepository.updatedBookingIds.first, pendingBooking.bookingId);
      expect(fakeRepository.updatedUserIds.first, 'bob_uid');
      expect(fakeRepository.updatedStatuses.first, BookingStatus.ACCEPTED);
    });
  });
}
