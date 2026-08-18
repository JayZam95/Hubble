import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/presentation/widgets/hubble_image.dart';
import '../../../marketplace/domain/models/listing_model.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../../marketplace/presentation/screens/listing_detail_screen.dart';
import '../providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesState = ref.watch(favoritesProvider);
    final sampleListings = ref.watch(sampleFavoriteListingsProvider);
    final allListingsAsync = ref.watch(allListingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Combine all available listings to resolve favorited IDs
    List<ListingModel> combinedListings = [...sampleListings];

    allListingsAsync.whenData((remoteListings) {
      for (final l in remoteListings) {
        if (!combinedListings.any((existing) => existing.id == l.id)) {
          combinedListings.add(l);
        }
      }
    });

    final savedListings = combinedListings
        .where((listing) => favoritesState.favoriteIds.contains(listing.id))
        .toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        title: Text(
          'Saved Wishlist (${savedListings.length})',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
          ),
        ),
        actions: [
          if (savedListings.isNotEmpty)
            IconButton(
              tooltip: 'Clear All Favorites',
              icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
              onPressed: () {
                _confirmClearDialog(context, ref);
              },
            ),
        ],
      ),
      body: SafeArea(
        child: favoritesState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : savedListings.isEmpty
                ? _buildEmptyState(context, isDark)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: savedListings.length,
                    itemBuilder: (context, index) {
                      final listing = savedListings[index];
                      return _buildFavoriteCard(context, ref, listing, isDark);
                    },
                  ),
      ),
    );
  }

  Widget _buildFavoriteCard(
    BuildContext context,
    WidgetRef ref,
    ListingModel listing,
    bool isDark,
  ) {
    final hasImages = listing.images.isNotEmpty && listing.images.first.isNotEmpty;
    final isService = listing.listingType == ListingType.service;
    final billingLabel = listing.billingType == BillingType.hourly
        ? '/hr'
        : listing.billingType == BillingType.monthly
            ? '/mo'
            : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ListingDetailScreen(listing: listing),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      if (hasImages)
                        HubbleImage(
                          imagePath: listing.images.first,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        )
                      else
                        Container(
                          width: 90,
                          height: 90,
                          color: isDark ? Colors.grey[800] : Colors.grey[300],
                          child: Icon(
                            isService ? Icons.handyman : Icons.shopping_bag,
                            color: isDark ? Colors.white30 : Colors.black26,
                            size: 36,
                          ),
                        ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isService ? 'SERVICE' : 'SHOP',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.category.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        listing.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By ${listing.providerName}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ZMW ${listing.price.toStringAsFixed(0)}$billingLabel',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),

                // Quick Remove Icon Button
                IconButton(
                  tooltip: 'Remove from Wishlist',
                  icon: const Icon(Icons.favorite, color: Colors.redAccent, size: 24),
                  onPressed: () {
                    ref.read(favoritesProvider.notifier).removeFavorite(listing.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed "${listing.title}" from saved favorites'),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Saved Favorites Yet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save services, products, and providers to your wishlist for fast booking and quick access.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.explore, color: Colors.white),
              label: const Text(
                'Explore Marketplace',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear All Favorites?'),
          content: const Text('This will remove all saved listings from your wishlist.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () {
                ref.read(favoritesProvider.notifier).clearAll();
                Navigator.pop(context);
              },
              child: const Text('Clear All', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
