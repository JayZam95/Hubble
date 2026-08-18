import 'package:flutter_test/flutter_test.dart';
import 'package:hubble/features/bookings/domain/models/booking_model.dart';

void main() {
  late BookingModel oldBooking;
  late BookingModel recentBooking;
  late BookingModel latestBooking;
  late BookingModel completedBooking;
  late BookingModel cancelledBooking;

  setUp(() {
    final now = DateTime.now();

    oldBooking = BookingModel(
      bookingId: 'b_old',
      clientId: 'client_1',
      providerId: 'provider_1',
      clientName: 'Alice Mwansa',
      providerName: 'Bob Electric',
      serviceCategory: 'Electrical',
      status: BookingStatus.PENDING,
      jobDescription: 'Fix main breaker box',
      financials: BookingFinancials(
        agreedPrice: 300.0,
        platformFee: 30.0,
        providerPayout: 270.0,
        isHeldInEscrow: true,
      ),
      timestamps: BookingTimestamps(
        requestedAt: now.subtract(const Duration(days: 10)),
        scheduledFor: now.add(const Duration(days: 2)),
      ),
    );

    recentBooking = BookingModel(
      bookingId: 'b_recent',
      clientId: 'client_1',
      providerId: 'provider_2',
      clientName: 'Alice Mwansa',
      providerName: 'Charlie Plumbing',
      serviceCategory: 'Plumbing',
      status: BookingStatus.ACCEPTED,
      jobDescription: 'Fix sink leaking tap',
      financials: BookingFinancials(
        agreedPrice: 150.0,
        platformFee: 15.0,
        providerPayout: 135.0,
        isHeldInEscrow: true,
      ),
      timestamps: BookingTimestamps(
        requestedAt: now.subtract(const Duration(days: 3)),
        scheduledFor: now.add(const Duration(days: 1)),
      ),
    );

    latestBooking = BookingModel(
      bookingId: 'b_latest',
      clientId: 'client_1',
      providerId: 'provider_1',
      clientName: 'Alice Mwansa',
      providerName: 'Bob Electric',
      serviceCategory: 'Electrical',
      status: BookingStatus.IN_PROGRESS,
      jobDescription: 'Install solar inverter system',
      financials: BookingFinancials(
        agreedPrice: 2000.0,
        platformFee: 200.0,
        providerPayout: 1800.0,
        isHeldInEscrow: true,
      ),
      timestamps: BookingTimestamps(
        requestedAt: now.subtract(const Duration(hours: 2)),
        scheduledFor: now.add(const Duration(hours: 4)),
      ),
    );

    completedBooking = BookingModel(
      bookingId: 'b_completed',
      clientId: 'client_2',
      providerId: 'provider_1',
      clientName: 'David Banda',
      providerName: 'Bob Electric',
      serviceCategory: 'Electrical',
      status: BookingStatus.COMPLETED,
      jobDescription: 'Rewiring bedroom lighting',
      financials: BookingFinancials(
        agreedPrice: 400.0,
        platformFee: 40.0,
        providerPayout: 360.0,
        isHeldInEscrow: false,
      ),
      timestamps: BookingTimestamps(
        requestedAt: now.subtract(const Duration(days: 15)),
        scheduledFor: now.subtract(const Duration(days: 14)),
      ),
    );

    cancelledBooking = BookingModel(
      bookingId: 'b_cancelled',
      clientId: 'client_1',
      providerId: 'provider_3',
      clientName: 'Alice Mwansa',
      providerName: 'Eve Carpentry',
      serviceCategory: 'Carpentry',
      status: BookingStatus.CANCELLED,
      jobDescription: 'Custom wardrobe assembly',
      financials: BookingFinancials(
        agreedPrice: 800.0,
        platformFee: 80.0,
        providerPayout: 720.0,
        isHeldInEscrow: false,
      ),
      timestamps: BookingTimestamps(
        requestedAt: now.subtract(const Duration(days: 5)),
        scheduledFor: now.subtract(const Duration(days: 4)),
      ),
    );
  });

  group('BookingStatus Enum Tests', () {
    test('BookingStatus displayName getters return expected readable strings', () {
      expect(BookingStatus.PENDING.displayName, 'Pending');
      expect(BookingStatus.ACCEPTED.displayName, 'Accepted');
      expect(BookingStatus.IN_PROGRESS.displayName, 'In Progress');
      expect(BookingStatus.COMPLETED.displayName, 'Completed');
      expect(BookingStatus.CANCELLED.displayName, 'Cancelled');
      expect(BookingStatus.DISPUTED.displayName, 'Disputed');
    });
  });

  group('Booking Model Filtering Tests', () {
    test('Filter bookings by status correctly isolates pending, active, completed, and cancelled', () {
      final allBookings = [
        oldBooking,
        recentBooking,
        latestBooking,
        completedBooking,
        cancelledBooking,
      ];

      final pendingBookings = allBookings.where((b) => b.status == BookingStatus.PENDING).toList();
      expect(pendingBookings.length, 1);
      expect(pendingBookings.first.bookingId, 'b_old');

      final activeBookings = allBookings.where((b) =>
        b.status == BookingStatus.ACCEPTED || b.status == BookingStatus.IN_PROGRESS
      ).toList();
      expect(activeBookings.length, 2);
      expect(activeBookings.map((b) => b.bookingId), containsAll(['b_recent', 'b_latest']));

      final completed = allBookings.where((b) => b.status == BookingStatus.COMPLETED).toList();
      expect(completed.length, 1);
      expect(completed.first.bookingId, 'b_completed');

      final cancelled = allBookings.where((b) => b.status == BookingStatus.CANCELLED).toList();
      expect(cancelled.length, 1);
      expect(cancelled.first.bookingId, 'b_cancelled');
    });

    test('Filter bookings by provider ID or client ID', () {
      final allBookings = [
        oldBooking,
        recentBooking,
        latestBooking,
        completedBooking,
        cancelledBooking,
      ];

      final client1Bookings = allBookings.where((b) => b.clientId == 'client_1').toList();
      expect(client1Bookings.length, 4);

      final provider1Bookings = allBookings.where((b) => b.providerId == 'provider_1').toList();
      expect(provider1Bookings.length, 3);
      expect(provider1Bookings.map((b) => b.bookingId), containsAll(['b_old', 'b_latest', 'b_completed']));
    });
  });

  group('Booking Sorting Tests', () {
    test('Sort bookings descending by requestedAt date (latest first)', () {
      final unsortedList = [
        oldBooking,       // 10 days ago
        completedBooking, // 15 days ago
        latestBooking,    // 2 hours ago
        cancelledBooking, // 5 days ago
        recentBooking,    // 3 days ago
      ];

      final sortedList = List<BookingModel>.from(unsortedList);
      sortedList.sort((a, b) => b.timestamps.requestedAt.compareTo(a.timestamps.requestedAt));

      expect(sortedList[0].bookingId, 'b_latest');
      expect(sortedList[1].bookingId, 'b_recent');
      expect(sortedList[2].bookingId, 'b_cancelled');
      expect(sortedList[3].bookingId, 'b_old');
      expect(sortedList[4].bookingId, 'b_completed');
    });

    test('Sort bookings ascending by scheduledFor date', () {
      final unsortedList = [
        recentBooking, // in 1 day
        oldBooking,    // in 2 days
        latestBooking, // in 4 hours
      ];

      final sortedList = List<BookingModel>.from(unsortedList);
      sortedList.sort((a, b) => a.timestamps.scheduledFor.compareTo(b.timestamps.scheduledFor));

      expect(sortedList[0].bookingId, 'b_latest');
      expect(sortedList[1].bookingId, 'b_recent');
      expect(sortedList[2].bookingId, 'b_old');
    });
  });

  group('BookingModel Serialization Tests', () {
    test('BookingModel toMap and fromMap serialization maintains fields', () {
      final map = recentBooking.toMap();
      expect(map['bookingId'], 'b_recent');
      expect(map['clientId'], 'client_1');
      expect(map['providerId'], 'provider_2');
      expect(map['status'], 'accepted');
      expect(map['serviceCategory'], 'Plumbing');

      final deserialized = BookingModel.fromMap(map, 'b_recent');
      expect(deserialized.bookingId, 'b_recent');
      expect(deserialized.clientName, 'Alice Mwansa');
      expect(deserialized.status, BookingStatus.ACCEPTED);
      expect(deserialized.financials.agreedPrice, 150.0);
      expect(deserialized.financials.platformFee, 15.0);
      expect(deserialized.financials.providerPayout, 135.0);
    });
  });
}
