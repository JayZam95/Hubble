import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/review_repository.dart';
import '../../domain/models/review_model.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository();
});

final providerReviewsStreamProvider = StreamProvider.family<List<ReviewModel>, String>((ref, providerId) {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getReviewsStream(providerId);
});
