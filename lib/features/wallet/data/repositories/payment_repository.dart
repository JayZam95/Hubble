import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/payment_config.dart';

class PaymentRepository {
  final FirebaseFirestore _firestore;
  final http.Client _client;

  PaymentRepository({FirebaseFirestore? firestore, http.Client? client})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _client = client ?? http.Client();

  /// Initiates a Zambia Mobile Money Charge via Flutterwave V3 API.
  /// Returns a Map containing the initiated transaction details (status, txRef, flwId).
  Future<Map<String, dynamic>> initiateMobileMoneyPayment({
    required String userId,
    required double amount,
    required String phoneNumber,
    required String network, // MTN, AIRTEL, ZAMTEL
    required String email,
    required String fullName,
  }) async {
    if (amount <= 0) throw Exception('Invalid amount');

    final txRef = 'hubble-tx-${DateTime.now().millisecondsSinceEpoch}';

    final body = {
      'amount': amount.toString(),
      'currency': 'ZMW',
      'phone_number': phoneNumber,
      'network': network.toUpperCase(),
      'email': email,
      'tx_ref': txRef,
      'fullname': fullName,
    };

    final response = await _client.post(
      Uri.parse(PaymentConfig.chargeUrl),
      headers: {
        'Authorization': 'Bearer ${PaymentConfig.flutterwaveSecretKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to initiate mobile money charge');
    }

    final resData = jsonDecode(response.body);
    if (resData['status'] != 'success') {
      throw Exception(resData['message'] ?? 'Payment initiation failed');
    }

    // Success response contains meta or data with transaction id
    final data = resData['data'];
    return {
      'status': data['status'], // e.g. pending
      'txRef': txRef,
      'id': data['id'],
      'message': resData['message'],
    };
  }

