import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String reviewId;
  final String bookingId;
  final String reviewerId;
  final String revieweeId;
  final double rating;
  final String comment;
  final DateTime? timestamp;

  ReviewModel({
    required this.reviewId,
    required this.bookingId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    required this.comment,
    this.timestamp,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedTimestamp;
    if (json['timestamp'] != null) {
      if (json['timestamp'] is Timestamp) {
        parsedTimestamp = (json['timestamp'] as Timestamp).toDate();
      } else if (json['timestamp'] is String) {
        parsedTimestamp = DateTime.tryParse(json['timestamp']);
      }
    }

    return ReviewModel(
      reviewId: json['reviewId'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      reviewerId: json['reviewerId'] as String? ?? '',
      revieweeId: json['revieweeId'] as String? ?? '',
      rating: (json['rating'] as num? ?? 0.0).toDouble(),
      comment: json['comment'] as String? ?? '',
      timestamp: parsedTimestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reviewId': reviewId,
      'bookingId': bookingId,
      'reviewerId': reviewerId,
      'revieweeId': revieweeId,
      'rating': rating,
      'comment': comment,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
    };
  }
}
