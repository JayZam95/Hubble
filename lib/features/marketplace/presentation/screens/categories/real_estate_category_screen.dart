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

class PropertyListingItem {
  final String id;
  final String title;
  final String agentOrLandlordName;
  final String agentPhone;
  final String imageUrl;
  final List<String> galleryImages;
  final String propertyType; // Apartments, Standalone Houses, Commercial Spaces, Student Hostels, Plots
  final int bedrooms;
  final int bathrooms;
  final double monthlyRent;
  final String furnishedStatus; // Fully Furnished, Semi-Furnished, Unfurnished
  final int squareMeters;
  final String neighborhood;
  final String city;
  final bool isVerifiedAgent;
  final List<String> amenities; // Water Tank, Backup Solar, 24/7 Security, Paved Yard, Swimming Pool
  final String description;

  const PropertyListingItem({
    required this.id,
    required this.title,
    required this.agentOrLandlordName,
    required this.agentPhone,
    required this.imageUrl,
    required this.galleryImages,
    required this.propertyType,
    required this.bedrooms,
    required this.bathrooms,
    required this.monthlyRent,
    required this.furnishedStatus,
    required this.squareMeters,
    required this.neighborhood,
    required this.city,
    required this.isVerifiedAgent,
    required this.amenities,
    required this.description,
  });
}

class RealEstateCategoryScreen extends ConsumerStatefulWidget {
  const RealEstateCategoryScreen({super.key});

  @override
  ConsumerState<RealEstateCategoryScreen> createState() => _RealEstateCategoryScreenState();
}

