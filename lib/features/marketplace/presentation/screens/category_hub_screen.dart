import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/presentation/widgets/hubble_image.dart';
import '../../../../core/presentation/widgets/shimmer_loading.dart';
import '../../../../core/presentation/widgets/animated_empty_state.dart';
import '../../domain/models/listing_model.dart';
import '../providers/marketplace_provider.dart';
import 'listing_detail_screen.dart';
import 'transportation/coach_list_screen.dart';
import 'transportation/transportation_hub_screen.dart';
import 'categories/tutor_category_screen.dart';
import 'categories/handyman_category_screen.dart';
import 'categories/beauty_category_screen.dart';
import 'categories/health_category_screen.dart';
import 'categories/food_category_screen.dart';
import 'categories/real_estate_category_screen.dart';

class CategoryHubScreen extends ConsumerStatefulWidget {
  final String categoryTitle;
  final IconData icon;
  final Color themeColor;
  final String description;

  const CategoryHubScreen({
    super.key,
    required this.categoryTitle,
    required this.icon,
    required this.themeColor,
    required this.description,
  });

  /// Helper to get the specialized screen for a given category title.
  static Widget getScreenForCategory({
    required String categoryTitle,
    IconData icon = Icons.grid_view_rounded,
    Color themeColor = AppColors.primary,
    String description = 'Explore verified providers and services.',
  }) {
    final lower = categoryTitle.toLowerCase();

    if (lower.contains('tutor') || lower.contains('educat') || lower.contains('school') || lower.contains('teach')) {
      return const TutorCategoryScreen();
    }
    if (lower.contains('repair') || lower.contains('trade') || lower.contains('handyman') || lower.contains('plumb') || lower.contains('electric') || lower.contains('home repair')) {
      return const HandymanCategoryScreen();
    }
    if (lower.contains('beauty') || lower.contains('spa') || lower.contains('well') || lower.contains('salon') || lower.contains('hair') || lower.contains('groom') || lower.contains('barber')) {
      return const BeautyCategoryScreen();
    }
    if (lower.contains('health') || lower.contains('medic') || lower.contains('doctor') || lower.contains('clinic') || lower.contains('consult')) {
      return const HealthCategoryScreen();
    }
    if (lower.contains('food') || lower.contains('dining') || lower.contains('restaur') || lower.contains('cater') || lower.contains('bak') || lower.contains('groc')) {
      return const FoodCategoryScreen();
    }
    if (lower.contains('real estate') || lower.contains('estate') || lower.contains('housing') || lower.contains('apart') || lower.contains('property') || lower.contains('rent')) {
      return const RealEstateCategoryScreen();
    }
    if (lower.contains('transport') || lower.contains('deliver') || lower.contains('bus') || lower.contains('ride') || lower.contains('taxi')) {
      return const TransportationHubScreen();
    }

    return CategoryHubScreen(
      categoryTitle: categoryTitle,
      icon: icon,
      themeColor: themeColor,
      description: description,
    );
  }

