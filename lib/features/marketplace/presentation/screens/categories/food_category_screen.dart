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
import '../../providers/cart_provider.dart';
import '../cart_screen.dart';
import '../listing_detail_screen.dart';

class FoodMenuItem {
  final String id;
  final String title;
  final String restaurantOrBakerName;
  final String imageUrl;
  final String cuisine; // Traditional Zambian, Fast Food, Bakery & Pastry, BBQ & Grill, Asian, Healthy
  final String mealType; // Breakfast, Lunch, Dinner, Snacks, Catering
  final double price;
  final int prepTimeMinutes;
  final double rating;
  final int reviewsCount;
  final bool isDeliveryAvailable;
  final bool isTakeoutAvailable;
  final String description;
  final List<String> tags;

  const FoodMenuItem({
    required this.id,
    required this.title,
    required this.restaurantOrBakerName,
    required this.imageUrl,
    required this.cuisine,
    required this.mealType,
    required this.price,
    required this.prepTimeMinutes,
    required this.rating,
    required this.reviewsCount,
    required this.isDeliveryAvailable,
    required this.isTakeoutAvailable,
    required this.description,
    required this.tags,
  });

  ListingModel toListingModel() {
    return ListingModel(
      id: id,
      providerId: 'provider_$id',
      providerName: restaurantOrBakerName,
      providerImage: imageUrl,
      title: title,
      description: description,
      price: price,
      listingType: ListingType.product,
      billingType: BillingType.perItem,
      category: 'Food & Catering',
      images: [imageUrl],
      stockCount: 20,
      createdAt: DateTime.now(),
    );
  }
}

class FoodCategoryScreen extends ConsumerStatefulWidget {
  const FoodCategoryScreen({super.key});

  @override
  ConsumerState<FoodCategoryScreen> createState() => _FoodCategoryScreenState();
}

