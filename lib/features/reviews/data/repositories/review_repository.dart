import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/review_model.dart';
import '../../../../core/errors/app_exception.dart';

class ReviewRepository {
  final FirebaseFirestore _firestore;

  ReviewRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<ReviewModel>> getReviewsStream(String revieweeId) {
    return _firestore
        .collection('reviews')
        .where('revieweeId', isEqualTo: revieweeId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReviewModel.fromJson(doc.data()))
          .toList();
    }).handleError((error) {
      throw AppException.fromFirebaseException(error);
    });
  }

  Future<void> submitReview({
    required String bookingId,
    required String reviewerId,
    required String revieweeId,
    required double rating,
    required String comment,
  }) async {
    try {
      final reviewDocRef = _firestore.collection('reviews').doc();
      final providerUserRef = _firestore.collection('users').doc(revieweeId);

      // Save review details
      final reviewData = {
        'reviewId': reviewDocRef.id,
        'bookingId': bookingId,
        'reviewerId': reviewerId,
        'revieweeId': revieweeId,
        'rating': rating,
        'comment': comment,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Run safe transaction to save review and update Provider's master rating score and review count
      await _firestore.runTransaction((transaction) async {
        final providerDoc = await transaction.get(providerUserRef);
        if (!providerDoc.exists) {
          throw AppException('Provider profile does not exist.');
        }

        final data = providerDoc.data();
        if (data == null) {
          throw AppException('Provider profile data is empty.');
        }

        transaction.set(reviewDocRef, reviewData);

        final providerProfile = data['providerProfile'] as Map<String, dynamic>? ?? {};
        final currentRating = (providerProfile['ratingAsProvider'] as num? ?? 0.0).toDouble();
        final currentReviews = providerProfile['reviewCount'] as int? ?? 0;

        final newReviewCount = currentReviews + 1;
        final newAverageRating = ((currentRating * currentReviews) + rating) / newReviewCount;

        // Securely update with Dot Notation
        transaction.update(providerUserRef, {
          'providerProfile.ratingAsProvider': newAverageRating,
          'providerProfile.reviewCount': newReviewCount,
        });
      });
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }
}

