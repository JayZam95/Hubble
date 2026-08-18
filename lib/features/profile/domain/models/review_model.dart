import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String providerId;
  final String clientId;
  final String clientName;
  final String? clientImage;
  final String bookingId;
  final double rating;
  final String text;
  final DateTime createdAt;
  final bool allowsReferences;

  ReviewModel({
    required this.id,
    required this.providerId,
    required this.clientId,
    required this.clientName,
    this.clientImage,
    required this.bookingId,
    required this.rating,
    required this.text,
    required this.createdAt,
    this.allowsReferences = true,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ReviewModel(
      id: documentId,
      providerId: map['providerId'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? 'Anonymous',
      clientImage: map['clientImage'],
      bookingId: map['bookingId'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      text: map['text'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      allowsReferences: map['allowsReferences'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'clientId': clientId,
      'clientName': clientName,
      'clientImage': clientImage,
      'bookingId': bookingId,
      'rating': rating,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'allowsReferences': allowsReferences,
    };
  }
}