  /// Helper to seamlessly push the appropriate category screen
  static void open(
    BuildContext context, {
    required String categoryTitle,
    IconData? icon,
    Color? themeColor,
    String? description,
  }) {
    HapticFeedback.lightImpact();
    final screen = getScreenForCategory(
      categoryTitle: categoryTitle,
      icon: icon ?? Icons.grid_view_rounded,
      themeColor: themeColor ?? AppColors.primary,
      description: description ?? 'Explore verified providers and products.',
    );
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  ConsumerState<CategoryHubScreen> createState() => _CategoryHubScreenState();
}

class _CategoryHubScreenState extends ConsumerState<CategoryHubScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, Services Only, Products Only, Top Rated

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesCategory(String listingCategory, String targetCategory) {
    final l = listingCategory.toLowerCase();
    final t = targetCategory.toLowerCase();
    if (l == t) return true;

    // Substring matching helpers
    if (t.contains('plumb') || t.contains('repair') || t.contains('home')) {
      return l.contains('plumb') || l.contains('repair') || l.contains('home') || l.contains('trade');
    }
    if (t.contains('tech') || t.contains('computer') || t.contains('software')) {
      return l.contains('tech') || l.contains('computer') || l.contains('software');
    }
    if (t.contains('medic') || t.contains('health')) {
      return l.contains('medic') || l.contains('health');
    }
    if (t.contains('educat') || t.contains('tutor')) {
      return l.contains('educat') || l.contains('tutor') || l.contains('school');
    }
    if (t.contains('beauty') || t.contains('spa') || t.contains('well')) {
      return l.contains('beauty') || l.contains('spa') || l.contains('well') || l.contains('groom');
    }
    if (t.contains('transport') || t.contains('deliver')) {
      return l.contains('transport') || l.contains('deliver') || l.contains('bus') || l.contains('taxi');
    }
    if (t.contains('retail') || t.contains('shop') || t.contains('cloth')) {
      return l.contains('retail') || l.contains('shop') || l.contains('cloth') || l.contains('apparel') || l.contains('electr');
    }
    return l.contains(t) || t.contains(l);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;

    final allListingsAsync = ref.watch(allListingsProvider);

    final isTransportation = widget.categoryTitle.toLowerCase().contains('transport') ||
        widget.categoryTitle.toLowerCase().contains('deliver');

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
          widget.categoryTitle,
          style: AppTextStyles.h2.copyWith(color: isDark ? Colors.white : Colors.black),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Hero Category Banner ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.themeColor,
                        widget.themeColor.withValues(alpha: 0.75),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: widget.themeColor.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.icon, color: Colors.white, size: 36),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.categoryTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.description,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 2. Transportation Fast Track Card (if applicable) ─────────
              if (isTransportation)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.directions_bus_rounded, color: AppColors.primary, size: 22),
                            SizedBox(width: 10),
                            Text(
                              'Intercity Bus Tickets & Express Travel',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CoachListScreen()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: const Icon(Icons.confirmation_number_rounded, size: 18),
                                label: const Text('Book Bus Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const TransportationHubScreen()),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: const Icon(Icons.local_taxi_rounded, size: 18),
                                label: const Text('Ride Hub', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // ── 3. Search & Filter Bar ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Search within ${widget.categoryTitle}...',
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── 4. Filter Pills ───────────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: ['All', 'Services Only', 'Products Only', 'Top Rated'].map((filter) {
                    final isSel = _selectedFilter == filter;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedFilter = filter);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? widget.themeColor : cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSel ? widget.themeColor : (isDark ? Colors.white12 : Colors.black12),
                          ),
                        ),
                        child: Text(
                          filter,
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

              const SizedBox(height: 20),

              // ── 5. Provider / Listing Results Feed ───────────────────────
              allListingsAsync.when(
                data: (listings) {
                  var filtered = listings.where((l) {
                    final matchesCat = _matchesCategory(l.category, widget.categoryTitle);
                    final matchesQuery = _searchQuery.isEmpty ||
                        l.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        l.description.toLowerCase().contains(_searchQuery.toLowerCase());
                    return matchesCat && matchesQuery;
                  }).toList();

                  if (_selectedFilter == 'Services Only') {
                    filtered = filtered.where((l) => l.listingType == ListingType.service).toList();
                  } else if (_selectedFilter == 'Products Only') {
                    filtered = filtered.where((l) => l.listingType == ListingType.product).toList();
                  }

                  if (filtered.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: AnimatedEmptyState(
                        icon: widget.icon,
                        title: 'No Listings Found',
                        subtitle: 'No provider listings match "${widget.categoryTitle}" currently.',
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final listing = filtered[index];
                        final hasImg = listing.images.isNotEmpty && listing.images.first.isNotEmpty;
                        final priceText = 'K ${listing.price.toStringAsFixed(0)}';

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ListingDetailScreen(listing: listing),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SizedBox(
                                    width: 85,
                                    height: 85,
                                    child: hasImg
                                        ? HubbleImage(
                                            imagePath: listing.images.first,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            color: widget.themeColor.withValues(alpha: 0.15),
                                            child: Icon(widget.icon, color: widget.themeColor, size: 36),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: widget.themeColor.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              listing.listingType == ListingType.service ? 'SERVICE' : 'PRODUCT',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: widget.themeColor,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            priceText,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        listing.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'By ${listing.providerName}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: ShimmerListTile(),
                ),
                error: (err, st) => Center(child: Text('Error: $err')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
