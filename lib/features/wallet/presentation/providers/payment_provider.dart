import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/payment_repository.dart';
import '../../domain/models/transaction_model.dart';
import 'package:cloud_functions/cloud_functions.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository();
});

final transactionHistoryProvider = StreamProvider.family.autoDispose<List<TransactionModel>, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('transactions')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList());
});

class PaymentController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> holdInEscrow(double amount, String bookingId, {String? userId}) async {
    state = const AsyncValue.loading();
    try {
      final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
      try {
        final callable = FirebaseFunctions.instanceFor(region: 'europe-west1').httpsCallable('holdInEscrow');
        await callable.call({
          'amount': amount,
          'bookingId': bookingId,
        });
      } catch (_) {
        if (uid != null) {
          await ref.read(paymentRepositoryProvider).holdInEscrow(
            userId: uid,
            amount: amount,
            bookingId: bookingId,
          );
        } else {
          rethrow;
        }
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> releaseEscrow(String bookingId, String providerId, double amount, String clientId) async {
    state = const AsyncValue.loading();
    try {
      try {
        final callable = FirebaseFunctions.instanceFor(region: 'europe-west1').httpsCallable('releaseEscrow');
        await callable.call({
          'amount': amount,
          'bookingId': bookingId,
          'providerId': providerId,
          'clientId': clientId,
        });
      } catch (_) {
        await ref.read(paymentRepositoryProvider).releaseEscrow(
          bookingId: bookingId,
          providerId: providerId,
          amount: amount,
          clientId: clientId,
        );
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> refundEscrow(String bookingId, String clientId, double amount) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(paymentRepositoryProvider).refundEscrow(
        bookingId: bookingId,
        clientId: clientId,
        amount: amount,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> adminResolveDispute({
    required String bookingId,
    required String disputeId,
    required String clientId,
    required String providerId,
    required double amount,
    required bool refundToClient,
  }) async {
    state = const AsyncValue.loading();
    try {
      try {
        final callable = FirebaseFunctions.instanceFor(region: 'europe-west1').httpsCallable('releaseEscrow');
        await callable.call({
          'amount': amount,
          'bookingId': bookingId,
          'providerId': refundToClient ? clientId : providerId,
          'clientId': clientId,
        });
      } catch (_) {
        await ref.read(paymentRepositoryProvider).adminResolveDispute(
          bookingId: bookingId,
          disputeId: disputeId,
          clientId: clientId,
          providerId: providerId,
          amount: amount,
          refundToClient: refundToClient,
        );
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> topUpWallet(double amount, String phoneNumber, String network) async {
    state = const AsyncValue.loading();
    try {
      try {
        final callable = FirebaseFunctions.instanceFor(region: 'europe-west1').httpsCallable('requestDeposit');
        final result = await callable.call({
          'amount': amount,
          'phoneNumber': phoneNumber,
          'network': network,
        });
        debugPrint('Deposit initiated: ${result.data}');
      } catch (_) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          final txRef = 'hubble-tx-${DateTime.now().millisecondsSinceEpoch}';
          await ref.read(paymentRepositoryProvider).depositFunds(uid, amount, txRef, network);
        } else {
          rethrow;
        }
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
  
  Future<void> requestWithdrawal(double amount, String phoneNumber, String network) async {
    state = const AsyncValue.loading();
    try {
      try {
        final callable = FirebaseFunctions.instanceFor(region: 'europe-west1').httpsCallable('requestWithdrawal');
        final result = await callable.call({
          'amount': amount,
          'phoneNumber': phoneNumber,
          'network': network,
        });
        debugPrint('Withdrawal initiated: ${result.data}');
      } catch (_) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await ref.read(paymentRepositoryProvider).withdrawFunds(uid, amount);
        } else {
          rethrow;
        }
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final paymentControllerProvider = NotifierProvider<PaymentController, AsyncValue<void>>(() {
  return PaymentController();
});
