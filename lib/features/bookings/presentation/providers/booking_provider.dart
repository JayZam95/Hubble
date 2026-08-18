import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/booking_repository.dart';
import '../../domain/models/booking_model.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository();
});

final clientBookingsStreamProvider = StreamProvider.autoDispose<List<BookingModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;
  if (user == null) {
    return Stream.value(<BookingModel>[]);
  }
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBookingsStream(userId: user.uid, isClient: true).map((bookings) {
    final sorted = List<BookingModel>.from(bookings);
    sorted.sort((a, b) => b.timestamps.requestedAt.compareTo(a.timestamps.requestedAt));
    return sorted;
  });
});

final providerBookingsStreamProvider = StreamProvider.autoDispose<List<BookingModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;
  if (user == null) {
    return Stream.value(<BookingModel>[]);
  }
  // Check if role is provider, either via name, or toString()
  final isProvider = user.role.name == 'provider' || user.role.toString().contains('provider');
  if (!isProvider) {
    return Stream.value(<BookingModel>[]);
  }
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBookingsStream(userId: user.uid, isClient: false).map((bookings) {
    final sorted = List<BookingModel>.from(bookings);
    sorted.sort((a, b) => b.timestamps.requestedAt.compareTo(a.timestamps.requestedAt));
    return sorted;
  });
});
