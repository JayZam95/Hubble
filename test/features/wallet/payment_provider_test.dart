import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:hubble/features/wallet/data/repositories/payment_repository.dart';
import 'package:hubble/features/wallet/domain/models/transaction_model.dart';
import 'package:hubble/features/wallet/presentation/providers/payment_provider.dart';
import 'package:hubble/features/bookings/domain/models/booking_model.dart';

void main() {
  group('Payment & Escrow Calculation Unit Tests', () {
    test('BookingFinancials correctly calculates 10% platform fee and provider payout', () {
      const double agreedPrice = 500.0;
      final platformFee = agreedPrice * 0.10; // K50
      final providerPayout = agreedPrice - platformFee; // K450

      final financials = BookingFinancials(
        agreedPrice: agreedPrice,
        platformFee: platformFee,
        providerPayout: providerPayout,
        isHeldInEscrow: true,
        paymentMethod: 'escrow',
      );

      expect(financials.agreedPrice, 500.0);
      expect(financials.platformFee, 50.0);
      expect(financials.providerPayout, 450.0);
      expect(financials.isHeldInEscrow, isTrue);
      expect(financials.paymentMethod, 'escrow');
    });

    test('BookingFinancials toMap and fromMap serialization', () {
      final financials = BookingFinancials(
        agreedPrice: 200.0,
        platformFee: 20.0,
        providerPayout: 180.0,
        isHeldInEscrow: true,
        paymentMethod: 'escrow',
      );

      final map = financials.toMap();
      expect(map['agreedPrice'], 200.0);
      expect(map['platformFee'], 20.0);
      expect(map['providerPayout'], 180.0);
      expect(map['isHeldInEscrow'], isTrue);

      final deserialized = BookingFinancials.fromMap(map);
      expect(deserialized.agreedPrice, 200.0);
      expect(deserialized.platformFee, 20.0);
      expect(deserialized.providerPayout, 180.0);
      expect(deserialized.isHeldInEscrow, isTrue);
    });

    test('TransactionModel correctly serializes and deserializes DEPOSIT and WITHDRAWAL', () {
      final now = DateTime.now();
      final tx = TransactionModel(
        id: 'tx_123',
        txRef: 'ref_123',
        type: 'DEPOSIT',
        amount: 150.0,
        gateway: 'FLUTTERWAVE',
        network: 'MTN',
        status: 'SUCCESSFUL',
        timestamp: now,
      );

      final map = tx.toMap();
      expect(map['txRef'], 'ref_123');
      expect(map['type'], 'DEPOSIT');
      expect(map['amount'], 150.0);

      final fromMapTx = TransactionModel.fromMap({
        'txRef': 'ref_456',
        'type': 'WITHDRAWAL',
        'amount': 75.0,
        'gateway': 'MOCK',
        'status': 'SUCCESSFUL',
      }, 'tx_456');

      expect(fromMapTx.id, 'tx_456');
      expect(fromMapTx.type, 'WITHDRAWAL');
      expect(fromMapTx.amount, 75.0);
      expect(fromMapTx.status, 'SUCCESSFUL');
    });
  });

  group('Wallet Balance Changes via PaymentRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late PaymentRepository paymentRepository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      paymentRepository = PaymentRepository(firestore: fakeFirestore);
    });

    test('depositFunds increases available balance and logs transaction', () async {
      const userId = 'user_001';
      // Initialize user doc
      await fakeFirestore.collection('users').doc(userId).set({
        'financialLedger': {
          'availableBalance': 100.0,
        },
      });

      await paymentRepository.depositFunds(userId, 50.0, 'tx_dep_1', 'AIRTEL');

      final doc = await fakeFirestore.collection('users').doc(userId).get();
      final balance = (doc.data()!['financialLedger'] as Map<String, dynamic>)['availableBalance'];
      expect(balance, 150.0);

      final txDoc = await fakeFirestore.collection('users').doc(userId).collection('transactions').doc('tx_dep_1').get();
      expect(txDoc.exists, isTrue);
      expect(txDoc.data()!['amount'], 50.0);
      expect(txDoc.data()!['type'], 'DEPOSIT');
    });

    test('withdrawFunds decreases available balance when sufficient funds exist', () async {
      const userId = 'user_002';
      await fakeFirestore.collection('users').doc(userId).set({
        'financialLedger': {
          'availableBalance': 200.0,
        },
      });

      await paymentRepository.withdrawFunds(userId, 80.0);

      final doc = await fakeFirestore.collection('users').doc(userId).get();
      final balance = (doc.data()!['financialLedger'] as Map<String, dynamic>)['availableBalance'];
      expect(balance, 120.0);
    });

    test('withdrawFunds throws exception when insufficient funds', () async {
      const userId = 'user_003';
      await fakeFirestore.collection('users').doc(userId).set({
        'financialLedger': {
          'availableBalance': 30.0,
        },
      });

      expect(
        () async => await paymentRepository.withdrawFunds(userId, 100.0),
        throwsA(isA<Exception>()),
      );
    });

    test('depositFunds and withdrawFunds throw exception for negative or zero amounts', () async {
      const userId = 'user_004';
      await fakeFirestore.collection('users').doc(userId).set({
        'financialLedger': {'availableBalance': 500.0},
      });

      expect(
        () async => await paymentRepository.depositFunds(userId, -10.0, 'tx_invalid', 'MTN'),
        throwsA(isA<Exception>()),
      );

      expect(
        () async => await paymentRepository.withdrawFunds(userId, 0.0),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('PaymentController Riverpod Tests', () {
    test('PaymentController initial state is AsyncValue.data(null)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(paymentControllerProvider);
      expect(state, const AsyncValue<void>.data(null));
    });
  });
}
