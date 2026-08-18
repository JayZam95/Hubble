import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/review_model.dart';

final reviewProvider = StreamProvider.family<List<ReviewModel>, String>((ref, providerId) {
  return FirebaseFirestore.instance
      .collection('reviews')
      .where('providerId', isEqualTo: providerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => ReviewModel.fromMap(doc.data(), doc.id)).toList();
      });
});
