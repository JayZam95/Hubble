import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/search_provider.dart';
import '../../../profile/presentation/screens/public_profile_screen.dart';
import '../../../../core/presentation/widgets/shimmer_loading.dart';
import 'listing_detail_screen.dart';
import '../../../../core/presentation/widgets/hubble_image.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  final String initialQuery;
  const SearchResultsScreen({super.key, required this.initialQuery});

  @override
  ConsumerState<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchQueryProvider.notifier).updateQuery(widget.initialQuery);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: TextField(
            autofocus: true,
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: (val) {
              ref.read(searchQueryProvider.notifier).updateQuery(val);
            },
            onSubmitted: (val) {
              ref.read(searchQueryProvider.notifier).updateQuery(val);
            },
            decoration: const InputDecoration(
              hintText: 'Search marketplace...',
              border: InputBorder.none,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).updateQuery('');
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Providers'),
              Tab(text: 'Listings & Products'),
            ],
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
          ),
        ),
        body: const TabBarView(
          children: [
            _ProvidersTab(),
            _ListingsTab(),
          ],
        ),
      ),
    );
  }
}

class _ProvidersTab extends ConsumerWidget {
  const _ProvidersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResultsAsync = ref.watch(searchResultsProvider);
    
    return searchResultsAsync.when(
      data: (providers) {
        if (providers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('No service providers found.', style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Try adjusting your filters or search query.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref.read(searchQueryProvider.notifier).updateQuery('');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Clear Search', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: providers.length,
          itemBuilder: (context, index) {
            final user = providers[index];
            final profile = user.providerProfile;
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PublicProfileScreen(providerUser: user),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'profile_pic_${user.uid}',
                        child: user.personalInfo.profileImageURL.isNotEmpty
                            ? HubbleImage(
                                imagePath: user.personalInfo.profileImageURL,
                                width: 60,
                                height: 60,
                                borderRadius: BorderRadius.circular(30),
                              )
                            : CircleAvatar(
                                radius: 30,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                child: Text(
                                  user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'P',
                                  style: const TextStyle(fontSize: 24, color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.displayName, style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(profile.professionTitle, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text(
                              profile.bio,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(profile.ratingAsProvider.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 16),
                                const Icon(Icons.attach_money, color: Colors.green, size: 16),
                                Text('${profile.hourlyRate}/hr', style: const TextStyle(fontWeight: FontWeight.bold)),
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
          },
        );
      },
      loading: () => const ShimmerListLoading(),
      error: (err, stack) => Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Oops! Something went wrong.', style: AppTextStyles.heading3),
              const SizedBox(height: 8),
              Text(err.toString(), style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListingsTab extends ConsumerWidget {
  const _ListingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(listingSearchResultsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return listingsAsync.when(
      data: (listings) {
        if (listings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('No listings or products found.', style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Try adjusting your filters or search query.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref.read(searchQueryProvider.notifier).updateQuery('');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Clear Search', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: listings.length,
          itemBuilder: (context, index) {
            final listing = listings[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ListingDetailScreen(listing: listing),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (listing.images.isNotEmpty)
                      HubbleImage(
                        imagePath: listing.images.first,
                        height: 160,
                        width: double.infinity,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  listing.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  listing.listingType.name.toUpperCase(),
                                  style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            listing.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  if (listing.providerImage.isNotEmpty)
                                    HubbleImage(
                                      imagePath: listing.providerImage,
                                      width: 24,
                                      height: 24,
                                      borderRadius: BorderRadius.circular(12),
                                    )
                                  else
                                    const Icon(Icons.person, size: 24, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    listing.providerName,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              Text(
                                  'K ${listing.price.toStringAsFixed(0)} / ${listing.billingType.name}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
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
          },
        );
      },
      loading: () => const ShimmerListLoading(),
      error: (err, stack) => Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Oops! Something went wrong.', style: AppTextStyles.heading3),
              const SizedBox(height: 8),
              Text(err.toString(), style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
