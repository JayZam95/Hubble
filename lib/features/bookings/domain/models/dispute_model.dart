import 'package:cloud_firestore/cloud_firestore.dart';

class DisputeModel {
  final String id;
  final String bookingId;
  final String reporterId;
  final String description;
  final List<String> photoUrls;
  final String status;
  final DateTime createdAt;

  DisputeModel({
    required this.id,
    required this.bookingId,
    required this.reporterId,
    required this.description,
    required this.photoUrls,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'reporterId': reporterId,
      'description': description,
      'photoUrls': photoUrls,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory DisputeModel.fromMap(Map<String, dynamic> map, String id) {
    return DisputeModel(
      id: id,
      bookingId: map['bookingId'] ?? '',
      reporterId: map['reporterId'] ?? '',
      description: map['description'] ?? '',
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      status: map['status'] ?? 'OPEN',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
