import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/presentation/widgets/hubble_image.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../bookings/presentation/screens/booking_creation_screen.dart';
import '../../../marketplace/domain/models/listing_model.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../../marketplace/presentation/screens/listing_detail_screen.dart';
import '../../../marketplace/presentation/providers/cart_provider.dart';
import '../../../marketplace/presentation/screens/cart_screen.dart';
import '../../../marketplace/presentation/screens/transportation/ride_booking_screen.dart';
import '../providers/review_provider.dart';
import '../../domain/models/review_model.dart';

class DriverProfileScreen extends ConsumerStatefulWidget {
  final UserModel providerUser;

  const DriverProfileScreen({super.key, required this.providerUser});

  @override
  ConsumerState<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends ConsumerState<DriverProfileScreen> {
  final PageController _vehiclePhotosController = PageController();
  int _activeVehiclePhotoIndex = 0;

  @override
  void dispose() {
    _vehiclePhotosController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No direct phone number listed for this driver.')),
      );
      return;
    }
    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not initiate call: $e')),
        );
      }
    }
  }

  Future<void> _startChat() async {
    final currentUser = ref.read(authStateProvider).user;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to message this driver.')),
      );
      return;
    }

    if (currentUser.uid == widget.providerUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot message yourself.')),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );

      final chatRepo = ref.read(chatRepositoryProvider);
      final chatId = await chatRepo.createChatRoom(
        myUid: currentUser.uid,
        myName: currentUser.displayName.isNotEmpty ? currentUser.displayName : 'Passenger',
        otherUid: widget.providerUser.uid,
        otherName: widget.providerUser.displayName.isNotEmpty ? widget.providerUser.displayName : 'Driver',
      );

      if (mounted) {
        Navigator.pop(context);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              otherUserId: widget.providerUser.uid,
              otherUserName: widget.providerUser.displayName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    }
  }

  void _hailRideNow() {
    final isBoda = widget.providerUser.providerProfile.professionTitle.toLowerCase().contains('boda') ||
        widget.providerUser.providerProfile.category.toLowerCase().contains('boda') ||
        widget.providerUser.providerProfile.bio.toLowerCase().contains('boda') ||
        widget.providerUser.providerProfile.bio.toLowerCase().contains('bike');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RideBookingScreen(
          vehicleType: isBoda ? 'motorbike' : 'cab',
        ),
      ),
    );
  }

  void _scheduleRideInAdvance({ListingModel? prefilledListing}) {
    final currentUser = ref.read(authStateProvider).user;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to schedule a ride.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookingCreationScreen(
          providerUser: widget.providerUser,
          prefilledListing: prefilledListing,
        ),
      ),
    );
  }

  void _addToCart(ListingModel listing) {
    ref.read(cartProvider.notifier).addItem(listing);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${listing.title} added to cart'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool isDark = true,
    Color? borderColor,
  }) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.75) : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor ?? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06)),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF0284C7), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.heading2.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textLightPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = widget.providerUser.providerProfile;
    final reviewsAsync = ref.watch(reviewProvider(widget.providerUser.uid));
    final listingsAsync = ref.watch(providerListingsProvider(widget.providerUser.uid));
    final hasImage = widget.providerUser.personalInfo.profileImageURL.isNotEmpty;

    final double hourlyRate = profile.hourlyRate > 0 ? profile.hourlyRate : 80.0;
    final String currency = profile.currency.isNotEmpty ? profile.currency : 'K';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Blue & cyan ambient glow
          Positioned(
            top: -40,
            right: -40,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0284C7).withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
          Positioned(
            top: 450,
            left: -60,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Driver Hero Sliver App Bar
              _buildDriverHeroAppBar(isDark, hasImage),

              // Main Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Quick Action Row (Direct Ride Hail, Chat, Call)
                      _buildQuickActionRow(isDark),
                      const SizedBox(height: 24),

                      // Vehicle Profile & Photos Carousel
                      _buildVehicleProfileCard(profile, isDark),
                      const SizedBox(height: 24),

                      // Safety Inspection & Verification Badges
                      _buildSafetyBadgesSection(profile, isDark),
                      const SizedBox(height: 24),

                      // Operational Coverage & Service Zones
                      _buildCoverageSection(isDark),
                      const SizedBox(height: 24),

                      // Transparent Fare Structure
                      _buildFareStructureSection(hourlyRate, currency, isDark),
                      const SizedBox(height: 24),

                      // Transport Packages & Bookable Routes
                      _buildTransportListings(listingsAsync, currency, isDark),
                      const SizedBox(height: 24),

                      // Passenger Testimonials & Reviews
                      _buildPassengerReviews(reviewsAsync, isDark),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Sticky Bottom Ride Hail CTA
          _buildStickyBottomBar(hourlyRate, currency, isDark),
        ],
      ),
    );
  }

  Widget _buildDriverHeroAppBar(bool isDark, bool hasImage) {
    final profile = widget.providerUser.providerProfile;
    final rating = profile.ratingAsProvider > 0 ? profile.ratingAsProvider : 4.96;
    final totalTrips = profile.totalJobsCompleted > 0 ? profile.totalJobsCompleted : 1240;

    return SliverAppBar(
      expandedHeight: 330,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.share_outlined, color: isDark ? Colors.white : Colors.black87),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Driver profile link copied to clipboard')),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [const Color(0xFF0F223D), const Color(0xFF0A0F1D)]
                      : [const Color(0xFFE0F2FE), const Color(0xFFF8FAFC)],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  Stack(
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF0284C7), width: 3.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: hasImage
                              ? HubbleImage(
                                  imagePath: widget.providerUser.personalInfo.profileImageURL,
                                  width: 104,
                                  height: 104,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                                  child: Center(
                                    child: Text(
                                      widget.providerUser.displayName.isNotEmpty
                                          ? widget.providerUser.displayName[0].toUpperCase()
                                          : 'D',
                                      style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0284C7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.local_taxi_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.providerUser.displayName,
                        style: AppTextStyles.heading1.copyWith(
                          fontSize: 22,
                          color: isDark ? Colors.white : AppColors.textLightPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, color: AppColors.primary, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.professionTitle.isNotEmpty
                        ? profile.professionTitle
                        : 'Verified Premium Cab & Transport Specialist',
                    style: const TextStyle(
                      color: Color(0xFF0284C7),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMetricBadge(Icons.star_rounded, '$rating Rating', Colors.amber, isDark),
                      const SizedBox(width: 8),
                      _buildMetricBadge(Icons.route_rounded, '$totalTrips+ Trips', AppColors.primary, isDark),
                      const SizedBox(width: 8),
                      _buildMetricBadge(Icons.timer_rounded, '99.4% On-Time', const Color(0xFF0284C7), isDark),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBadge(IconData icon, String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.textLightPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionRow(bool isDark) {
    final phone = widget.providerUser.personalInfo.phoneNumber;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: _hailRideNow,
                icon: const Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
                label: const Text('Direct Ride Hail', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: _startChat,
                icon: Icon(Icons.chat_bubble_outline_rounded, color: isDark ? Colors.white : const Color(0xFF0284C7), size: 18),
                label: Text('Chat', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isDark ? Colors.white30 : const Color(0xFF0284C7).withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            if (phone.isNotEmpty) ...[
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.phone_in_talk, color: AppColors.success),
                  onPressed: () => _makePhoneCall(phone),
                  tooltip: 'Call Driver',
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _scheduleRideInAdvance(),
            icon: Icon(Icons.calendar_month_outlined, color: isDark ? Colors.white70 : const Color(0xFF0284C7), size: 16),
            label: Text(
              'Schedule Trip or Charter in Advance',
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF0284C7),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleProfileCard(ProviderProfile profile, bool isDark) {
    final vehiclePhotos = profile.portfolioImages.isNotEmpty
        ? profile.portfolioImages
        : [
            'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?w=700&q=80',
            'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=700&q=80',
            'https://images.unsplash.com/photo-1550355291-bbee04a92027?w=700&q=80',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Vehicle Profile & Specifications', Icons.directions_car_filled_outlined, isDark),
        _buildGlassCard(
          isDark: isDark,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo carousel
              SizedBox(
                height: 180,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _vehiclePhotosController,
                      itemCount: vehiclePhotos.length,
                      onPageChanged: (idx) {
                        setState(() => _activeVehiclePhotoIndex = idx);
                      },
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: HubbleImage(
                            imagePath: vehiclePhotos[index],
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: AnimatedSmoothIndicator(
                          activeIndex: _activeVehiclePhotoIndex,
                          count: vehiclePhotos.length,
                          effect: WormEffect(
                            dotWidth: 6,
                            dotHeight: 6,
                            activeDotColor: Colors.white,
                            dotColor: Colors.white38,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Vehicle model & plate number
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Toyota Corolla Cross Hybrid (2023)',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Silver Metallic • Executive Sedan Class',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black45 : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? Colors.white24 : Colors.black26),
                    ),
                    child: Text(
                      'ABC 4829 ZM',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
              const SizedBox(height: 16),
              // Amenity Icons Wrap
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  _buildAmenityChip(Icons.people_outline, '4 Passengers', isDark),
                  _buildAmenityChip(Icons.ac_unit, 'Cold A/C', isDark),
                  _buildAmenityChip(Icons.luggage_outlined, '3 Large Bags', isDark),
                  _buildAmenityChip(Icons.cable_outlined, 'USB Charging', isDark),
                  _buildAmenityChip(Icons.music_note_outlined, 'Bluetooth Audio', isDark),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmenityChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF0284C7), size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyBadgesSection(ProviderProfile profile, bool isDark) {
    final safetyBadges = [
      {'title': 'Commercial Driver’s License (CDL) Class B', 'subtitle': 'Verified by National Road Safety Authority (RTSA)'},
      {'title': 'Annual Vehicle Roadworthiness Inspection', 'subtitle': 'Passed 150-Point Hubble Safety Inspection (2026)'},
      {'title': 'Comprehensive Passenger Liability Insurance', 'subtitle': 'Underwritten & Active Policy #PL-89210-ZM'},
      {'title': 'Dual HD Dashcam & GPS Live Telemetry', 'subtitle': 'Real-time emergency tracking enabled'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Safety Certifications & Verification', Icons.verified_user_outlined, isDark),
        _buildGlassCard(
          isDark: isDark,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: safetyBadges.length,
            separatorBuilder: (context, index) => Divider(
              color: isDark ? Colors.white12 : Colors.black12,
              height: 20,
            ),
            itemBuilder: (context, index) {
              final badge = safetyBadges[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          badge['title']!,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          badge['subtitle']!,
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCoverageSection(bool isDark) {
    final zones = [
      'KKIA International Airport',
      'Lusaka CBD & Longacres',
      'Woodlands & Kabulonga',
      'Roma & Olympia Metro',
      'Intercity Highway Charters',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Coverage Zones & Operational Hours', Icons.location_on_outlined, isDark),
        _buildGlassCard(
          isDark: isDark,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_filled, color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Available 24/7 for On-Demand & Scheduled Trips',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: zones.map((zone) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      zone,
                      style: const TextStyle(
                        color: Color(0xFF0284C7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFareStructureSection(double hourlyRate, String currency, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Transparent Fare Rates', Icons.receipt_long_outlined, isDark),
        _buildGlassCard(
          isDark: isDark,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildFareRow('Base Fare', '$currency 30.00', 'Includes first 2 KM ride', isDark),
              Divider(color: isDark ? Colors.white12 : Colors.black12, height: 20),
              _buildFareRow('Per-Kilometer Distance Rate', '$currency 12.00 / km', 'Standard metro transit rate', isDark),
              Divider(color: isDark ? Colors.white12 : Colors.black12, height: 20),
              _buildFareRow('Hourly Dedicated Chauffeur', '$currency ${hourlyRate.toStringAsFixed(0)} / hr', 'Chauffeur standby with unlimited city stops', isDark, isHighlight: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFareRow(String title, String price, String subtitle, bool isDark, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isHighlight ? const Color(0xFF0284C7) : (isDark ? Colors.white : Colors.black87),
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        Text(
          price,
          style: TextStyle(
            color: isHighlight ? const Color(0xFF0284C7) : AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildTransportListings(AsyncValue<List<ListingModel>> listingsAsync, String currency, bool isDark) {
    return listingsAsync.when(
      data: (listings) {
        if (listings.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Pre-Bookable Transport Packages', Icons.directions_bus_filled_outlined, isDark),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: listings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final listing = listings[index];
                final isProduct = listing.listingType == ListingType.product;

                return _buildGlassCard(
                  isDark: isDark,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      if (listing.images.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: HubbleImage(
                            imagePath: listing.images.first,
                            width: 65,
                            height: 65,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.local_taxi,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing.title,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$currency ${listing.price.toStringAsFixed(0)} ${listing.billingType == BillingType.hourly ? '/hr' : ''}',
                              style: const TextStyle(
                                color: Color(0xFF0284C7),
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isProduct)
                            IconButton(
                              icon: const Icon(Icons.add_shopping_cart, color: Color(0xFF0284C7), size: 20),
                              onPressed: () => _addToCart(listing),
                            ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ListingDetailScreen(listing: listing),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('View', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  Widget _buildPassengerReviews(AsyncValue<List<ReviewModel>> reviewsAsync, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Passenger Testimonials & Reviews', Icons.rate_review_outlined, isDark),
        reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return _buildGlassCard(
                isDark: isDark,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No reviews posted yet. Hail a ride with this driver to leave a review!',
                      style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
                    ),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final review = reviews[index];
                return _buildGlassCard(
                  isDark: isDark,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.2),
                                child: Text(
                                  review.clientName.isNotEmpty ? review.clientName[0].toUpperCase() : 'P',
                                  style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review.clientName,
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(review.createdAt),
                                    style: TextStyle(
                                      color: isDark ? Colors.white38 : Colors.black38,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          RatingBarIndicator(
                            rating: review.rating,
                            itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                            itemCount: 5,
                            itemSize: 14.0,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        review.text,
                        style: TextStyle(
                          color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black87,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7))),
          error: (e, st) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildStickyBottomBar(double hourlyRate, String currency, bool isDark) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0A0F1D).withValues(alpha: 0.88) : Colors.white.withValues(alpha: 0.92),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Base Fare',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '$currency 30.00',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.textLightPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _hailRideNow,
                      icon: const Icon(Icons.local_taxi_rounded, color: Colors.white, size: 18),
                      label: const Text(
                        'Hail Ride Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
