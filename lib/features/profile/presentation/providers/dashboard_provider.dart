import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../bookings/presentation/providers/booking_provider.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../../bookings/domain/models/booking_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../marketplace/domain/models/order_model.dart';

class RetailDashboardMetrics {
  final double totalRevenue;
  final int totalOrders;
  final int lowStockItems;
  final int profileViews;
  final List<OrderModel> recentOrders;

  RetailDashboardMetrics({
    required this.totalRevenue,
    required this.totalOrders,
    required this.lowStockItems,
    this.profileViews = 0,
    this.recentOrders = const [],
  });
}

class ServiceDashboardMetrics {
  final double totalEarnings;
  final int activeJobs;
  final int completedJobs;
  final List<BookingModel> upcomingJobs;

  ServiceDashboardMetrics({
    required this.totalEarnings,
    required this.activeJobs,
    required this.completedJobs,
    required this.upcomingJobs,
  });
}

final providerOrdersStreamProvider = StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final user = ref.watch(authStateProvider).user;
  if (user == null) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collection('orders')
      .where('sellerId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => OrderModel.fromMap(doc.data(), doc.id)).toList());
});

final retailDashboardProvider = Provider.autoDispose<AsyncValue<RetailDashboardMetrics>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;
  if (user == null) {
    return const AsyncValue.loading();
  }

  final ordersAsync = ref.watch(providerOrdersStreamProvider);
  final listingsAsync = ref.watch(providerListingsProvider(user.uid));

  if (ordersAsync.isLoading || listingsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (ordersAsync.hasError) {
    return AsyncValue.error(ordersAsync.error!, ordersAsync.stackTrace!);
  }
  if (listingsAsync.hasError) {
    return AsyncValue.error(listingsAsync.error!, listingsAsync.stackTrace!);
  }

  final orders = ordersAsync.value ?? [];
  final listings = listingsAsync.value ?? [];

  double revenue = 0.0;
  int orderCount = 0;
  for (final o in orders) {
    if (o.status == OrderStatus.delivered || o.status == OrderStatus.shipped || o.status == OrderStatus.confirmed) {
      revenue += o.totalAmount;
    }
    if (o.status != OrderStatus.cancelled) {
      orderCount++;
    }
  }

  int lowStock = 0;
  for (final l in listings) {
    if (l.stockCount < 5) {
      lowStock++;
    }
  }

  return AsyncValue.data(RetailDashboardMetrics(
    totalRevenue: revenue,
    totalOrders: orderCount,
    lowStockItems: lowStock,
    profileViews: 0,
    recentOrders: orders,
  ));
});

final serviceDashboardProvider = Provider.autoDispose<AsyncValue<ServiceDashboardMetrics>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;
  if (user == null) {
    return const AsyncValue.loading();
  }

  final bookingsAsync = ref.watch(providerBookingsStreamProvider);

  if (bookingsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (bookingsAsync.hasError) {
    return AsyncValue.error(bookingsAsync.error!, bookingsAsync.stackTrace!);
  }

  final bookings = bookingsAsync.value ?? [];

  double earnings = 0.0;
  int active = 0;
  int completed = 0;
  List<BookingModel> upcoming = [];

  for (final b in bookings) {
    if (b.status == BookingStatus.COMPLETED) {
      earnings += b.financials.providerPayout;
      completed++;
    } else if (b.status == BookingStatus.ACCEPTED || b.status == BookingStatus.IN_PROGRESS) {
      active++;
      upcoming.add(b);
    }
  }

  upcoming.sort((a, b) => a.timestamps.scheduledFor.compareTo(b.timestamps.scheduledFor));

  return AsyncValue.data(ServiceDashboardMetrics(
    totalEarnings: earnings,
    activeJobs: active,
    completedJobs: completed,
    upcomingJobs: upcoming,
  ));
});
