import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/marketplace_provider.dart';
import '../providers/search_provider.dart';
import '../providers/trending_categories_provider.dart';
import 'search_results_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/user_model.dart';
import 'map_screen.dart';
import '../../../profile/presentation/screens/public_profile_screen.dart';
import '../../domain/models/listing_model.dart';
import 'listing_detail_screen.dart';
import 'package:hubble/features/marketplace/presentation/screens/transportation/transportation_hub_screen.dart'
    as transportation;
import 'package:hubble/features/marketplace/presentation/screens/transportation/coach_list_screen.dart';
import 'cart_screen.dart';
import 'category_hub_screen.dart';
import 'categories/handyman_category_screen.dart';
import 'categories/beauty_category_screen.dart';
import 'categories/food_category_screen.dart';
import '../providers/cart_provider.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../../core/presentation/widgets/hubble_image.dart';
import '../../../../core/presentation/widgets/shimmer_loading.dart';
import '../../../../core/presentation/widgets/animated_empty_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HighlightItem {
  final String prompt;
  final String displayTitle;
  final List<Color> fallbackGradientColors;
  final String imageUrl;
  HighlightItem({
    required this.prompt,
    required this.displayTitle,
    required this.fallbackGradientColors,
    required this.imageUrl,
  });
}

class CategoryItem {
  final String title;
  final IconData icon;
  final Color color;
  final String description;

  CategoryItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
  });

  factory CategoryItem.fromTitle(String title) {
    IconData icon;
    Color color;
    String description;
    final lower = title.toLowerCase();

    if (lower.contains('transport') || lower.contains('deliver') || lower.contains('bus') || lower.contains('ride')) {
      icon = Icons.directions_bus_rounded;
      color = const Color(0xFF0284C7); // Sky 600
      description = 'Intercity Bus Tickets, Rides & Express Delivery';
    } else if (lower.contains('estate') || lower.contains('housing') || lower.contains('apart') || lower.contains('rent') || lower.contains('property')) {
      icon = Icons.apartment_rounded;
      color = const Color(0xFF059669); // Emerald 600
      description = 'Apartments, Houses, Offices & Student Hostels';
    } else if (lower.contains('plumb') || lower.contains('repair') || lower.contains('trades') || lower.contains('home')) {
      icon = Icons.home_repair_service_rounded;
      color = const Color(0xFFEA580C); // Orange 600
      description = 'Plumbing, Electrical, Carpentry & Home Repairs';
    } else if (lower.contains('tech') || lower.contains('software') || lower.contains('computer')) {
      icon = Icons.laptop_chromebook_rounded;
      color = const Color(0xFF2563EB); // Blue 600
      description = 'IT Support, Software Developers & Device Repairs';
    } else if (lower.contains('medic') || lower.contains('health')) {
      icon = Icons.health_and_safety_rounded;
      color = const Color(0xFF0D9488); // Teal 600
      description = 'Doctors, Nurses, Clinics & Medical Consultations';
    } else if (lower.contains('educat') || lower.contains('tutor') || lower.contains('school')) {
      icon = Icons.school_rounded;
      color = const Color(0xFF7C3AED); // Violet 600
      description = 'Private Tutors, Academic Courses & STEM Mentors';
    } else if (lower.contains('beauty') || lower.contains('well') || lower.contains('spa')) {
      icon = Icons.spa_rounded;
      color = const Color(0xFFDB2777); // Pink 600
      description = 'Salons, Barbers, Skincare & Wellness Therapies';
    } else if (lower.contains('retail') || lower.contains('shop') || lower.contains('cloth') || lower.contains('apparel')) {
      icon = Icons.shopping_bag_rounded;
      color = const Color(0xFF059669); // Emerald 600
      description = 'Fashion, Accessories & Local Storefront Products';
    } else if (lower.contains('electr') || lower.contains('gadget')) {
      icon = Icons.devices_rounded;
      color = const Color(0xFF4F46E5); // Indigo 600
      description = 'Smartphones, Laptops & Home Appliances';
    } else if (lower.contains('groc') || lower.contains('food')) {
      icon = Icons.restaurant_rounded;
      color = const Color(0xFFD97706); // Amber 600
      description = 'Fresh Groceries, Meals & Catering Services';
    } else if (lower.contains('legal') || lower.contains('gavel')) {
      icon = Icons.gavel_rounded;
      color = const Color(0xFF78350F); // Brown
      description = 'Attorneys, Legal Counsel & Contract Advisory';
    } else if (lower.contains('business') || lower.contains('consult')) {
      icon = Icons.business_center_rounded;
      color = const Color(0xFF0D9488); // Teal 600
      description = 'Accounting, Corporate Tax & Growth Advisory';
    } else if (lower.contains('event') || lower.contains('entertain')) {
      icon = Icons.festival_rounded;
      color = const Color(0xFFC026D3); // Fuchsia 600
      description = 'Event Planners, DJs, Sound & Catering Equipment';
    } else if (lower.contains('creative') || lower.contains('design') || lower.contains('photo')) {
      icon = Icons.brush_rounded;
      color = const Color(0xFF6366F1); // Indigo 500
      description = 'Logo Design, Branding, Video & Photography';
    } else {
      icon = Icons.grid_view_rounded;
      color = const Color(0xFF0284C7);
      description = 'Verified Professional Services & Storefront Items';
    }

    return CategoryItem(
      title: title,
      icon: icon,
      color: color,
      description: description,
    );
  }
}

