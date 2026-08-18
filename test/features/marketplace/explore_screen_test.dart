import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubble/features/marketplace/presentation/screens/explore_screen.dart';
import 'package:hubble/features/marketplace/presentation/screens/categories/tutor_category_screen.dart';
import 'package:hubble/features/marketplace/presentation/screens/map_screen.dart';
import 'package:hubble/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:hubble/features/marketplace/presentation/providers/trending_categories_provider.dart';
import 'package:hubble/features/marketplace/domain/models/listing_model.dart';
import 'package:hubble/features/auth/presentation/providers/auth_provider.dart';
import '../auth/presentation/auth_provider_test.dart';

void main() {
  late FakeAuthRepository fakeRepository;
  late ListingModel sampleProduct;

  setUp(() {
    fakeRepository = FakeAuthRepository();
    sampleProduct = ListingModel(
      id: 'prod_1',
      providerId: 'p_1',
      providerName: 'Tech Shop',
      providerImage: '',
      title: 'Wireless Headphones',
      description: 'Noise cancelling audio',
      price: 299.0,
      listingType: ListingType.product,
      billingType: BillingType.perItem,
      category: 'Electronics',
      images: [],
      stockCount: 5,
      createdAt: DateTime.now(),
    );
  });

  Widget createExploreScreen() {

    return ProviderScope(
      overrides: [
        trendingCategoriesProvider.overrideWith((ref) => Stream.value(['Tutoring', 'Repairs'])),
        allListingsProvider.overrideWith((ref) => Future.value([sampleProduct])),
        topProvidersProvider('individual').overrideWith((ref) => Future.value([])),
        topProvidersProvider('shop').overrideWith((ref) => Future.value([])),
        authRepositoryProvider.overrideWithValue(fakeRepository),
      ],
      child: const MaterialApp(
        home: ExploreScreen(animate: false),
      ),
    );
  }

  group('ExploreScreen Widget Tests', () {
    testWidgets('Renders Hubble title, search bar, category grid, and map view button', (WidgetTester tester) async {
      await tester.pumpWidget(createExploreScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Hubble'), findsOneWidget);
      expect(find.byKey(const Key('explore_search_bar_padding')), findsOneWidget);
      expect(find.text('Explore Categories'), findsOneWidget);
      expect(find.byKey(const Key('category_tutoring')), findsOneWidget);
      expect(find.byKey(const Key('category_repairs')), findsOneWidget);
      expect(find.byKey(const Key('explore_map_button')), findsOneWidget);
    });

    testWidgets('Tapping on a category tile navigates to CategoryHubScreen / Specialized Screen', (WidgetTester tester) async {
      await tester.pumpWidget(createExploreScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.ensureVisible(find.byKey(const Key('category_tutoring')));
      await tester.tap(find.byKey(const Key('category_tutoring')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(TutorCategoryScreen), findsOneWidget);
    });

    testWidgets('Tapping on Map View floating action button navigates to MapScreen', (WidgetTester tester) async {
      await tester.pumpWidget(createExploreScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.byKey(const Key('explore_map_button')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(MapScreen), findsOneWidget);
    });

    testWidgets('Tapping Services and Products tabs switches active section', (WidgetTester tester) async {
      await tester.pumpWidget(createExploreScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Services'), findsOneWidget);
      expect(find.text('Products'), findsOneWidget);

      await tester.tap(find.text('Products'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Trending Products'), findsOneWidget);
      expect(find.text('Wireless Headphones'), findsOneWidget);
    });
  });
}
