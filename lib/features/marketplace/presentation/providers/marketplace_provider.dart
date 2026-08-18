import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../../../core/utils/dummy_data_seeder.dart';
import '../../data/repositories/marketplace_repository.dart';
import '../../domain/models/listing_model.dart';
import '../../../auth/domain/models/user_model.dart';

class MarketplaceState {
  final bool isLoading;
  final bool isSuccess;
  final String errorMessage;
  final String professionTitle;
  final double hourlyRate;
  final String bio;
  final List<String> portfolioImages;

  MarketplaceState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage = '',
    this.professionTitle = '',
    this.hourlyRate = 0.0,
    this.bio = '',
    this.portfolioImages = const [],
  });

  MarketplaceState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    String? professionTitle,
    double? hourlyRate,
    String? bio,
    List<String>? portfolioImages,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return MarketplaceState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: clearSuccess ? false : (isSuccess ?? this.isSuccess),
      errorMessage: clearError ? '' : (errorMessage ?? this.errorMessage),
      professionTitle: professionTitle ?? this.professionTitle,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      bio: bio ?? this.bio,
      portfolioImages: portfolioImages ?? this.portfolioImages,
    );
  }
}

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return MarketplaceRepository();
});

class MarketplaceNotifier extends Notifier<MarketplaceState> {
  @override
  MarketplaceState build() {
    return MarketplaceState();
  }

  Future<void> fetchProfile(String uid) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final repository = ref.read(marketplaceRepositoryProvider);
      final profile = await repository.fetchProviderProfile(uid);
      if (profile != null) {
        state = state.copyWith(
          isLoading: false,
          professionTitle: profile['professionTitle'] as String? ?? '',
          hourlyRate: (profile['hourlyRate'] as num?)?.toDouble() ?? 0.0,
          bio: profile['bio'] as String? ?? '',
          portfolioImages: (profile['portfolioImages'] as List?)?.cast<String>() ?? [],
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> saveProfile({
    required String uid,
    required String professionTitle,
    required String category,
    required String businessType,
    required double hourlyRate,
    required String bio,
    required List<File> newImageFiles,
    required List<String> existingImageUrls,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final repository = ref.read(marketplaceRepositoryProvider);
      
      List<String> uploadedUrls = [];
      if (newImageFiles.isNotEmpty) {
        uploadedUrls = await repository.uploadPortfolioImages(uid, newImageFiles);
      }
      
      final allUrls = [...existingImageUrls, ...uploadedUrls];

      await repository.saveProviderProfile(
        uid: uid,
        professionTitle: professionTitle,
        category: category,
        businessType: businessType,
        hourlyRate: hourlyRate,
        bio: bio,
        portfolioImages: allUrls,
      );
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        professionTitle: professionTitle,
        hourlyRate: hourlyRate,
        bio: bio,
        portfolioImages: allUrls,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearSuccess() {
    state = state.copyWith(clearSuccess: true);
  }
}

final marketplaceProvider = NotifierProvider<MarketplaceNotifier, MarketplaceState>(() {
  return MarketplaceNotifier();
});

final liveCategoriesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final repo = ref.watch(marketplaceRepositoryProvider);
  return repo.getLiveCategories();
});

// --- NEW PROVIDERS ---

final providerListingsProvider = FutureProvider.family<List<ListingModel>, String>((ref, providerId) async {
  final repo = ref.watch(marketplaceRepositoryProvider);
  return repo.fetchListingsByProvider(providerId);
});

final allListingsProvider = FutureProvider<List<ListingModel>>((ref) async {
  final repo = ref.watch(marketplaceRepositoryProvider);
  final listings = await repo.fetchAllListings();
  if (listings.isEmpty) {
    await DummyDataSeeder.seedAllMockData();
    return repo.fetchAllListings();
  }
  return listings;
});

final listingsByCategoryProvider = FutureProvider.family<List<ListingModel>, String>((ref, category) async {
  final listings = await ref.watch(allListingsProvider.future);
  if (category.trim().isEmpty) return listings;
  return listings.where((l) => l.category.toLowerCase() == category.trim().toLowerCase()).toList();
});

final topProvidersProvider = FutureProvider.family<List<UserModel>, String?>((ref, businessType) async {
  final repo = ref.watch(marketplaceRepositoryProvider);
  final providers = await repo.fetchTopProviders(businessType: businessType);
  if (providers.isEmpty) {
    await DummyDataSeeder.seedAllMockData();
    return repo.fetchTopProviders(businessType: businessType);
  }
  return providers;
});