class _FoodCategoryScreenState extends ConsumerState<FoodCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCuisine = 'All Cuisines';
  String _selectedMealType = 'All Meals';
  String _selectedPrepTime = 'All Times'; // All Times, < 20 mins, 20-40 mins, 40+ mins
  bool _isDeliveryMode = true; // true = Delivery, false = Takeout

  final List<String> _cuisines = [
    'All Cuisines',
    'Traditional Zambian',
    'Grill & BBQ',
    'Fast Food',
    'Bakery & Pastry',
    'Healthy & Salads',
    'Asian & Rice',
  ];

  final List<String> _mealTypes = [
    'All Meals',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snacks & Desserts',
    'Catering Packs',
  ];

  final List<String> _prepTimes = [
    'All Times',
    '< 20 mins (Fast)',
    '20-40 mins',
    '40+ mins',
  ];

  final List<FoodMenuItem> _mockFoodItems = const [
    FoodMenuItem(
      id: 'food_1',
      title: 'Traditional Nshima with Village Chicken & Chibwabwa',
      restaurantOrBakerName: 'Kwamwamba Zambian Kitchen',
      imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?fit=crop&w=600&q=80',
      cuisine: 'Traditional Zambian',
      mealType: 'Lunch',
      price: 95.0,
      prepTimeMinutes: 25,
      rating: 4.95,
      reviewsCount: 240,
      isDeliveryAvailable: true,
      isTakeoutAvailable: true,
      description: 'Slow-cooked free-range village chicken in rich tomato onion gravy, served with white breakfast meal nshima and pumpkin leaves.',
      tags: ['Local Favorite', 'Hot & Fresh', 'Authentic'],
    ),
    FoodMenuItem(
      id: 'food_2',
      title: 'Charcoal Braai T-Bone Steak & Garlic Chips',
      restaurantOrBakerName: 'The Smokehouse & Grill',
      imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?fit=crop&w=600&q=80',
      cuisine: 'Grill & BBQ',
      mealType: 'Dinner',
      price: 165.0,
      prepTimeMinutes: 30,
      rating: 4.85,
      reviewsCount: 180,
      isDeliveryAvailable: true,
      isTakeoutAvailable: true,
      description: '500g flame-grilled Zambian prime beef T-Bone with secret BBQ basting, crispy chips, and homemade chakalaka.',
      tags: ['Popular', 'BBQ', 'High Protein'],
    ),
    FoodMenuItem(
      id: 'food_3',
      title: 'Artisan Red Velvet & Belgian Chocolate Cake Slice',
      restaurantOrBakerName: 'Fresh Bakes by Maria',
      imageUrl: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?fit=crop&w=600&q=80',
      cuisine: 'Bakery & Pastry',
      mealType: 'Snacks & Desserts',
      price: 65.0,
      prepTimeMinutes: 15,
      rating: 5.0,
      reviewsCount: 310,
      isDeliveryAvailable: true,
      isTakeoutAvailable: true,
      description: 'Moist layers of rich cocoa red velvet cake frosted with velvety cream cheese icing and dark chocolate shavings.',
      tags: ['Dessert', 'Freshly Baked', 'Sweet'],
    ),
    FoodMenuItem(
      id: 'food_4',
      title: 'Double Smash Beef Burger with Melted Cheddar',
      restaurantOrBakerName: 'Urban Burger Shack',
      imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?fit=crop&w=600&q=80',
      cuisine: 'Fast Food',
      mealType: 'Lunch',
      price: 110.0,
      prepTimeMinutes: 18,
      rating: 4.9,
      reviewsCount: 195,
      isDeliveryAvailable: true,
      isTakeoutAvailable: true,
      description: 'Two smashed beef patties, caramelized onions, melted cheddar cheese, dill pickles, and house secret sauce on brioche.',
      tags: ['Fast & Easy', 'Cheesy', 'Top Rated'],
    ),
    FoodMenuItem(
      id: 'food_5',
      title: 'Grilled Lemon Herb Tilapia & Fresh Green Salad',
      restaurantOrBakerName: 'Kariba Breeze Seafood & Greens',
      imageUrl: 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?fit=crop&w=600&q=80',
      cuisine: 'Healthy & Salads',
      mealType: 'Dinner',
      price: 140.0,
      prepTimeMinutes: 22,
      rating: 4.8,
      reviewsCount: 92,
      isDeliveryAvailable: true,
      isTakeoutAvailable: true,
      description: 'Whole fresh Lake Kariba Bream / Tilapia grilled with olive oil, lemon zest, garlic herbs, with avocado garden salad.',
      tags: ['Healthy', 'Fresh Catch', 'Keto'],
    ),
    FoodMenuItem(
      id: 'food_6',
      title: 'Special Egg Fried Rice with Stir-Fry Chili Beef',
      restaurantOrBakerName: 'Wok & Roll Asian Bistro',
      imageUrl: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?fit=crop&w=600&q=80',
      cuisine: 'Asian & Rice',
      mealType: 'Dinner',
      price: 125.0,
      prepTimeMinutes: 20,
      rating: 4.85,
      reviewsCount: 144,
      isDeliveryAvailable: true,
      isTakeoutAvailable: true,
      description: 'Fragrant jasmine rice wok-tossed with scallions, organic eggs, tender beef strips, bell peppers, and savory dark soy.',
      tags: ['Wok Fresh', 'Spicy', 'Savory'],
    ),
    FoodMenuItem(
      id: 'food_7',
      title: 'English Breakfast Platter (Eggs, Sausages & Toast)',
      restaurantOrBakerName: 'Morning Brew Café',
      imageUrl: 'https://images.unsplash.com/photo-1533089860892-a7c6f0a88666?fit=crop&w=600&q=80',
      cuisine: 'Fast Food',
      mealType: 'Breakfast',
      price: 85.0,
      prepTimeMinutes: 15,
      rating: 4.75,
      reviewsCount: 88,
      isDeliveryAvailable: true,
      isTakeoutAvailable: true,
      description: 'Two sunny-side up eggs, grilled beef sausages, baked beans, sauteed mushrooms, and buttered whole wheat toast.',
      tags: ['Breakfast', 'All Day', 'Coffee Pairing'],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(FoodMenuItem food) {
    HapticFeedback.lightImpact();
    final listing = food.toListingModel();
    ref.read(cartProvider.notifier).addItem(listing);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('Added "${food.title}" to cart!')),
          ],
        ),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    const amberTheme = Color(0xFFD97706); // Amber 600

    final allListingsAsync = ref.watch(allListingsProvider);
    final cart = ref.watch(cartProvider);
    final cartCount = cart.items.fold(0, (sum, i) => sum + i.quantity);

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
          'Food & Dining Hub',
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.shopping_bag_outlined, color: isDark ? Colors.white : Colors.black),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                },
              ),
              if (cartCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),
        ],
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
                      colors: [Color(0xFFD97706), Color(0xFFEA580C), Color(0xFFDC2626)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD97706).withValues(alpha: 0.35),
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
                        child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fresh Meals & Local Bakeries',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Traditional Nshima, BBQ, Cakes & Fast Delivery',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 2. Delivery vs Takeout Toggle ──────────────────────────────
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
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _isDeliveryMode = true);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isDeliveryMode ? const Color(0xFFD97706) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.moped_rounded, size: 16, color: _isDeliveryMode ? Colors.white : Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    '🛵 Fast Delivery (25-35m)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _isDeliveryMode ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _isDeliveryMode = false);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isDeliveryMode ? const Color(0xFFD97706) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.takeout_dining_rounded, size: 16, color: !_isDeliveryMode ? Colors.white : Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    '🥡 Takeout Pickup',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: !_isDeliveryMode ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
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
                    hintText: 'Search village chicken, burger, cakes, steak...',
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: amberTheme),
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

              // ── 4. Cuisine Filter Chips (Horizontal) ───────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: _cuisines.map((c) {
                    final isSel = _selectedCuisine == c;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCuisine = c);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? amberTheme : cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSel ? amberTheme : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Text(
                          c,
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

              const SizedBox(height: 10),

              // ── 5. Meal Type & Prep Time Chips ─────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    ..._mealTypes.map((m) {
                      final isSel = _selectedMealType == m;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedMealType = m);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel ? amberTheme.withValues(alpha: 0.15) : cardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel ? amberTheme : (isDark ? Colors.white10 : Colors.black12),
                            ),
                          ),
                          child: Text(
                            m,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? amberTheme : (isDark ? Colors.white60 : Colors.black54),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 4),
                    ..._prepTimes.map((p) {
                      final isSel = _selectedPrepTime == p;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedPrepTime = p);
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.timer_outlined, size: 12, color: isSel ? const Color(0xFF10B981) : Colors.grey),
                              const SizedBox(width: 3),
                              Text(
                                p,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                  color: isSel ? const Color(0xFF10B981) : (isDark ? Colors.white60 : Colors.black54),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── 6. Food & Dining Feed ──────────────────────────────────────
              allListingsAsync.when(
                data: (listings) {
                  // Filter live marketplace listings
                  final foodListings = listings.where((l) {
                    final cat = l.category.toLowerCase();
                    return cat.contains('food') || cat.contains('cater') || cat.contains('bak') || cat.contains('restaur') || cat.contains('groc');
                  }).toList();

                  // Filter mock food items
                  final filteredFoods = _mockFoodItems.where((food) {
                    if (_selectedCuisine != 'All Cuisines' && !food.cuisine.toLowerCase().contains(_selectedCuisine.toLowerCase())) {
                      return false;
                    }
                    if (_selectedMealType != 'All Meals' && !food.mealType.toLowerCase().contains(_selectedMealType.toLowerCase())) {
                      return false;
                    }
                    if (_selectedPrepTime == '< 20 mins (Fast)' && food.prepTimeMinutes >= 20) return false;
                    if (_selectedPrepTime == '20-40 mins' && (food.prepTimeMinutes < 20 || food.prepTimeMinutes > 40)) return false;
                    if (_selectedPrepTime == '40+ mins' && food.prepTimeMinutes < 40) return false;

                    if (_searchQuery.isNotEmpty) {
                      final matchTitle = food.title.toLowerCase().contains(_searchQuery);
                      final matchRest = food.restaurantOrBakerName.toLowerCase().contains(_searchQuery);
                      final matchDesc = food.description.toLowerCase().contains(_searchQuery);
                      if (!matchTitle && !matchRest && !matchDesc) return false;
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
                              'Dishes & Caterers (${filteredFoods.length + foodListings.length})',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              _isDeliveryMode ? '🛵 Avg 25-35m' : '🥡 Pickup in 15m',
                              style: const TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Live marketplace listings
                        if (foodListings.isNotEmpty) ...[
                          ...foodListings.map((l) => _buildLiveListingCard(context, l, isDark, cardColor, amberTheme)),
                          const SizedBox(height: 8),
                        ],

                        if (filteredFoods.isEmpty && foodListings.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: AnimatedEmptyState(
                              icon: Icons.restaurant_outlined,
                              title: 'No Dishes Match Selected Filters',
                              subtitle: 'Try changing your cuisine or meal type filters to see more delicious meals.',
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredFoods.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final food = filteredFoods[index];
                              return _buildFoodCard(context, food, isDark, cardColor, amberTheme);
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
                  child: Text('Error loading food: $e'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodCard(
    BuildContext context,
    FoodMenuItem food,
    bool isDark,
    Color cardColor,
    Color amberTheme,
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
            // Image with Prep Time & Price Tag
            SizedBox(
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  HubbleImage(imagePath: food.imageUrl, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Cuisine Badge
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
                        food.cuisine,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  // Prep Time Chip
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: amberTheme,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '⏱️ ${food.prepTimeMinutes} mins',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  // Price on Bottom Right
                  Positioned(
                    bottom: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'K ${food.price.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details Body
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
                          food.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        food.restaurantOrBakerName,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        '${food.rating} (${food.reviewsCount})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    food.description,
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: food.tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w500),
                      ),
                    )).toList(),
                  ),

                  const SizedBox(height: 14),

                  // Add To Cart & Order Now Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addToCart(food),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: amberTheme,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                          label: const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _addToCart(food);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF10B981),
                          side: const BorderSide(color: Color(0xFF10B981)),
                          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Order Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
    Color amberTheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: amberTheme.withValues(alpha: 0.3)),
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
                          color: amberTheme.withValues(alpha: 0.15),
                          child: Icon(Icons.restaurant_rounded, color: amberTheme, size: 30),
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
                      'K ${listing.price.toStringAsFixed(2)}',
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
                    ref.read(cartProvider.notifier).addItem(listing);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF10B981),
                        content: Text('Added "${listing.title}" to cart!'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: amberTheme,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                  label: const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: listing)));
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                ),
                child: const Text('View', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
