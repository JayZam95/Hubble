import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/booking_model.dart';

class BookingRepository {
  final FirebaseFirestore _firestore;

  BookingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<BookingModel>> getBookingsStream({
    required String userId,
    required bool isClient,
  }) {
    final field = isClient ? 'clientId' : 'providerId';
    return _firestore
        .collection('bookings')
        .where(field, isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

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
    String billingType = 'fixed',
    int quantity = 1,
    String paymentMethod = 'escrow',
  }) async {
    final docRef = _firestore.collection('bookings').doc();
    final platformFee = agreedPrice * 0.10;
    final providerPayout = agreedPrice - platformFee;

    final bookingData = {
      'bookingId': docRef.id,
      'clientId': clientId,
      'providerId': providerId,
      'clientName': clientName,
      'providerName': providerName,
      'serviceCategory': serviceCategory,
      'status': BookingStatus.PENDING.name,
      'jobDescription': jobDescription,
      'financials': {
        'agreedPrice': agreedPrice,
        'platformFee': platformFee,
        'providerPayout': providerPayout,
        'isHeldInEscrow': true,
        'paymentMethod': paymentMethod,
      },
      'timestamps': {
        'requestedAt': FieldValue.serverTimestamp(),
        'scheduledFor': Timestamp.fromDate(scheduledFor),
      },
      'listingId': listingId,
      'billingType': billingType,
      'quantity': quantity,
    };

    await docRef.set(bookingData);
    return docRef.id;
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required String userId,
    required BookingStatus newStatus,
  }) async {
    final docRef = _firestore.collection('bookings').doc(bookingId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      throw Exception('Booking does not exist.');
    }

    final data = snapshot.data();
    if (data == null) {
      throw Exception('Booking is empty.');
    }

    final clientId = data['clientId'] as String? ?? '';
    final providerId = data['providerId'] as String? ?? '';

    if (userId != clientId && userId != providerId) {
      throw Exception('Security violation: User not authorized to modify this booking.');
    }

    // Role-based status constraints
    if (userId == clientId) {
      // Client is allowed to transition to CANCELLED or DISPUTED
      if (newStatus != BookingStatus.CANCELLED && newStatus != BookingStatus.DISPUTED) {
        throw Exception('Security violation: Client can only transition status to CANCELLED or DISPUTED.');
      }
    } else if (userId == providerId) {
      // Provider is allowed to accept, set in progress, or complete
      if (newStatus == BookingStatus.PENDING) {
        throw Exception('Security violation: Provider cannot transition status back to PENDING.');
      }
    }

    // If transitioning to COMPLETED, release escrow funds securely
    if (newStatus == BookingStatus.COMPLETED) {
      await _firestore.runTransaction((transaction) async {
        final bookingSnap = await transaction.get(docRef);
        final bookingData = bookingSnap.data()!;
        
        final currentStatus = bookingData['status'] as String? ?? '';
        if (currentStatus == BookingStatus.COMPLETED.name) {
          throw Exception('Booking is already completed.');
        }

        final financials = bookingData['financials'] as Map<String, dynamic>? ?? {};
        final isHeldInEscrow = financials['isHeldInEscrow'] as bool? ?? false;
        final providerPayout = (financials['providerPayout'] as num? ?? 0.0).toDouble();

        if (isHeldInEscrow && providerPayout > 0) {
          final providerUserRef = _firestore.collection('users').doc(providerId);
          final providerSnap = await transaction.get(providerUserRef);
          
          if (providerSnap.exists && providerSnap.data() != null) {
            final providerData = providerSnap.data()!;
            final ledger = providerData['financialLedger'] as Map<String, dynamic>? ?? {};
            final currentBalance = (ledger['availableBalance'] as num? ?? 0.0).toDouble();
            
            // Release funds dynamically depending on billing models
            // Product delivery (perItem), standard fixed, monthly subscription release
            transaction.update(providerUserRef, {
              'financialLedger.availableBalance': currentBalance + providerPayout,
            });
            
            transaction.update(docRef, {
              'status': newStatus.name,
              'financials.isHeldInEscrow': false,
            });
          } else {
            transaction.update(docRef, {
              'status': newStatus.name,
            });
          }
        } else {
          transaction.update(docRef, {
            'status': newStatus.name,
          });
        }
      });
    } else if (newStatus == BookingStatus.CANCELLED) {
      await docRef.update({
        'status': newStatus.name,
        'financials.isHeldInEscrow': false,
      });
    } else {
      await docRef.update({
        'status': newStatus.name,
      });
    }
  }
}
