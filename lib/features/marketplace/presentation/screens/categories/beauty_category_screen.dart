import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/presentation/widgets/hubble_image.dart';
import '../../../../../core/presentation/widgets/shimmer_loading.dart';
import '../../../../../core/presentation/widgets/animated_empty_state.dart';
import '../../../domain/models/listing_model.dart';
import '../../providers/marketplace_provider.dart';
import '../listing_detail_screen.dart';

class BeautyServiceItem {
  final String id;
  final String title;
  final String salonOrStylistName;
  final String avatarUrl;
  final String imageUrl;
  final String category; // Haircuts, Braiding, Spa, Nails, Makeup, Skincare, Barbering
  final double price;
  final int durationMinutes;
  final bool offersHomeService;
  final bool offersSalonVisit;
  final double rating;
  final int reviewsCount;
  final String location;
  final List<String> availableSlots;
  final String description;

  const BeautyServiceItem({
    required this.id,
    required this.title,
    required this.salonOrStylistName,
    required this.avatarUrl,
    required this.imageUrl,
    required this.category,
    required this.price,
    required this.durationMinutes,
    required this.offersHomeService,
    required this.offersSalonVisit,
    required this.rating,
    required this.reviewsCount,
    required this.location,
    required this.availableSlots,
    required this.description,
  });
}

class BeautyCategoryScreen extends ConsumerStatefulWidget {
  const BeautyCategoryScreen({super.key});

  @override
  ConsumerState<BeautyCategoryScreen> createState() => _BeautyCategoryScreenState();
}

