import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/booking_model.dart';
import '../providers/booking_provider.dart';
import 'booking_detail_screen.dart';
import '../../../../core/presentation/widgets/shimmer_loading.dart';
import '../../../../core/presentation/widgets/animated_empty_state.dart';
import '../../../../core/constants/app_text_styles.dart';

class BookingListScreen extends ConsumerStatefulWidget {
  const BookingListScreen({super.key});

  @override
  ConsumerState<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends ConsumerState<BookingListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clientAsync = ref.watch(clientBookingsStreamProvider);
    final providerAsync = ref.watch(providerBookingsStreamProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    final isProvider = user?.role.name == 'provider';

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        centerTitle: false,
        title: Text(
          'Your Activity',
          style: AppTextStyles.heading1.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          // Custom Tab Selector
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: isDark ? AppColors.bgDarkCard : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: isDark ? Colors.white : Colors.black,
                unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: 'Purchases'),
                  Tab(text: 'Sales'),
                  Tab(text: 'History'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Purchases (Jobs I bought)
                _buildBookingList(
                  asyncValue: clientAsync,
                  isPurchase: true,
                  emptyMessage: 'No purchased jobs here yet.',
                  filterHistory: false,
                ),
                // Tab 2: Sales (Jobs I sell as Provider)
                isProvider
                    ? _buildBookingList(
                        asyncValue: providerAsync,
                        isPurchase: false,
                        emptyMessage: 'No incoming service requests yet.',
                        filterHistory: false,
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.storefront_outlined,
                                  size: 64,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Not a Provider Yet',
                                style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Register as a Service Provider in your settings to start receiving and managing sales requests.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                // Tab 3: History (Completed or Cancelled jobs)
                _buildHistoryTab(
                  clientAsync: clientAsync,
                  providerAsync: providerAsync,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingList({
    required AsyncValue<List<BookingModel>> asyncValue,
    required bool isPurchase,
    required String emptyMessage,
    required bool filterHistory,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: asyncValue.when(
        loading: () => const ShimmerListLoading(),
        error: (err, stack) => Center(
          key: const ValueKey('error'),
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Error syncing bookings',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.withValues(alpha: 0.8), fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        data: (bookings) {
          final filtered = bookings.where((b) {
            final isCompletedOrCancelled = b.status == BookingStatus.COMPLETED || b.status == BookingStatus.CANCELLED;
            return filterHistory ? isCompletedOrCancelled : !isCompletedOrCancelled;
          }).toList();

          if (filtered.isEmpty) {
            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.bgDarkCard : Colors.white,
              onRefresh: () async {
                ref.invalidate(clientBookingsStreamProvider);
                ref.invalidate(providerBookingsStreamProvider);
                await Future.delayed(const Duration(milliseconds: 400));
              },
              child: SingleChildScrollView(
                key: const ValueKey('empty'),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  alignment: Alignment.center,
                  child: AnimatedEmptyState(
                    icon: isPurchase ? Icons.shopping_bag_outlined : Icons.event_busy_rounded,
                    title: 'No Bookings Found',
                    subtitle: emptyMessage,
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.bgDarkCard : Colors.white,
            onRefresh: () async {
              ref.invalidate(clientBookingsStreamProvider);
              ref.invalidate(providerBookingsStreamProvider);
              await Future.delayed(const Duration(milliseconds: 400));
            },
            child: ListView.builder(
              key: const ValueKey('list'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final booking = filtered[index];
                return _BookingCard(
                  booking: booking,
                  isPurchase: isPurchase,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BookingDetailScreen(bookingId: booking.bookingId),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab({
    required AsyncValue<List<BookingModel>> clientAsync,
    required AsyncValue<List<BookingModel>> providerAsync,
  }) {
    final clientList = clientAsync.value ?? [];
    final providerList = providerAsync.value ?? [];

    final clientHistory = clientList.where((b) => b.status == BookingStatus.COMPLETED || b.status == BookingStatus.CANCELLED).map((b) => MapEntry(b, true));
    final providerHistory = providerList.where((b) => b.status == BookingStatus.COMPLETED || b.status == BookingStatus.CANCELLED).map((b) => MapEntry(b, false));

    final combined = [...clientHistory, ...providerHistory];
    combined.sort((a, b) => b.key.timestamps.requestedAt.compareTo(a.key.timestamps.requestedAt));

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: combined.isEmpty
          ? RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.bgDarkCard : Colors.white,
              onRefresh: () async {
                ref.invalidate(clientBookingsStreamProvider);
                ref.invalidate(providerBookingsStreamProvider);
                await Future.delayed(const Duration(milliseconds: 400));
              },
              child: SingleChildScrollView(
                key: const ValueKey('empty_history'),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  alignment: Alignment.center,
                  child: const AnimatedEmptyState(
                    icon: Icons.history_rounded,
                    title: 'No History Yet',
                    subtitle: 'Your transaction history is empty.',
                  ),
                ),
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.bgDarkCard : Colors.white,
              onRefresh: () async {
                ref.invalidate(clientBookingsStreamProvider);
                ref.invalidate(providerBookingsStreamProvider);
                await Future.delayed(const Duration(milliseconds: 400));
              },
              child: ListView.builder(
                key: const ValueKey('history_list'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                itemCount: combined.length,
                itemBuilder: (context, index) {
                  final item = combined[index];
                  final booking = item.key;
                  final isPurchase = item.value;
                  return _BookingCard(
                    booking: booking,
                    isPurchase: isPurchase,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BookingDetailScreen(bookingId: booking.bookingId),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isPurchase;
  final VoidCallback onTap;

  const _BookingCard({
    required this.booking,
    required this.isPurchase,
    required this.onTap,
  });

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.PENDING:
        return Colors.orange;
      case BookingStatus.ACCEPTED:
        return Colors.blue;
      case BookingStatus.IN_PROGRESS:
        return Colors.purple;
      case BookingStatus.COMPLETED:
        return Colors.green;
      case BookingStatus.CANCELLED:
        return Colors.red;
      case BookingStatus.DISPUTED:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(booking.status);
    final dateString = DateFormat('MMM dd, yyyy').format(booking.timestamps.scheduledFor);
    final timeString = DateFormat('h:mm a').format(booking.timestamps.scheduledFor);

    final counterpartyName = isPurchase ? booking.providerName : booking.clientName;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            booking.status.displayName,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          isPurchase ? Icons.shopping_cart_outlined : Icons.storefront_outlined,
                          size: 16,
                          color: isPurchase ? Colors.blue : Colors.purple,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPurchase ? 'Buying' : 'Selling',
                          style: TextStyle(
                            color: isPurchase ? Colors.blue : Colors.purple,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                      ),
                      child: Center(
                        child: Text(
                          counterpartyName.isNotEmpty ? counterpartyName[0].toUpperCase() : 'C',
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 20, 
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.serviceCategory,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            counterpartyName,
                            style: TextStyle(
                              fontSize: 14, 
                              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'K ${booking.financials.agreedPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 16, color: isDark ? Colors.white54 : Colors.black54),
                          const SizedBox(width: 8),
                          Text(
                            dateString, 
                            style: TextStyle(
                              fontSize: 13, 
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: isDark ? Colors.white54 : Colors.black54),
                          const SizedBox(width: 8),
                          Text(
                            timeString, 
                            style: TextStyle(
                              fontSize: 13, 
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