class ExploreScreen extends ConsumerStatefulWidget {
  final bool animate;
  const ExploreScreen({super.key, this.animate = true});
  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  int _carouselIndex = 0;
  bool _showAllCategories = false;
  PageController? _carouselController;
  Timer? _carouselTimer;
  bool _isDisposed = false;
  int _selectedTab = 0; /* 0 = Services, 1 = Products */
  final List<HighlightItem> _highlights = [
    HighlightItem(
      prompt: 'a bus ticket...',
      displayTitle: 'Book Intercity Bus',
      fallbackGradientColors: [
        const Color(0xFF10B981),
        const Color(0xFF059669),
      ],
      imageUrl:
          'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=600&q=80',
    ),
    HighlightItem(
      prompt: 'a taxi...',
      displayTitle: 'Rides on Demand',
      fallbackGradientColors: [
        const Color(0xFFF59E0B),
        const Color(0xFFD97706),
      ],
      imageUrl:
          'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?auto=format&fit=crop&w=600&q=80',
    ),
    HighlightItem(
      prompt: 'a restaurant...',
      displayTitle: 'Top Rated Food',
      fallbackGradientColors: [
        const Color(0xFFEF4444),
        const Color(0xFFDC2626),
      ],
      imageUrl:
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=600&q=80',
    ),
    HighlightItem(
      prompt: 'a retail shop...',
      displayTitle: 'Local Shopping',
      fallbackGradientColors: [
        const Color(0xFF3B82F6),
        const Color(0xFF2563EB),
      ],
      imageUrl:
          'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=600&q=80',
    ),
    HighlightItem(
      prompt: 'a barber...',
      displayTitle: 'Expert Grooming',
      fallbackGradientColors: [
        const Color(0xFFEC4899),
        const Color(0xFFDB2777),
      ],
      imageUrl:
          'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?auto=format&fit=crop&w=600&q=80',
    ),
    HighlightItem(
      prompt: 'a mechanic...',
      displayTitle: 'Auto Repairs',
      fallbackGradientColors: [
        const Color(0xFF10B981),
        const Color(0xFF059669),
      ],
      imageUrl:
          'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?auto=format&fit=crop&w=600&q=80',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _carouselController = PageController(initialPage: 0);
    final isTest =
        (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'));
    if (widget.animate && !isTest) {
      _startCarouselTimer();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _carouselTimer?.cancel();
    _carouselController?.dispose();
    super.dispose();
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isDisposed || _carouselController == null) return;
      final nextPage = (_carouselIndex + 1) % _highlights.length;
      _carouselController!.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _showFilterBottomSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FilterBottomSheet(isDark: isDark);
      },
    );
  }

