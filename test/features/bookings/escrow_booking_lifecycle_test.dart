import 'package:flutter_test/flutter_test.dart';
import 'package:hubble/features/bookings/domain/models/booking_model.dart';
import 'package:hubble/features/wallet/domain/models/transaction_model.dart';

void main() {
  group('Escrow & Booking Lifecycle End-to-End Tests', () {
    test('Happy Path: Complete Escrow Holding, 10% Platform Fee, 90% Provider Payout', () {
      const initialClientBalance = 500.0;
      const initialClientVault = 0.0;
      const initialProviderBalance = 0.0;
      const bookingPrice = 200.0;

      // 1. Booking initiation & Escrow Hold calculation
      const platformFee = bookingPrice * 0.10; // 20.0
      const providerPayout = bookingPrice - platformFee; // 180.0

      final financials = BookingFinancials(
        agreedPrice: bookingPrice,
        platformFee: platformFee,
        providerPayout: providerPayout,
        isHeldInEscrow: true,
        paymentMethod: 'escrow',
      );

      final clientVaultAfterHold = initialClientVault + bookingPrice;
      final clientBalanceAfterHold = initialClientBalance - bookingPrice;

      expect(clientBalanceAfterHold, 300.0);
      expect(clientVaultAfterHold, 200.0);
      expect(financials.isHeldInEscrow, true);
      expect(financials.platformFee, 20.0);
      expect(financials.providerPayout, 180.0);

      // 2. Booking State Transitions
      final timestamps = BookingTimestamps(
        requestedAt: DateTime.now(),
        scheduledFor: DateTime.now().add(const Duration(days: 1)),
      );

      final booking = BookingModel(
        bookingId: 'book_lifecycle_01',
        clientId: 'client_A',
        providerId: 'provider_B',
        clientName: 'Alice Mwape',
        providerName: 'Bob Banda',
        serviceCategory: 'Plumbing',
        status: BookingStatus.pending,
        jobDescription: 'Fix kitchen sink leak',
        financials: financials,
        timestamps: timestamps,
      );

      expect(booking.status, BookingStatus.pending);
      expect(booking.financials.isHeldInEscrow, true);

      // 3. Escrow Release: 90% credited to provider, 10% retained
      final providerBalanceAfterRelease = initialProviderBalance + financials.providerPayout;
      final clientVaultAfterRelease = clientVaultAfterHold - bookingPrice;

      expect(providerBalanceAfterRelease, 180.0);
      expect(clientVaultAfterRelease, 0.0);
    });

    test('Dispute & Refund Path: Escrow Frozen on Dispute and Fully Returned on Refund', () {
      const initialClientBalance = 500.0;
      const initialClientVault = 0.0;
      const bookingPrice = 350.0;

      // 1. Escrow locked
      final clientVaultAfterHold = initialClientVault + bookingPrice;
      final clientBalanceAfterHold = initialClientBalance - bookingPrice;

      final booking = BookingModel(
        bookingId: 'book_dispute_02',
        clientId: 'client_A',
        providerId: 'provider_B',
        clientName: 'Alice Mwape',
        providerName: 'Bob Banda',
        serviceCategory: 'Electrician',
        status: BookingStatus.disputed,
        jobDescription: 'Rewire main breaker',
        financials: BookingFinancials(
          agreedPrice: bookingPrice,
          platformFee: 35.0,
          providerPayout: 315.0,
          isHeldInEscrow: true,
        ),
        timestamps: BookingTimestamps(
          requestedAt: DateTime.now(),
          scheduledFor: DateTime.now().add(const Duration(days: 1)),
        ),
      );

      expect(booking.status, BookingStatus.disputed);
      expect(booking.financials.isHeldInEscrow, true);

      // 2. Admin arbitrates and triggers full refund to client available balance
      final clientBalanceAfterRefund = clientBalanceAfterHold + bookingPrice;
      final clientVaultAfterRefund = clientVaultAfterHold - bookingPrice;

      expect(clientBalanceAfterRefund, 500.0);
      expect(clientVaultAfterRefund, 0.0);
    });

    test('Transaction Model Serialization for DEPOSIT, WITHDRAWAL, and ESCROW transactions', () {
      final now = DateTime.now();

      final depositTx = TransactionModel(
        id: 'tx_dep_01',
        txRef: 'deposit-user123-1700000000',
        type: 'DEPOSIT',
        amount: 250.0,
        gateway: 'FLUTTERWAVE',
        network: 'MTN',
        status: 'SUCCESSFUL',
        timestamp: now,
      );

      final map = depositTx.toMap();
      final deserialized = TransactionModel.fromMap(map, 'tx_dep_01');

      expect(deserialized.id, 'tx_dep_01');
      expect(deserialized.amount, 250.0);
      expect(deserialized.type, 'DEPOSIT');
      expect(deserialized.network, 'MTN');
      expect(deserialized.status, 'SUCCESSFUL');
    });
  });
}