  /// Verifies a transaction status on Flutterwave by its reference.
  Future<bool> verifyPaymentByRef(String txRef) async {
    final verifyUrl = '${PaymentConfig.baseUrl}/transactions/verify_by_reference?tx_ref=$txRef';

    final response = await _client.get(
      Uri.parse(verifyUrl),
      headers: {
        'Authorization': 'Bearer ${PaymentConfig.flutterwaveSecretKey}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      return false;
    }

    final resData = jsonDecode(response.body);
    if (resData['status'] == 'success' && resData['data'] != null) {
      final status = resData['data']['status'];
      return status == 'successful';
    }

    return false;
  }

  /// Deposits funds directly into the user's available balance in Firestore
  /// and logs a payment history entry in their ledger.
  Future<void> depositFunds(String userId, double amount, String txRef, String network) async {
    if (amount <= 0) throw Exception('Invalid amount');

    final userRef = _firestore.collection('users').doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('User not found');
      }

      final data = snapshot.data()!;
      final ledger = data['financialLedger'] as Map<String, dynamic>? ?? {};
      final currentBalance = (ledger['availableBalance'] as num? ?? 0.0).toDouble();
      
      // Update balance
      transaction.update(userRef, {
        'financialLedger.availableBalance': currentBalance + amount,
      });

      // Add dynamic transaction log to subcollection or history array
      final historyRef = userRef.collection('transactions').doc(txRef);
      transaction.set(historyRef, {
        'txRef': txRef,
        'type': 'DEPOSIT',
        'amount': amount,
        'gateway': 'FLUTTERWAVE',
        'network': network,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'SUCCESSFUL',
      });
    });
  }

  /// Withdraws funds by decrementing the available balance in Firestore
  /// and logging a transaction history entry.
  Future<void> withdrawFunds(String userId, double amount) async {
    if (amount <= 0) throw Exception('Invalid amount');

    final userRef = _firestore.collection('users').doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('User not found');
      }

      final data = snapshot.data()!;
      final ledger = data['financialLedger'] as Map<String, dynamic>? ?? {};
      final currentBalance = (ledger['availableBalance'] as num? ?? 0.0).toDouble();

      if (currentBalance < amount) {
        throw Exception('Insufficient funds');
      }

      transaction.update(userRef, {
        'financialLedger.availableBalance': currentBalance - amount,
      });

      final txRef = 'hubble-wd-${DateTime.now().millisecondsSinceEpoch}';
      final historyRef = userRef.collection('transactions').doc(txRef);
      transaction.set(historyRef, {
        'txRef': txRef,
        'type': 'WITHDRAWAL',
        'amount': amount,
        'gateway': 'MOCK',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'SUCCESSFUL',
      });
    });
  }

  /// Holds funds in escrow by deducting from available balance and logging ESCROW_HOLD.
  Future<void> holdInEscrow({
    required String userId,
    required double amount,
    required String bookingId,
  }) async {
    if (amount <= 0) throw Exception('Invalid amount');

    final userRef = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('User not found');
      }

      final data = snapshot.data()!;
      final ledger = data['financialLedger'] as Map<String, dynamic>? ?? {};
      final currentBalance = (ledger['availableBalance'] as num? ?? 0.0).toDouble();

      if (currentBalance < amount) {
        throw Exception('Insufficient funds in wallet');
      }

      transaction.update(userRef, {
        'financialLedger.availableBalance': currentBalance - amount,
      });

      final txRef = 'hubble-escrow-hold-${DateTime.now().millisecondsSinceEpoch}';
      final historyRef = userRef.collection('transactions').doc(txRef);
      transaction.set(historyRef, {
        'txRef': txRef,
        'type': 'ESCROW_HOLD',
        'amount': amount,
        'bookingId': bookingId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'SUCCESSFUL',
      });
    });
  }

  /// Releases escrow funds to the provider. Idempotent check prevents double payout.
  Future<void> releaseEscrow({
    required String bookingId,
    required String providerId,
    required double amount,
    required String clientId,
  }) async {
    if (amount <= 0) throw Exception('Invalid amount');

    final bookingRef = _firestore.collection('bookings').doc(bookingId);
    final providerRef = _firestore.collection('users').doc(providerId);

    await _firestore.runTransaction((transaction) async {
      final bookingSnap = await transaction.get(bookingRef);
      if (bookingSnap.exists && bookingSnap.data() != null) {
        final bData = bookingSnap.data()!;
        final financials = bData['financials'] as Map<String, dynamic>? ?? {};
        final isHeld = financials['isHeldInEscrow'] as bool? ?? false;
        if (!isHeld) {
          // Escrow funds already released or not held
          return;
        }

        transaction.update(bookingRef, {
          'financials.isHeldInEscrow': false,
          'status': 'COMPLETED',
        });
      }

      final providerSnap = await transaction.get(providerRef);
      if (providerSnap.exists && providerSnap.data() != null) {
        final pData = providerSnap.data()!;
        final ledger = pData['financialLedger'] as Map<String, dynamic>? ?? {};
        final currentBalance = (ledger['availableBalance'] as num? ?? 0.0).toDouble();

        transaction.update(providerRef, {
          'financialLedger.availableBalance': currentBalance + amount,
        });

        final txRef = 'hubble-escrow-rel-${DateTime.now().millisecondsSinceEpoch}';
        final historyRef = providerRef.collection('transactions').doc(txRef);
        transaction.set(historyRef, {
          'txRef': txRef,
          'type': 'ESCROW_RELEASE',
          'amount': amount,
          'bookingId': bookingId,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'SUCCESSFUL',
        });
      }
    });
  }

  /// Refunds escrow funds back to the client. Idempotent.
  Future<void> refundEscrow({
    required String bookingId,
    required String clientId,
    required double amount,
  }) async {
    if (amount <= 0) return;

    final bookingRef = _firestore.collection('bookings').doc(bookingId);
    final clientRef = _firestore.collection('users').doc(clientId);

    await _firestore.runTransaction((transaction) async {
      final bookingSnap = await transaction.get(bookingRef);
      if (bookingSnap.exists && bookingSnap.data() != null) {
        final bData = bookingSnap.data()!;
        final financials = bData['financials'] as Map<String, dynamic>? ?? {};
        final isHeld = financials['isHeldInEscrow'] as bool? ?? false;
        if (!isHeld) {
          return;
        }

        transaction.update(bookingRef, {
          'financials.isHeldInEscrow': false,
          'status': 'CANCELLED',
        });
      }

      final clientSnap = await transaction.get(clientRef);
      if (clientSnap.exists && clientSnap.data() != null) {
        final cData = clientSnap.data()!;
        final ledger = cData['financialLedger'] as Map<String, dynamic>? ?? {};
        final currentBalance = (ledger['availableBalance'] as num? ?? 0.0).toDouble();

        transaction.update(clientRef, {
          'financialLedger.availableBalance': currentBalance + amount,
        });

        final txRef = 'hubble-escrow-ref-${DateTime.now().millisecondsSinceEpoch}';
        final historyRef = clientRef.collection('transactions').doc(txRef);
        transaction.set(historyRef, {
          'txRef': txRef,
          'type': 'ESCROW_REFUND',
          'amount': amount,
          'bookingId': bookingId,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'SUCCESSFUL',
        });
      }
    });
  }

  /// Resolves a dispute by either refunding the client or releasing to the provider.
  Future<void> adminResolveDispute({
    required String bookingId,
    required String disputeId,
    required String clientId,
    required String providerId,
    required double amount,
    required bool refundToClient,
  }) async {
    if (refundToClient) {
      await refundEscrow(
        bookingId: bookingId,
        clientId: clientId,
        amount: amount,
      );
    } else {
      await releaseEscrow(
        bookingId: bookingId,
        providerId: providerId,
        amount: amount,
        clientId: clientId,
      );
    }

    if (disputeId.isNotEmpty) {
      await _firestore.collection('disputes').doc(disputeId).update({
        'status': refundToClient ? 'RESOLVED_REFUNDED' : 'RESOLVED_PAID',
        'resolvedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
