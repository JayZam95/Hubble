import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../domain/models/listing_model.dart';
import 'marketplace_provider.dart';

class SearchFilters {
  final double minPrice;
  final double maxPrice;
  final double maxDistance;
  final double minRating;

  SearchFilters({
    this.minPrice = 0.0,
    this.maxPrice = 10000.0,
    this.maxDistance = 50.0,
    this.minRating = 0.0,
  });

  SearchFilters copyWith({
    double? minPrice,
    double? maxPrice,
    double? maxDistance,
    double? minRating,
  }) {
    return SearchFilters(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      maxDistance: maxDistance ?? this.maxDistance,
      minRating: minRating ?? this.minRating,
    );
  }
}

class SearchFiltersNotifier extends Notifier<SearchFilters> {
  @override
  SearchFilters build() => SearchFilters();

  void updateFilters(SearchFilters filters) {
    state = filters;
  }
}

final searchFiltersProvider = NotifierProvider<SearchFiltersNotifier, SearchFilters>(() {
  return SearchFiltersNotifier();
});

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

final searchResultsProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final filters = ref.watch(searchFiltersProvider);
  final repository = ref.watch(marketplaceRepositoryProvider);
  final results = await repository.searchProviders(query);

  return results.where((provider) {
    if (provider.providerProfile.ratingAsProvider < filters.minRating) return false;
    return true;
  }).toList();
});

final listingSearchResultsProvider = FutureProvider.autoDispose<List<ListingModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final filters = ref.watch(searchFiltersProvider);
  final repository = ref.watch(marketplaceRepositoryProvider);
  final results = await repository.searchListings(query);

  return results.where((listing) {
    if (listing.price < filters.minPrice || listing.price > filters.maxPrice) return false;
    return true;
  }).toList();
});