class _RealEstateCategoryScreenState extends ConsumerState<RealEstateCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedPropertyType = 'All Types';
  String _selectedBedrooms = 'Any Beds';
  String _selectedFurnished = 'All'; // All, Fully Furnished, Semi-Furnished, Unfurnished
  String _selectedRentRange = 'All Prices';

  final List<String> _propertyTypes = [
    'All Types',
    'Apartments',
    'Standalone Houses',
    'Commercial Spaces',
    'Student Hostels',
    'Plots & Land',
  ];

  final List<String> _bedroomFilters = [
    'Any Beds',
    '1 Bed',
    '2 Beds',
    '3 Beds',
    '4+ Beds',
  ];

  final List<String> _furnishedFilters = [
    'All',
    'Fully Furnished',
    'Semi-Furnished',
    'Unfurnished',
  ];

  final List<String> _rentRanges = [
    'All Prices',
    'Under K 4,000/mo',
    'K 4,000 - K 9,000/mo',
    'K 9,000 - K 18,000/mo',
    'K 18,000+/mo',
  ];

  final List<PropertyListingItem> _mockProperties = const [
    PropertyListingItem(
      id: 'prop_1',
      title: 'Modern 3-Bedroom Executive Master Self-Contained Apartment',
      agentOrLandlordName: 'PrimeGate Realty Lusaka',
      agentPhone: '+260 977 888111',
      imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?fit=crop&w=600&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?fit=crop&w=600&q=80',
      ],
      propertyType: 'Apartments',
      bedrooms: 3,
      bathrooms: 2,
      monthlyRent: 8500.0,
      furnishedStatus: 'Fully Furnished',
      squareMeters: 165,
      neighborhood: 'Kabulonga',
      city: 'Lusaka',
      isVerifiedAgent: true,
      amenities: ['Solar Inverter Backup', 'Borehole Water', '24/7 Security Guard', 'Swimming Pool', 'Paved Yard'],
      description: 'Stunning luxury 3-bed apartment in secure gated complex. Fitted kitchen with granite counters, air conditioning in all rooms, and private balcony.',
    ),
    PropertyListingItem(
      id: 'prop_2',
      title: 'Cozy 2-Bedroom Semi-Detached Flat with Private Garden',
      agentOrLandlordName: 'Kondwani Estates',
      agentPhone: '+260 966 555222',
      imageUrl: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?fit=crop&w=600&q=80',
      galleryImages: ['https://images.unsplash.com/photo-1512917774080-9991f1c4c750?fit=crop&w=600&q=80'],
      propertyType: 'Apartments',
      bedrooms: 2,
      bathrooms: 1,
      monthlyRent: 4500.0,
      furnishedStatus: 'Semi-Furnished',
      squareMeters: 95,
      neighborhood: 'Woodlands Extension',
      city: 'Lusaka',
      isVerifiedAgent: true,
      amenities: ['Motorized Gate', 'Borehole Water', 'CCTV', 'Carport'],
      description: 'Neat and secure flat close to Woodlands Shopping Mall. Built-in wardrobes, tiled floors, reliable water, and quiet neighborhood.',
    ),
    PropertyListingItem(
      id: 'prop_3',
      title: '4-Bedroom Standalone Family Residence with Guest Cottage',
      agentOrLandlordName: 'Heritage Properties Zambia',
      agentPhone: '+260 955 333444',
      imageUrl: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?fit=crop&w=600&q=80',
      galleryImages: ['https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?fit=crop&w=600&q=80'],
      propertyType: 'Standalone Houses',
      bedrooms: 4,
      bathrooms: 3,
      monthlyRent: 16000.0,
      furnishedStatus: 'Unfurnished',
      squareMeters: 320,
      neighborhood: 'Rhodespark',
      city: 'Lusaka',
      isVerifiedAgent: true,
      amenities: ['Large Green Lawn', 'Electric Fence', 'Double Garage', 'Staff Quarters', 'Solar Geysers'],
      description: 'Spacious high-ceiling family home on 1-acre plot in diplomatic area. Two en-suite bedrooms, study room, expansive veranda.',
    ),
    PropertyListingItem(
      id: 'prop_4',
      title: 'Open-Plan Commercial Office Space (Ground Floor)',
      agentOrLandlordName: 'Lusaka Corporate Realty',
      agentPhone: '+260 978 222111',
      imageUrl: 'https://images.unsplash.com/photo-1497366216548-37526070297c?fit=crop&w=600&q=80',
      galleryImages: ['https://images.unsplash.com/photo-1497366216548-37526070297c?fit=crop&w=600&q=80'],
      propertyType: 'Commercial Spaces',
      bedrooms: 0,
      bathrooms: 2,
      monthlyRent: 12000.0,
      furnishedStatus: 'Semi-Furnished',
      squareMeters: 140,
      neighborhood: 'Lusaka CBD / Cairo Road',
      city: 'Lusaka',
      isVerifiedAgent: true,
      amenities: ['High Speed Fiber Optic', 'Backup Generator', 'Dedicated Parking', 'Access Control'],
      description: 'Prime commercial office suite ideal for financial consultancy, law firm, or tech startup with high foot traffic.',
    ),
    PropertyListingItem(
      id: 'prop_5',
      title: 'Student Boarding House Studio Room (Near UNZA Great East)',
      agentOrLandlordName: 'Varsity Hostels Direct',
      agentPhone: '+260 971 444333',
      imageUrl: 'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?fit=crop&w=600&q=80',
      galleryImages: ['https://images.unsplash.com/photo-1555854877-bab0e564b8d5?fit=crop&w=600&q=80'],
      propertyType: 'Student Hostels',
      bedrooms: 1,
      bathrooms: 1,
      monthlyRent: 2200.0,
      furnishedStatus: 'Fully Furnished',
      squareMeters: 30,
      neighborhood: 'Handsworth / Kalundu',
      city: 'Lusaka',
      isVerifiedAgent: false,
      amenities: ['Unlimited Wi-Fi', 'Study Desk & Bed', 'Shared Kitchenette', '24/7 Security Guard'],
      description: 'Safe and quiet student studio room within 5 mins walking distance to UNZA main campus. Water and electricity included.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openScheduleViewing(BuildContext context, PropertyListingItem property) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ScheduleViewingSheet(property: property),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    const emeraldTheme = Color(0xFF059669); // Emerald 600

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
          'Real Estate & Housing Hub',
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
              // ── 1. Hero Banner ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF065F46), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withValues(alpha: 0.3),
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
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verified Properties & Rentals',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Apartments, Houses & Commercial Spaces in Zambia',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 2. Search Bar ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Search Kabulonga, Rhodespark, 3 Bed, Furnished...',
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: emeraldTheme),
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
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── 3. Property Type Chips ─────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: _propertyTypes.map((type) {
                    final isSel = _selectedPropertyType == type;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedPropertyType = type);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? emeraldTheme : cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSel ? emeraldTheme : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Text(
                          type,
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

              // ── 4. Bedroom, Furnished & Rent Filter Chips ─────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    ..._bedroomFilters.map((bed) {
                      final isSel = _selectedBedrooms == bed;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedBedrooms = bed);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel ? emeraldTheme.withValues(alpha: 0.15) : cardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel ? emeraldTheme : (isDark ? Colors.white10 : Colors.black12),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bed_outlined, size: 12, color: isSel ? emeraldTheme : Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                bed,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                  color: isSel ? emeraldTheme : (isDark ? Colors.white60 : Colors.black54),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 4),
                    ..._furnishedFilters.map((furn) {
                      final isSel = _selectedFurnished == furn;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedFurnished = furn);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF0284C7).withValues(alpha: 0.15) : cardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel ? const Color(0xFF0284C7) : (isDark ? Colors.white10 : Colors.black12),
                            ),
                          ),
                          child: Text(
                            furn,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? const Color(0xFF0284C7) : (isDark ? Colors.white60 : Colors.black54),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 4),
                    ..._rentRanges.map((rent) {
                      final isSel = _selectedRentRange == rent;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedRentRange = rent);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF10B981).withValues(alpha: 0.15) : cardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel ? const Color(0xFF10B981) : (isDark ? Colors.white10 : Colors.black12),
                            ),
                          ),
                          child: Text(
                            rent,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? const Color(0xFF10B981) : (isDark ? Colors.white60 : Colors.black54),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── 5. Property Listings Feed ──────────────────────────────────
              allListingsAsync.when(
                data: (listings) {
                  // Filter live marketplace listings
                  final realEstateListings = listings.where((l) {
                    final cat = l.category.toLowerCase();
                    return cat.contains('estate') || cat.contains('house') || cat.contains('apart') || cat.contains('property') || cat.contains('rent');
                  }).toList();

                  // Filter mock property items
                  final filteredProps = _mockProperties.where((p) {
                    if (_selectedPropertyType != 'All Types' && !p.propertyType.toLowerCase().contains(_selectedPropertyType.toLowerCase())) {
                      return false;
                    }
                    if (_selectedBedrooms == '1 Bed' && p.bedrooms != 1) return false;
                    if (_selectedBedrooms == '2 Beds' && p.bedrooms != 2) return false;
                    if (_selectedBedrooms == '3 Beds' && p.bedrooms != 3) return false;
                    if (_selectedBedrooms == '4+ Beds' && p.bedrooms < 4) return false;

                    if (_selectedFurnished != 'All' && !p.furnishedStatus.toLowerCase().contains(_selectedFurnished.toLowerCase())) {
                      return false;
                    }

                    if (_selectedRentRange == 'Under K 4,000/mo' && p.monthlyRent >= 4000) return false;
                    if (_selectedRentRange == 'K 4,000 - K 9,000/mo' && (p.monthlyRent < 4000 || p.monthlyRent > 9000)) return false;
                    if (_selectedRentRange == 'K 9,000 - K 18,000/mo' && (p.monthlyRent < 9000 || p.monthlyRent > 18000)) return false;
                    if (_selectedRentRange == 'K 18,000+/mo' && p.monthlyRent < 18000) return false;

                    if (_searchQuery.isNotEmpty) {
                      final matchTitle = p.title.toLowerCase().contains(_searchQuery);
                      final matchNeigh = p.neighborhood.toLowerCase().contains(_searchQuery);
                      final matchDesc = p.description.toLowerCase().contains(_searchQuery);
                      if (!matchTitle && !matchNeigh && !matchDesc) return false;
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
                              'Available Properties (${filteredProps.length + realEstateListings.length})',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const Text(
                              'Verified Landlords & Agents',
                              style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Live marketplace listings
                        if (realEstateListings.isNotEmpty) ...[
                          ...realEstateListings.map((l) => _buildLiveListingCard(context, l, isDark, cardColor, emeraldTheme)),
                          const SizedBox(height: 8),
                        ],

                        if (filteredProps.isEmpty && realEstateListings.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: const AnimatedEmptyState(
                              icon: Icons.apartment_outlined,
                              title: 'No Properties Match Filters',
                              subtitle: 'Try changing your bedroom count, property type, or furnished filters.',
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredProps.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 18),
                            itemBuilder: (context, index) {
                              final prop = filteredProps[index];
                              return _buildPropertyCard(context, prop, isDark, cardColor, emeraldTheme);
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
                  child: Text('Error loading real estate: $e'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyCard(
    BuildContext context,
    PropertyListingItem prop,
    bool isDark,
    Color cardColor,
    Color emeraldTheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
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
            // Cover Image
            SizedBox(
              height: 170,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  HubbleImage(imagePath: prop.imageUrl, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Property Type Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        prop.propertyType,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  // Furnished Status Chip
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        prop.furnishedStatus,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  // Monthly Rent on Bottom Right
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'K ${prop.monthlyRent.toStringAsFixed(0)} / mo',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  // Location on Bottom Left
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          '${prop.neighborhood}, ${prop.city}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
                  Text(
                    prop.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Listed by ${prop.agentOrLandlordName}',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                  const SizedBox(height: 10),

                  // Specs bar (Beds, Baths, Sqm)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (prop.bedrooms > 0)
                          Row(
                            children: [
                              const Icon(Icons.bed_rounded, size: 16, color: Color(0xFF059669)),
                              const SizedBox(width: 4),
                              Text('${prop.bedrooms} Bedrooms', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        Row(
                          children: [
                            const Icon(Icons.bathtub_outlined, size: 16, color: Color(0xFF0284C7)),
                            const SizedBox(width: 4),
                            Text('${prop.bathrooms} Baths', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.square_foot_rounded, size: 16, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 4),
                            Text('${prop.squareMeters} m²', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Amenities Chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: prop.amenities.take(3).map((amenity) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        amenity,
                        style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black54),
                      ),
                    )).toList(),
                  ),

                  const SizedBox(height: 14),

                  // Schedule Viewing & Contact CTAs
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          onPressed: () => _openScheduleViewing(context, prop),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: emeraldTheme,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.calendar_today_rounded, size: 16),
                          label: const Text('Schedule Viewing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF059669),
                                content: Text('Connecting to ${prop.agentOrLandlordName} (${prop.agentPhone})...'),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: emeraldTheme,
                            side: BorderSide(color: emeraldTheme.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.phone_outlined, size: 16),
                          label: const Text('Call Agent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
    );
  }

  Widget _buildLiveListingCard(
    BuildContext context,
    ListingModel listing,
    bool isDark,
    Color cardColor,
    Color emeraldTheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: emeraldTheme.withValues(alpha: 0.3)),
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
                          color: emeraldTheme.withValues(alpha: 0.15),
                          child: Icon(Icons.apartment_rounded, color: emeraldTheme, size: 30),
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
                      'K ${listing.price.toStringAsFixed(0)} / mo',
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
                    backgroundColor: emeraldTheme,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: const Text('Schedule Viewing / Inquire', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScheduleViewingSheet extends StatefulWidget {
  final PropertyListingItem property;

  const _ScheduleViewingSheet({required this.property});

  @override
  State<_ScheduleViewingSheet> createState() => _ScheduleViewingSheetState();
}

class _ScheduleViewingSheetState extends State<_ScheduleViewingSheet> {
  String _viewingType = 'In-Person Tour';
  String _selectedSlot = 'Tomorrow 10:00 AM';
  final TextEditingController _contactController = TextEditingController();
  bool _isScheduling = false;

  final List<String> _slots = [
    'Tomorrow 10:00 AM',
    'Tomorrow 02:30 PM',
    'Saturday 11:00 AM',
    'Saturday 03:00 PM',
    'Sunday 01:00 PM',
  ];

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const emeraldTheme = Color(0xFF059669);

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
                    color: emeraldTheme.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.apartment_rounded, color: emeraldTheme, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Schedule Property Viewing',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${widget.property.neighborhood}, ${widget.property.city}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Viewing Type (In-Person vs Virtual Tour)
            const Text('Tour Preference', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _viewingType = 'In-Person Tour'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _viewingType == 'In-Person Tour' ? emeraldTheme : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: emeraldTheme),
                      ),
                      child: Center(
                        child: Text(
                          '🚶 In-Person Physical Tour',
                          style: TextStyle(
                            color: _viewingType == 'In-Person Tour' ? Colors.white : emeraldTheme,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _viewingType = 'Virtual Live Video Tour'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _viewingType == 'Virtual Live Video Tour' ? emeraldTheme : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: emeraldTheme),
                      ),
                      child: Center(
                        child: Text(
                          '📹 Virtual Video Tour',
                          style: TextStyle(
                            color: _viewingType == 'Virtual Live Video Tour' ? Colors.white : emeraldTheme,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Text('Select Preferred Viewing Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _slots.map((slot) {
                final isSel = _selectedSlot == slot;
                return ChoiceChip(
                  label: Text(slot, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.w500)),
                  selected: isSel,
                  selectedColor: emeraldTheme,
                  labelStyle: TextStyle(color: isSel ? Colors.white : null),
                  onSelected: (val) => setState(() => _selectedSlot = slot),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            const Text('Your Phone / WhatsApp Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _contactController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '+260 97X XXX XXX',
                hintStyle: const TextStyle(fontSize: 12),
                prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isScheduling
                    ? null
                    : () async {
                        final nav = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        setState(() => _isScheduling = true);
                        await Future.delayed(const Duration(milliseconds: 600));
                        if (!mounted) return;
                        setState(() => _isScheduling = false);
                        nav.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF059669),
                            content: Text('Viewing scheduled with ${widget.property.agentOrLandlordName} for $_selectedSlot!'),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: emeraldTheme,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isScheduling
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Confirm Viewing Request',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