  Widget _buildTabSelector(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkCard : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedTab = 0;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 0
                      ? (isDark ? Colors.white : Colors.black)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Services',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _selectedTab == 0
                          ? (isDark ? Colors.black : Colors.white)
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedTab = 1;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 1
                      ? (isDark ? Colors.white : Colors.black)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Products',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _selectedTab == 1
                          ? (isDark ? Colors.black : Colors.white)
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformers(BuildContext context, bool isDark) {
    final businessType = _selectedTab == 0 ? 'individual' : 'shop';
    final topProvidersAsync = ref.watch(topProvidersProvider(businessType));
    
    final fallbackProviders = [
      UserModel(
        uid: 'dummy_1',
        email: 'kondwani.phiri@example.com',
        displayName: 'Kondwani Phiri',
        role: UserRole.provider,
        createdAt: DateTime.now(),
        personalInfo: PersonalInfo(
          firstName: 'Kondwani',
          lastName: 'Phiri',
          phoneNumber: '+260 977 101010',
          email: 'kondwani.phiri@example.com',
          isVerified: true,
          profileImageURL: 'https://images.unsplash.com/photo-1522529599102-193c0d76b5b6?auto=format&fit=crop&w=300&q=80',
        ),
        currentLocation: CurrentLocation(latitude: 0.0, longitude: 0.0, geohash: ''),
        clientProfile: ClientProfile(ratingAsClient: 5.0, totalBookingsMade: 0),
        providerProfile: ProviderProfile(
          isActive: true,
          professionTitle: 'Master Plumber',
          category: 'Home Repair',
          hourlyRate: 65.0,
          currency: 'ZMW',
          bio: 'Expert plumbing & pipe repair',
          ratingAsProvider: 4.8,
          totalJobsCompleted: 24,
          portfolioImages: [],
          businessType: 'individual',
          listingsCount: 2,
        ),
        financialLedger: FinancialLedger(
          currency: 'ZMW',
          availableBalance: 0.0,
          vaultSettings: VaultSettings(isAutoSaveEnabled: false, autoSavePercentage: 0.0, vaultBalance: 0.0),
          investmentPortfolio: InvestmentPortfolio(isActive: false, totalEstimatedValue: 0.0, assets: []),
        ),
      ),
      UserModel(
        uid: 'dummy_2',
        email: 'mutinta.mwale@example.com',
        displayName: 'Mutinta Mwale',
        role: UserRole.provider,
        createdAt: DateTime.now(),
        personalInfo: PersonalInfo(
          firstName: 'Mutinta',
          lastName: 'Mwale',
          phoneNumber: '+260 966 202020',
          email: 'mutinta.mwale@example.com',
          isVerified: true,
          profileImageURL: 'https://images.unsplash.com/photo-1589156280159-27698a70f29e?auto=format&fit=crop&w=300&q=80',
        ),
        currentLocation: CurrentLocation(latitude: 0.0, longitude: 0.0, geohash: ''),
        clientProfile: ClientProfile(ratingAsClient: 5.0, totalBookingsMade: 0),
        providerProfile: ProviderProfile(
          isActive: true,
          professionTitle: 'Hair Stylist',
          category: 'Beauty',
          hourlyRate: 45.0,
          currency: 'ZMW',
          bio: 'Modern hair styling & braids',
          ratingAsProvider: 4.9,
          totalJobsCompleted: 156,
          portfolioImages: [],
          businessType: 'salon',
          listingsCount: 1,
        ),
        financialLedger: FinancialLedger(
          currency: 'ZMW',
          availableBalance: 0.0,
          vaultSettings: VaultSettings(isAutoSaveEnabled: false, autoSavePercentage: 0.0, vaultBalance: 0.0),
          investmentPortfolio: InvestmentPortfolio(isActive: false, totalEstimatedValue: 0.0, assets: []),
        ),
      ),
      UserModel(
        uid: 'dummy_5',
        email: 'thandiwe.tembo@example.com',
        displayName: 'Thandiwe Tembo',
        role: UserRole.provider,
        createdAt: DateTime.now(),
        personalInfo: PersonalInfo(
          firstName: 'Thandiwe',
          lastName: 'Tembo',
          phoneNumber: '+260 967 505050',
          email: 'thandiwe.tembo@example.com',
          isVerified: true,
          profileImageURL: 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?auto=format&fit=crop&w=150&q=80',
        ),
        currentLocation: CurrentLocation(latitude: 0.0, longitude: 0.0, geohash: ''),
        clientProfile: ClientProfile(ratingAsClient: 5.0, totalBookingsMade: 0),
        providerProfile: ProviderProfile(
          isActive: true,
          professionTitle: 'IT Specialist',
          category: 'Electronics',
          hourlyRate: 55.0,
          currency: 'ZMW',
          bio: 'Laptop & device repairs',
          ratingAsProvider: 4.9,
          totalJobsCompleted: 112,
          portfolioImages: [],
          businessType: 'company',
          listingsCount: 2,
        ),
        financialLedger: FinancialLedger(
          currency: 'ZMW',
          availableBalance: 0.0,
          vaultSettings: VaultSettings(isAutoSaveEnabled: false, autoSavePercentage: 0.0, vaultBalance: 0.0),
          investmentPortfolio: InvestmentPortfolio(isActive: false, totalEstimatedValue: 0.0, assets: []),
        ),
      ),
    ];

    return topProvidersAsync.when(
      data: (providers) {
        final effectiveProviders = providers.isNotEmpty ? providers : fallbackProviders;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Top Rated Performers',
                    style: AppTextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.verified, color: AppColors.primary, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                scrollDirection: Axis.horizontal,
                itemCount: effectiveProviders.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final provider = effectiveProviders[index];
                  final profile = provider.providerProfile;
                  final imageUrl =
                      provider.personalInfo.profileImageURL.isNotEmpty
                      ? provider.personalInfo.profileImageURL
                      : 'https://images.unsplash.com/photo-1522529599102-193c0d76b5b6?auto=format&fit=crop&w=300&q=80';
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PublicProfileScreen(providerUser: provider),
                        ),
                      );
                    },
                    child: SizedBox(
                      width: 100,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 36,
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.1,
                              ),
                              child: HubbleImage(
                                imagePath: imageUrl,
                                width: 72,
                                height: 72,
                                borderRadius: BorderRadius.circular(36),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            provider.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                profile.ratingAsProvider > 0
                                    ? profile.ratingAsProvider.toStringAsFixed(1)
                                    : '4.9',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'Top Rated Performers',
              style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              scrollDirection: Axis.horizontal,
              itemCount: fallbackProviders.length,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final provider = fallbackProviders[index];
                return SizedBox(
                  width: 100,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        child: HubbleImage(
                          imagePath: provider.personalInfo.profileImageURL,
                          width: 72,
                          height: 72,
                          borderRadius: BorderRadius.circular(36),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  Widget _buildFeaturedServices(bool isDark) {
    return ref
        .watch(allListingsProvider)
        .when(
          data: (listings) {
            final services = listings
                .where((l) => l.listingType == ListingType.service)
                .toList();
            if (services.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Featured Services',
                    style: AppTextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return _buildServiceCard(context, service, isDark);
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: 2,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (_, _) => const ShimmerCard(width: 260, height: 180, borderRadius: 20),
            ),
          ),
          error: (err, st) => const SizedBox.shrink(),
        );
  }

  Widget _buildServiceCard(
    BuildContext context,
    ListingModel service,
    bool isDark,
  ) {
    final hasImage =
        service.images.isNotEmpty && service.images.first.isNotEmpty;
    final billingLabel = service.billingType == BillingType.hourly
        ? '/hr'
        : service.billingType == BillingType.monthly
        ? '/mo'
        : '';
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListingDetailScreen(listing: service),
          ),
        );
      },
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    hasImage
                        ? HubbleImage(
                            imagePath: service.images.first,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.teal.shade300,
                                  const Color(0xFF34D399),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(
                              Icons.handyman_outlined,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          service.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'by ${service.providerName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          'K ${service.price.toStringAsFixed(0)}$billingLabel',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.success,
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
    );
  }

  Widget _buildProductsGrid(bool isDark) {
    return ref
        .watch(allListingsProvider)
        .when(
          data: (listings) {
            final products = listings
                .where((l) => l.listingType == ListingType.product)
                .toList();
            if (products.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0, horizontal: 20.0),
                child: AnimatedEmptyState(
                  icon: Icons.storefront_outlined,
                  title: 'No Products Available',
                  subtitle: 'No items are listed in the shop yet. Stay tuned!',
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Trending Products',
                    style: AppTextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildProductCard(context, product, isDark);
                  },
                ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: ShimmerGrid(
              itemCount: 4,
              crossAxisCount: 2,
              childAspectRatio: 0.72,
            ),
          ),
          error: (err, stack) =>
              Center(child: Text('Error loading products: $err')),
        );
  }

  Widget _buildProductCard(
    BuildContext context,
    ListingModel product,
    bool isDark,
  ) {
    final hasImage =
        product.images.isNotEmpty && product.images.first.isNotEmpty;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListingDetailScreen(listing: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    hasImage
                        ? HubbleImage(
                            imagePath: product.images.first,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade300,
                                  Colors.indigo.shade400,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.stockCount > 0 ? 'In Stock' : 'Out of Stock',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.category,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'by ${product.providerName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'K ${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.success,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ListingDetailScreen(listing: product),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white : Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: isDark ? Colors.black : Colors.white,
                              size: 16,
                            ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text.rich(
          TextSpan(
            style: GoogleFonts.poppins(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            children: [
              const TextSpan(text: 'H', style: TextStyle(color: Color(0xFF009A44))),
              const TextSpan(text: 'u', style: TextStyle(color: Color(0xFF009A44))),
              const TextSpan(text: 'b', style: TextStyle(color: Color(0xFF009A44))),
              const TextSpan(text: 'b', style: TextStyle(color: Color(0xFFEF3340))),
              TextSpan(text: 'l', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              const TextSpan(text: 'e', style: TextStyle(color: Color(0xFFFF8200))),
            ],
          ),
        ),
        centerTitle: false,
        backgroundColor: isDark ? AppColors.bgDark : Colors.white,
        elevation: 0,
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final user = ref.watch(authStateProvider).user;
              final uid = user?.uid;
              final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
              if (uid == null || isTest) {
                return IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                );
              }
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('notifications')
                    .where('read', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data?.docs.length ?? 0;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsScreen(),
                            ),
                          );
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final cart = ref.watch(cartProvider);
              final itemCount = cart.items.fold(
                0,
                (total, item) => total + item.quantity,
              );
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shopping_cart_outlined,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    },
                  ),
                  if (itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$itemCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('explore_map_button'),
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapScreen()),
          );
        },
        backgroundColor: isDark ? Colors.white : Colors.black,
        foregroundColor: isDark ? Colors.black : Colors.white,
        elevation: 6,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.map, size: 20),
        label: const Text(
          'Map View',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: isDark ? AppColors.bgDarkCard : Colors.white,
          onRefresh: () async {
            ref.invalidate(allListingsProvider);
            ref.invalidate(
              trendingCategoriesProvider,
            ); /* We invalidate the individual and shop providers as well */
            ref.invalidate(topProvidersProvider('individual'));
            ref.invalidate(topProvidersProvider('shop'));
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                /* --- THE FLOATING SEARCH BAR --- */ Padding(
                  key: const Key('explore_search_bar_padding'),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SearchResultsScreen(initialQuery: ''),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.bgDarkCard : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.3 : 0.08,
                            ),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 18,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search,
                              color: Colors.grey,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AnimatedSearchBarText(
                                prompt: _highlights[_carouselIndex].prompt,
                                isDark: isDark,
                                animate: widget.animate,
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                _showFilterBottomSheet(context, isDark);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.tune,
                                  color: isDark ? Colors.white : Colors.black,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                /* --- THE SYNCED SLIDESHOW (Carousel) --- */ Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Trending on Hubble',
                    style: AppTextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      SizedBox(
                        key: const Key('explore_slideshow_card'),
                        height: 200,
                        child: PageView.builder(
                          controller: _carouselController,
                          onPageChanged: (index) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _carouselIndex = index;
                                });
                              }
                            });
                          },
                          itemCount: _highlights.length,
                          itemBuilder: (context, index) {
                            final item = _highlights[index];
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                if (item.displayTitle == 'Book Intercity Bus') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const CoachListScreen(),
                                    ),
                                  );
                                } else if (item.displayTitle == 'Rides on Demand') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const transportation.TransportationHubScreen(),
                                    ),
                                  );
                                } else if (item.displayTitle == 'Top Rated Food') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const FoodCategoryScreen(),
                                    ),
                                  );
                                } else if (item.displayTitle == 'Local Shopping') {
                                  CategoryHubScreen.open(context, categoryTitle: 'Retail & Shopping');
                                } else if (item.displayTitle == 'Expert Grooming') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const BeautyCategoryScreen(),
                                    ),
                                  );
                                } else if (item.displayTitle == 'Auto Repairs') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const HandymanCategoryScreen(),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  gradient: LinearGradient(
                                    colors: item.fallbackGradientColors,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    /* Live Background Image */ ClipRRect(
                                      borderRadius: BorderRadius.circular(25),
                                      child: HubbleImage(
                                        imagePath: item.imageUrl,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    /* Overlay Dark Gradient Scrim */ Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withValues(
                                                alpha: 0.7,
                                              ),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                      ),
                                    ),
                                    /* Content Text */ Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Align(
                                        alignment: Alignment.bottomLeft,
                                        child: Text(
                                          item.displayTitle,
                                          style: AppTextStyles.heading1
                                              .copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      /* Page Indicators */ Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_highlights.length, (index) {
                          final isSelected = index == _carouselIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            height: 8,
                            width: isSelected ? 24 : 8,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                /* --- TAB SELECTOR --- */ _buildTabSelector(isDark),
                const SizedBox(height: 24),
                _buildTopPerformers(context, isDark),
                const SizedBox(height: 24),
                if (_selectedTab == 0) ...[
                  /* --- CATEGORIES SECTION --- */ Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      'Explore Categories',
                      style: AppTextStyles.heading2.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Consumer(
                      builder: (context, ref, child) {
                        final categoriesAsync = ref.watch(
                          trendingCategoriesProvider,
                        );
                        return categoriesAsync.when(
                          data: (allCategories) {
                            final categories = _showAllCategories
                                ? allCategories
                                : allCategories.take(6).toList();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: 1.0,
                                      ),
                                  itemCount: categories.length,
                                  itemBuilder: (context, index) {
                                    final catTitle = categories[index];
                                    final catItem = CategoryItem.fromTitle(
                                      catTitle,
                                    );
                                    return _CategoryTile(
                                      key: Key(
                                        'category_${catItem.title.toLowerCase()}',
                                      ),
                                      category: catItem,
                                      onTap: () {
                                        CategoryHubScreen.open(
                                          context,
                                          categoryTitle: catItem.title,
                                          icon: catItem.icon,
                                          themeColor: catItem.color,
                                          description: catItem.description,
                                        );
                                      },
                                    );
                                  },
                                ),
                                if (allCategories.length > 6) ...[
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      setState(() {
                                        _showAllCategories =
                                            !_showAllCategories;
                                      });
                                    },
                                    child: Text(
                                      _showAllCategories
                                          ? 'View Less'
                                          : 'View More Categories',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                          loading: () => const ShimmerGrid(
                            itemCount: 6,
                            crossAxisCount: 3,
                            childAspectRatio: 1.0,
                            cardBorderRadius: 16,
                          ),
                          error: (err, st) {
                            debugPrint('Trending categories error: $err');
                            return const SizedBox.shrink();
                          },
                        );
                      },
                    ),
                  ),
                  _buildFeaturedServices(isDark),
                  const SizedBox(height: 48),
                ] else ...[
                  /* --- PRODUCTS SECTION --- */ _buildProductsGrid(isDark),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryItem category;
  final VoidCallback onTap;
  const _CategoryTile({super.key, required this.category, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: category.color.withValues(alpha: 0.12),
                ),
                child: Icon(category.icon, color: category.color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                category.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textDarkPrimary
                      : AppColors.textLightPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedSearchBarText extends StatefulWidget {
  final String prompt;
  final bool isDark;
  final bool animate;
  const AnimatedSearchBarText({
    super.key,
    required this.prompt,
    required this.isDark,
    required this.animate,
  });
  @override
  State<AnimatedSearchBarText> createState() => _AnimatedSearchBarTextState();
}

class _AnimatedSearchBarTextState extends State<AnimatedSearchBarText> {
  String _animatedPlaceholder = '';
  int _animationId = 0;
  @override
  void initState() {
    super.initState();
    final isTest =
        (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'));
    if (widget.animate && !isTest) {
      _typeText(widget.prompt, ++_animationId);
    } else {
      _animatedPlaceholder = widget.prompt;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedSearchBarText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.prompt != oldWidget.prompt) {
      final isTest =
          (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'));
      if (widget.animate && !isTest) {
        _typeText(widget.prompt, ++_animationId);
      } else {
        setState(() {
          _animatedPlaceholder = widget.prompt;
        });
      }
    }
  }

  Future<void> _typeText(String text, int id) async {
    if (!mounted) return;
    setState(() => _animatedPlaceholder = '');
    await Future.delayed(const Duration(milliseconds: 300));
    for (int i = 0; i <= text.length; i++) {
      if (id != _animationId || !mounted) return;
      setState(() {
        _animatedPlaceholder = text.substring(0, i);
      });
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'Search for $_animatedPlaceholder',
      style: TextStyle(
        color: widget.isDark ? Colors.white54 : Colors.black54,
        fontSize: 16,
      ),
    );
  }
}

class FilterBottomSheet extends ConsumerStatefulWidget {
  final bool isDark;
  const FilterBottomSheet({super.key, required this.isDark});
  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late double _minPrice;
  late double _maxPrice;
  late double _maxDistance;
  late double _minRating;
  @override
  void initState() {
    super.initState();
    final currentFilters = ref.read(searchFiltersProvider);
    _minPrice = currentFilters.minPrice;
    _maxPrice = currentFilters.maxPrice;
    _maxDistance = currentFilters.maxDistance;
    _minRating = currentFilters.minRating;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.bgDarkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: AppTextStyles.heading2.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Price Range (K ${_minPrice.toStringAsFixed(0)} - K ${_maxPrice.toStringAsFixed(0)})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            min: 0,
            max: 10000,
            divisions: 100,
            activeColor: AppColors.primary,
            labels: RangeLabels(
              'K ${_minPrice.toStringAsFixed(0)}',
              'K ${_maxPrice.toStringAsFixed(0)}',
            ),
            onChanged: (values) {
              setState(() {
                _minPrice = values.start;
                _maxPrice = values.end;
              });
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Maximum Distance (${_maxDistance.toStringAsFixed(0)} km)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _maxDistance,
            min: 1,
            max: 100,
            divisions: 99,
            activeColor: AppColors.primary,
            label: '${_maxDistance.toStringAsFixed(0)} km',
            onChanged: (value) {
              setState(() {
                _maxDistance = value;
              });
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Minimum Rating (${_minRating.toStringAsFixed(1)} stars)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _minRating,
            min: 0,
            max: 5,
            divisions: 10,
            activeColor: AppColors.primary,
            label: '${_minRating.toStringAsFixed(1)} stars',
            onChanged: (value) {
              setState(() {
                _minRating = value;
              });
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                ref
                    .read(searchFiltersProvider.notifier)
                    .updateFilters(
                      SearchFilters(
                        minPrice: _minPrice,
                        maxPrice: _maxPrice,
                        maxDistance: _maxDistance,
                        minRating: _minRating,
                      ),
                    );
                Navigator.pop(context);
              },
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
