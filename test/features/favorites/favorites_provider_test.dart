import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubble/features/favorites/presentation/providers/favorites_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('FavoritesNotifier Unit Tests', () {
    test('Initial favorites state has empty set or loaded favorites', () {
      final state = container.read(favoritesProvider);
      expect(state.favoriteIds, isNotNull);
    });

    test('toggleFavorite adds listing ID if not present', () async {
      final notifier = container.read(favoritesProvider.notifier);
      await notifier.toggleFavorite('test_listing_101');

      final state = container.read(favoritesProvider);
      expect(state.favoriteIds.contains('test_listing_101'), isTrue);
      expect(notifier.isFavorite('test_listing_101'), isTrue);
    });

    test('toggleFavorite removes listing ID if already present', () async {
      final notifier = container.read(favoritesProvider.notifier);
      await notifier.toggleFavorite('test_listing_102');
      expect(notifier.isFavorite('test_listing_102'), isTrue);

      await notifier.toggleFavorite('test_listing_102');
      expect(notifier.isFavorite('test_listing_102'), isFalse);
    });

    test('removeFavorite explicitly removes listing ID', () async {
      final notifier = container.read(favoritesProvider.notifier);
      await notifier.toggleFavorite('test_listing_103');
      expect(notifier.isFavorite('test_listing_103'), isTrue);

      await notifier.removeFavorite('test_listing_103');
      expect(notifier.isFavorite('test_listing_103'), isFalse);
    });

    test('clearFavorites clears all saved listing IDs', () async {
      final notifier = container.read(favoritesProvider.notifier);
      await notifier.toggleFavorite('fav_1');
      await notifier.toggleFavorite('fav_2');

      await notifier.clearAll();
      final state = container.read(favoritesProvider);
      expect(state.favoriteIds.isEmpty, isTrue);
    });
  });
}
