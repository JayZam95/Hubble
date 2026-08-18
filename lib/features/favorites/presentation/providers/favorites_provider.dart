import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../marketplace/domain/models/listing_model.dart';

class FavoritesState {
  final Set<String> favoriteIds;
  final bool isLoading;

  FavoritesState({
    required this.favoriteIds,
    this.isLoading = false,
  });

  FavoritesState copyWith({
    Set<String>? favoriteIds,
    bool? isLoading,
  }) {
    return FavoritesState(
      favoriteIds: favoriteIds ?? this.favoriteIds,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FavoritesNotifier extends Notifier<FavoritesState> {
  static const String _prefsKey = 'hubble_saved_favorite_ids';

  @override
  FavoritesState build() {
    Future.microtask(() => _loadFavorites());
    return FavoritesState(
      favoriteIds: {
        'fav_sample_1',
        'fav_sample_2',
      },
      isLoading: false,
    );
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList(_prefsKey);

      if (!ref.mounted) return;

      if (savedList != null) {
        state = state.copyWith(
          favoriteIds: savedList.toSet(),
          isLoading: false,
        );
      } else {
        await prefs.setStringList(_prefsKey, state.favoriteIds.toList());
        if (ref.mounted) {
          state = state.copyWith(isLoading: false);
        }
      }
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<void> toggleFavorite(String listingId) async {
    final currentSet = Set<String>.from(state.favoriteIds);
    if (currentSet.contains(listingId)) {
      currentSet.remove(listingId);
    } else {
      currentSet.add(listingId);
    }

    state = state.copyWith(favoriteIds: currentSet);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, currentSet.toList());
    } catch (_) {}
  }

  bool isFavorite(String listingId) {
    return state.favoriteIds.contains(listingId);
  }

  Future<void> removeFavorite(String listingId) async {
    if (!state.favoriteIds.contains(listingId)) return;

    final currentSet = Set<String>.from(state.favoriteIds)..remove(listingId);
    state = state.copyWith(favoriteIds: currentSet);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, currentSet.toList());
    } catch (_) {}
  }

  Future<void> clearAll() async {
    state = state.copyWith(favoriteIds: {});
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, FavoritesState>(FavoritesNotifier.new);

// Mock / Default listings resolver for offline & fallback display
final sampleFavoriteListingsProvider = Provider<List<ListingModel>>((ref) {
  return [
    ListingModel(
      id: 'fav_sample_1',
      providerId: 'p_101',
      providerName: 'Chisa Electrical Services',
      providerImage: 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=500',
      title: 'Full Home Solar & Wiring Installation',
      description: 'Professional residential wiring, solar inverter installation and DB board upgrades in Kitwe & Lusaka.',
      price: 450.0,
      listingType: ListingType.service,
      billingType: BillingType.fixed,
      category: 'Technology Support',
      images: [
        'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=500',
      ],
      stockCount: 1,
      estimatedDuration: '4 Hours',
      travelsToClient: true,
      travelRadius: 25,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    ListingModel(
      id: 'fav_sample_2',
      providerId: 'p_102',
      providerName: 'Kabwe Plumbing & Drain Pros',
      providerImage: 'https://images.unsplash.com/photo-1581092921461-eab62e97a780?w=500',
      title: 'Emergency Leak Repair & Drain Unblocking',
      description: '24/7 fast response emergency plumbing, boreholes, and pipe fitting in Lusaka.',
      price: 180.0,
      listingType: ListingType.service,
      billingType: BillingType.hourly,
      category: 'Plumbing & Home Repair',
      images: [
        'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=500',
      ],
      stockCount: 1,
      estimatedDuration: '1 Hour',
      travelsToClient: true,
      travelRadius: 30,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    ListingModel(
      id: 'fav_sample_3',
      providerId: 'p_103',
      providerName: 'Zambia Tech Depot',
      providerImage: 'https://images.unsplash.com/photo-1605647540924-852290f6b0d5?w=500',
      title: 'Smart Home Security Camera Kit (4CH)',
      description: 'Full HD wireless IP camera kit with night vision, mobile app access, and 1TB storage.',
      price: 1250.0,
      listingType: ListingType.product,
      billingType: BillingType.perItem,
      category: 'Electronics & Gadgets',
      images: [
        'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=500',
      ],
      stockCount: 15,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
  ];
});
