import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/presentation/widgets/hubble_image.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import 'coach_list_screen.dart';
import 'available_cabs_screen.dart';
import 'bike_service_screen.dart';
import 'live_ride_tracking_screen.dart';
import '../../../../../core/utils/dummy_data_seeder.dart';

class TransportationHubScreen extends ConsumerWidget {
  const TransportationHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textPrimary = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final textSecondary = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Transportation Hub',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Sync Bus Data',
            onPressed: () async {
              await DummyDataSeeder.seedBusTrips();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bus data synced to Firestore!')),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Active Ongoing Ride Card ────────────────────────────────────
            _buildActiveTripSection(context, ref, isDark),

            // ── Header ──────────────────────────────────────────────────────
            Text(
              'Where to?',
              style: AppTextStyles.h1.copyWith(color: textPrimary, fontSize: 32),
            ),
            const SizedBox(height: 6),
            Text(
              'Select a mode of transport to get started.',
              style: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
            ),
            const SizedBox(height: 24),

            // ── 1. Buses Button ──────────────────────────────────────────────
            _TransportOptionCard(
              isDark: isDark,
              cardColor: cardColor,
              title: 'Buses',
              subtitle: 'Intercity bus selection, live seat plans & digital receipts',
              icon: Icons.directions_bus_filled_rounded,
              gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
              badge: 'INTERCITY',
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CoachListScreen()),
                );
              },
            ),
            const SizedBox(height: 18),

            // ── 2. Cabs Button ───────────────────────────────────────────────
            _TransportOptionCard(
              isDark: isDark,
              cardColor: cardColor,
              title: 'Cabs',
              subtitle: 'Find & request available cabs nearby with live ETAs',
              icon: Icons.local_taxi_rounded,
              gradientColors: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
              badge: 'NEARBY',
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AvailableCabsScreen()),
                );
              },
            ),
            const SizedBox(height: 18),

            // ── 3. Bikes Button (Delivery or Rides) ──────────────────────────
            _TransportOptionCard(
              isDark: isDark,
              cardColor: cardColor,
              title: 'Bikes',
              subtitle: 'Express parcel delivery or boda-boda passenger rides',
              icon: Icons.two_wheeler_rounded,
              gradientColors: const [Color(0xFF0D9488), Color(0xFF0284C7)],
              badge: 'RIDES & COURIER',
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BikeServiceScreen()),
                );
              },
            ),

            const SizedBox(height: 36),

            // ── Information Banner ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Verified Operators & Escrow Security',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'All bus companies, cab drivers, and courier bikers on Hubble are verified for safety.',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTripSection(BuildContext context, WidgetRef ref, bool isDark) {
    final currentUser = ref.watch(authStateProvider).user;
    final isTest = (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'));
    if (isTest) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ride_requests')
          .orderBy('createdAt', descending: true)
          .limit(8)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) return false;
          final status = data['status'] as String?;
          final docUserId = data['userId'] as String?;
          final isUserMatch = currentUser == null ||
              docUserId == currentUser.uid ||
              docUserId == 'guest_user';
          final isActive = status != 'COMPLETED' && status != 'CANCELLED';
          return isUserMatch && isActive;
        }).toList();

        if (docs.isEmpty) return const SizedBox.shrink();

        final activeDoc = docs.first;
        final data = activeDoc.data() as Map<String, dynamic>;
        final rideId = activeDoc.id;
        final rideType = data['type'] as String? ?? 'cab_ride';
        final isBoda = rideType.contains('boda');
        final driverName = data['driverName'] as String? ??
            (isBoda ? 'Moses Sakala' : 'Chileshe Mwansa');
        final driverPhone = data['driverPhone'] as String? ?? '+260 977 492011';
        final driverPhotoUrl = data['driverPhotoUrl'] as String? ?? '';
        final driverRating = (data['driverRating'] as num?)?.toDouble() ?? 4.9;
        final totalRides = (data['totalRides'] as num?)?.toInt() ?? 320;
        final vehicleModel = data['vehicleModel'] as String? ??
            (isBoda ? 'TVS HLX 150 (Red)' : 'Toyota Vitz (Silver)');
        final licensePlate = data['licensePlate'] as String? ??
            (data['riderPlate'] as String? ?? 'BAL 4920');
        final pickupName = data['pickupName'] as String? ?? 'Lusaka CBD';
        final pickupLat = (data['pickupLat'] as num?)?.toDouble() ?? -15.4167;
        final pickupLng = (data['pickupLng'] as num?)?.toDouble() ?? 28.2833;
        final dropoffName = data['dropoffName'] as String? ?? 'East Park Mall';
        final dropoffLat = (data['dropoffLat'] as num?)?.toDouble() ?? -15.3905;
        final dropoffLng = (data['dropoffLng'] as num?)?.toDouble() ?? 28.3225;
        final fare = (data['totalFare'] as num?)?.toDouble() ?? 65.0;
        final distanceKm = (data['distanceKm'] as num?)?.toDouble() ?? 4.5;
        final safetyPin = data['safetyPin'] as String? ?? '4892';
        final statusStr = data['status'] as String? ?? 'DRIVER_DISPATCHED';
        final rideState = RideTrackingStateExtension.fromDbStatus(statusStr);

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFEFF6FF), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'ACTIVE TRIP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppColors.success,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      rideState.displayName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      child: HubbleImage(
                        imagePath: driverPhotoUrl,
                        width: 44,
                        height: 44,
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driverName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$vehicleModel · $licensePlate',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'K ${fare.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'PIN: $safetyPin',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.navigation_rounded, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$pickupName → $dropoffName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LiveRideTrackingScreen(
                            rideId: rideId,
                            rideType: isBoda ? 'boda' : 'cab',
                            driverId: data['driverId'] as String? ?? 'driver_1',
                            driverName: driverName,
                            driverPhone: driverPhone,
                            driverPhotoUrl: driverPhotoUrl,
                            driverRating: driverRating,
                            totalRides: totalRides,
                            vehicleModel: vehicleModel,
                            licensePlate: licensePlate,
                            pickupName: pickupName,
                            pickupLatLng: LatLng(pickupLat, pickupLng),
                            dropoffName: dropoffName,
                            dropoffLatLng: LatLng(dropoffLat, dropoffLng),
                            fare: fare,
                            distanceKm: distanceKm,
                            safetyPin: safetyPin,
                            initialState: rideState,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.map_rounded, size: 18),
                    label: const Text(
                      'Resume Live Tracking',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable Option Card
// ---------------------------------------------------------------------------
class _TransportOptionCard extends StatefulWidget {
  final bool isDark;
  final Color cardColor;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final String? badge;
  final VoidCallback onTap;

  const _TransportOptionCard({
    required this.isDark,
    required this.cardColor,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
    this.badge,
  });

  @override
  State<_TransportOptionCard> createState() => _TransportOptionCardState();
}

class _TransportOptionCardState extends State<_TransportOptionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            color: widget.cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: widget.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon with gradient container
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradientColors.first.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(widget.icon, size: 32, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: widget.isDark
                                ? AppColors.textDarkPrimary
                                : AppColors.textLightPrimary,
                          ),
                        ),
                        if (widget.badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: widget.gradientColors.first.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.badge!,
                              style: TextStyle(
                                color: widget.gradientColors.first,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textLightSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: widget.isDark ? Colors.white38 : Colors.black38,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