class _BeautyCategoryScreenState extends ConsumerState<BeautyCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedMenu = 'All Services';
  String _selectedLocationType = 'All Locations'; // All Locations, Home Service Only, Salon Visit Only
  String _selectedDuration = 'All Durations'; // All Durations, 30 mins, 45 mins, 60 mins, 90+ mins

  final List<String> _serviceMenu = [
    'All Services',
    'Braiding & Wigs',
    'Haircuts & Styling',
    'Spa & Massage',
    'Nails & Gel',
    'Makeup & Glam',
    'Skincare & Facials',
    'Barbering',
  ];

  final List<String> _durationChips = [
    'All Durations',
    '30 mins',
    '45 mins',
    '60 mins',
    '90+ mins',
  ];

  final List<BeautyServiceItem> _mockBeautyServices = const [
    BeautyServiceItem(
      id: 'beauty_1',
      title: 'Knotless Box Braids & Scalp Treatment',
      salonOrStylistName: 'Mutinta Mwale Stylist',
      avatarUrl: 'https://images.unsplash.com/photo-1589156280159-27698a70f29e?fit=crop&w=300&q=80',
      imageUrl: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?fit=crop&w=600&q=80',
      category: 'Braiding & Wigs',
      price: 280.0,
      durationMinutes: 90,
      offersHomeService: true,
      offersSalonVisit: true,
      rating: 4.95,
      reviewsCount: 156,
      location: 'Woodlands, Lusaka',
      availableSlots: ['Today 11:00 AM', 'Today 02:30 PM', 'Tomorrow 09:30 AM', 'Tomorrow 01:00 PM'],
      description: 'Clean, painless knotless braids using premium extensions. Includes relaxing peppermint scalp cleanse.',
    ),
    BeautyServiceItem(
      id: 'beauty_2',
      title: 'Deep Tissue Aromatherapy Full Body Massage',
      salonOrStylistName: 'Serene Oasis Wellness & Spa',
      avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?fit=crop&w=300&q=80',
      imageUrl: 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?fit=crop&w=600&q=80',
      category: 'Spa & Massage',
      price: 350.0,
      durationMinutes: 60,
      offersHomeService: true,
      offersSalonVisit: true,
      rating: 4.9,
      reviewsCount: 88,
      location: 'Kabulonga, Lusaka',
      availableSlots: ['Today 01:00 PM', 'Today 03:30 PM', 'Tomorrow 10:00 AM'],
      description: 'Soothing organic essential oils relieve tension, stress, and muscle soreness with certified therapists.',
    ),
    BeautyServiceItem(
      id: 'beauty_3',
      title: 'Luxury Acrylic Overlay & French Gel Pedicure',
      salonOrStylistName: 'Glamour Nails Studio',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?fit=crop&w=300&q=80',
      imageUrl: 'https://images.unsplash.com/photo-1632345031435-8727f6897d53?fit=crop&w=600&q=80',
      category: 'Nails & Gel',
      price: 220.0,
      durationMinutes: 45,
      offersHomeService: false,
      offersSalonVisit: true,
      rating: 4.85,
      reviewsCount: 114,
      location: 'Rhodespark, Lusaka',
      availableSlots: ['Today 10:00 AM', 'Today 12:00 PM', 'Today 04:00 PM'],
      description: 'Long-lasting acrylic overlay, custom chrome nail art, cuticle care, and nourishing foot scrub.',
    ),
    BeautyServiceItem(
      id: 'beauty_4',
      title: 'Bridal & Editorial HD Glam Makeup',
      salonOrStylistName: 'Thandiwe Beauty Artistry',
      avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?fit=crop&w=300&q=80',
      imageUrl: 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?fit=crop&w=600&q=80',
      category: 'Makeup & Glam',
      price: 320.0,
      durationMinutes: 60,
      offersHomeService: true,
      offersSalonVisit: true,
      rating: 5.0,
      reviewsCount: 62,
      location: 'Roma, Lusaka',
      availableSlots: ['Tomorrow 08:00 AM', 'Tomorrow 11:30 AM', 'Tomorrow 03:00 PM'],
      description: 'Flawless camera-ready makeup, luxury 3D mink lashes, contouring, and setting spray lasting 16+ hours.',
    ),
    BeautyServiceItem(
      id: 'beauty_5',
      title: 'Hydrating Glow Facial & Blackhead Extraction',
      salonOrStylistName: 'Radiant Skin Clinic',
      avatarUrl: 'https://images.unsplash.com/photo-1567532939604-b6b5b0db2604?fit=crop&w=300&q=80',
      imageUrl: 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?fit=crop&w=600&q=80',
      category: 'Skincare & Facials',
      price: 290.0,
      durationMinutes: 45,
      offersHomeService: false,
      offersSalonVisit: true,
      rating: 4.8,
      reviewsCount: 75,
      location: 'Foxdale Court, Lusaka',
      availableSlots: ['Today 02:00 PM', 'Tomorrow 01:30 PM'],
      description: 'Deep pore steaming, ultrasonic exfoliation, hyaluronic acid infusion, and high frequency acne treatment.',
    ),
    BeautyServiceItem(
      id: 'beauty_6',
      title: 'Executive Fade Haircut, Beard Sculpt & Hot Towel',
      salonOrStylistName: 'Gentlemen\'s Club Barbershop',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fit=crop&w=300&q=80',
      imageUrl: 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?fit=crop&w=600&q=80',
      category: 'Barbering',
      price: 150.0,
      durationMinutes: 30,
      offersHomeService: true,
      offersSalonVisit: true,
      rating: 4.95,
      reviewsCount: 210,
      location: 'Lusaka CBD',
      availableSlots: ['Today 11:30 AM', 'Today 01:00 PM', 'Today 04:30 PM', 'Today 06:00 PM'],
      description: 'Razor sharp skin fades, beard trim with conditioning butter, and relaxing eucalyptus hot towel treatment.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSlotBookingSheet(BuildContext context, BeautyServiceItem service, String? preselectedSlot) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BeautySlotBookingSheet(service: service, preselectedSlot: preselectedSlot),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    const pinkTheme = Color(0xFFDB2777); // Pink 600

    final allListingsAsync = ref.watch(allListingsProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Beauty & Wellness Hub',
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Hero Hub Banner ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDB2777), Color(0xFFBE185D), Color(0xFF9D174D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDB2777).withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.spa_rounded, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Grooming, Spas & Salons',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Book in-salon visits or luxury home service',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 2. Location Toggle (Home Service vs Salon Visit) ───────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _buildLocationTab('All Locations', '✨ All', isDark),
                      _buildLocationTab('Home Service Only', '🏠 Home Service', isDark),
                      _buildLocationTab('Salon Visit Only', '💈 Salon Visit', isDark),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── 3. Search Bar ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Search braids, massage, haircut, nails...',
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: pinkTheme),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: cardColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── 4. Service Menu Chips (Horizontal) ─────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: _serviceMenu.map((menu) {
                    final isSel = _selectedMenu == menu;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedMenu = menu);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? pinkTheme : cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSel ? pinkTheme : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Text(
                          menu,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              // ── 5. Duration Chips ──────────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: _durationChips.map((dur) {
                    final isSel = _selectedDuration == dur;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedDuration = dur);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? pinkTheme.withValues(alpha: 0.15) : cardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSel ? pinkTheme : (isDark ? Colors.white10 : Colors.black12),
                            width: isSel ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: isSel ? pinkTheme : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dur,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel ? pinkTheme : (isDark ? Colors.white60 : Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // ── 6. Beauty Services Feed ────────────────────────────────────
              allListingsAsync.when(
                data: (listings) {
                  // Filter live listings
                  final beautyListings = listings.where((l) {
                    final cat = l.category.toLowerCase();
                    return cat.contains('beauty') || cat.contains('spa') || cat.contains('hair') || cat.contains('salon') || cat.contains('wellness');
                  }).toList();

                  // Filter mock beauty services
                  final filteredServices = _mockBeautyServices.where((s) {
                    if (_selectedMenu != 'All Services' && !s.category.toLowerCase().contains(_selectedMenu.toLowerCase())) {
                      return false;
                    }
                    if (_selectedLocationType == 'Home Service Only' && !s.offersHomeService) return false;
                    if (_selectedLocationType == 'Salon Visit Only' && !s.offersSalonVisit) return false;

                    if (_selectedDuration == '30 mins' && s.durationMinutes > 30) return false;
                    if (_selectedDuration == '45 mins' && s.durationMinutes != 45) return false;
                    if (_selectedDuration == '60 mins' && s.durationMinutes != 60) return false;
                    if (_selectedDuration == '90+ mins' && s.durationMinutes < 90) return false;

                    if (_searchQuery.isNotEmpty) {
                      final matchTitle = s.title.toLowerCase().contains(_searchQuery);
                      final matchSalon = s.salonOrStylistName.toLowerCase().contains(_searchQuery);
                      final matchDesc = s.description.toLowerCase().contains(_searchQuery);
                      if (!matchTitle && !matchSalon && !matchDesc) return false;
                    }
                    return true;
                  }).toList();

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Available Services (${filteredServices.length + beautyListings.length})',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const Text(
                              'Instant Slot Booking',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFDB2777),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Live marketplace listings
                        if (beautyListings.isNotEmpty) ...[
                          ...beautyListings.map((l) => _buildLiveListingCard(context, l, isDark, cardColor, pinkTheme)),
                          const SizedBox(height: 8),
                        ],

                        if (filteredServices.isEmpty && beautyListings.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: AnimatedEmptyState(
                              icon: Icons.spa_outlined,
                              title: 'No Beauty Services Match Filters',
                              subtitle: 'Try changing your service menu or duration filters.',
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredServices.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final service = filteredServices[index];
                              return _buildBeautyCard(context, service, isDark, cardColor, pinkTheme);
                            },
                          ),
                      ],
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: ShimmerListTile(),
                ),
                error: (e, st) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Error loading beauty services: $e'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationTab(String type, String label, bool isDark) {
    final isSel = _selectedLocationType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedLocationType = type);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFFDB2777) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSel ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBeautyCard(
    BuildContext context,
    BeautyServiceItem service,
    bool isDark,
    Color cardColor,
    Color pinkTheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Banner with Location badge & Duration chip
            SizedBox(
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  HubbleImage(imagePath: service.imageUrl, fit: BoxFit.cover),
                  // Dark gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Category tag
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        service.category,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  // Duration chip
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: pinkTheme,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '⏱️ ${service.durationMinutes} mins',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  // Service format badge (Home vs Salon)
                  Positioned(
                    bottom: 10,
                    left: 12,
                    child: Row(
                      children: [
                        if (service.offersHomeService)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('🏠 Home Service', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        if (service.offersSalonVisit)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('💈 Salon Visit', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          service.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'K ${service.price.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        service.salonOrStylistName,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        '${service.rating} (${service.reviewsCount})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    service.description,
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),

                  // Slot Preview Chips
                  const Text('Available Slots Today / Tomorrow:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: service.availableSlots.map((slot) {
                        return GestureDetector(
                          onTap: () => _openSlotBookingSheet(context, service, slot),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: pinkTheme.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: pinkTheme.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bolt_rounded, size: 12, color: Color(0xFFDB2777)),
                                const SizedBox(width: 3),
                                Text(
                                  slot,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDB2777)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Direct Book CTA
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openSlotBookingSheet(context, service, null),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pinkTheme,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.calendar_month_rounded, size: 16),
                      label: const Text('Book Appointment Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

  Widget _buildLiveListingCard(
    BuildContext context,
    ListingModel listing,
    bool isDark,
    Color cardColor,
    Color pinkTheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pinkTheme.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 65,
                  height: 65,
                  child: listing.images.isNotEmpty && listing.images.first.isNotEmpty
                      ? HubbleImage(imagePath: listing.images.first, fit: BoxFit.cover)
                      : Container(
                          color: pinkTheme.withValues(alpha: 0.15),
                          child: Icon(Icons.spa_rounded, color: pinkTheme, size: 30),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text('by ${listing.providerName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      'K ${listing.price.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: listing)));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pinkTheme,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.calendar_month_rounded, size: 16),
                  label: const Text('Book Appointment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BeautySlotBookingSheet extends StatefulWidget {
  final BeautyServiceItem service;
  final String? preselectedSlot;

  const _BeautySlotBookingSheet({
    required this.service,
    this.preselectedSlot,
  });

  @override
  State<_BeautySlotBookingSheet> createState() => _BeautySlotBookingSheetState();
}

class _BeautySlotBookingSheetState extends State<_BeautySlotBookingSheet> {
  late String _chosenSlot;
  late String _chosenLocation;
  final TextEditingController _notesController = TextEditingController();
  bool _isReserving = false;

  @override
  void initState() {
    super.initState();
    _chosenSlot = widget.preselectedSlot ?? widget.service.availableSlots.first;
    _chosenLocation = widget.service.offersHomeService ? 'Home Service' : 'Salon Visit';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const pinkTheme = Color(0xFFDB2777);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: pinkTheme.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.spa_rounded, color: pinkTheme, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.service.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'by ${widget.service.salonOrStylistName} • ${widget.service.durationMinutes} mins',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location preference
            const Text('Appointment Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                if (widget.service.offersHomeService)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _chosenLocation = 'Home Service'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _chosenLocation == 'Home Service' ? pinkTheme : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: pinkTheme),
                        ),
                        child: Center(
                          child: Text(
                            '🏠 Home Service',
                            style: TextStyle(
                              color: _chosenLocation == 'Home Service' ? Colors.white : pinkTheme,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (widget.service.offersHomeService && widget.service.offersSalonVisit) const SizedBox(width: 10),
                if (widget.service.offersSalonVisit)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _chosenLocation = 'Salon Visit'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _chosenLocation == 'Salon Visit' ? pinkTheme : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: pinkTheme),
                        ),
                        child: Center(
                          child: Text(
                            '💈 Salon Visit',
                            style: TextStyle(
                              color: _chosenLocation == 'Salon Visit' ? Colors.white : pinkTheme,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),
            const Text('Select Time Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.service.availableSlots.map((slot) {
                final isSel = _chosenSlot == slot;
                return ChoiceChip(
                  label: Text(slot, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.w500)),
                  selected: isSel,
                  selectedColor: pinkTheme,
                  labelStyle: TextStyle(color: isSel ? Colors.white : null),
                  onSelected: (val) => setState(() => _chosenSlot = slot),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            const Text('Special Requests / Hair or Skin Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'e.g. Sensitive skin, bringing own wig, medium pressure...',
                hintStyle: const TextStyle(fontSize: 12),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isReserving
                    ? null
                    : () async {
                        final nav = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        setState(() => _isReserving = true);
                        await Future.delayed(const Duration(milliseconds: 600));
                        if (!mounted) return;
                        setState(() => _isReserving = false);
                        nav.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF10B981),
                            content: Text('Appointment reserved for $_chosenSlot ($_chosenLocation)!'),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: pinkTheme,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isReserving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Confirm Appointment (K ${widget.service.price.toStringAsFixed(0)})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
