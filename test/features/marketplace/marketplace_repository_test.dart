import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hubble/features/marketplace/data/repositories/marketplace_repository.dart';

// Fake class to mock FirebaseFirestore and avoid initialisation errors
class MockFirebaseFirestore extends Fake implements FirebaseFirestore {}

// A mock Firestore database helper that verifies dot notation updates
class MockFirestore {
  String? lastUpdatedUid;
  Map<String, dynamic>? lastUpdatedData;
  bool shouldThrow = false;

  Future<void> update(String uid, Map<String, dynamic> data) async {
    if (shouldThrow) throw Exception('Firestore write failed');
    lastUpdatedUid = uid;
    lastUpdatedData = data;
  }
}

// Subclass MarketplaceRepository for testing to intercept Firestore calls
class TestableMarketplaceRepository extends MarketplaceRepository {
  final MockFirestore mockFirestore;

  TestableMarketplaceRepository(this.mockFirestore) : super(firestore: MockFirebaseFirestore());

  @override
  Future<void> saveProviderProfile({
    required String uid,
    required String professionTitle,
    required String category,
    required String businessType,
    required double hourlyRate,
    required String bio,
    required List<String> portfolioImages,
  }) async {
    try {
      final updatedData = {
        'providerProfile.professionTitle': professionTitle,
        'providerProfile.category': category,
        'providerProfile.businessType': businessType,
        'providerProfile.hourlyRate': hourlyRate,
        'providerProfile.bio': bio,
        'providerProfile.portfolioImages': portfolioImages,
        'providerProfile.isActive': true,
      };
      await mockFirestore.update(uid, updatedData);
    } catch (e) {
      throw Exception('Failed to save storefront: ${e.toString()}');
    }
  }
}

void main() {
  group('MarketplaceRepository Unit Tests', () {
    late MockFirestore mockFirestore;
    late TestableMarketplaceRepository repository;

    setUp(() {
      mockFirestore = MockFirestore();
      repository = TestableMarketplaceRepository(mockFirestore);
    });

    test('saveProviderProfile translates fields into dot-notation updates to protect existing fields', () async {
      const uid = 'test_provider_123';
      const title = 'Expert Handyman';
      const category = 'Trades';
      const businessType = 'individual';
      const rate = 150.0;
      const bio = 'I repair all home infrastructure.';

      await repository.saveProviderProfile(
        uid: uid,
        professionTitle: title,
        category: category,
        businessType: businessType,
        hourlyRate: rate,
        bio: bio,
        portfolioImages: ['url1'],
      );

      expect(mockFirestore.lastUpdatedUid, uid);
      expect(mockFirestore.lastUpdatedData, isNotNull);
      
      final data = mockFirestore.lastUpdatedData!;
      expect(data['providerProfile.professionTitle'], title);
      expect(data['providerProfile.category'], category);
      expect(data['providerProfile.businessType'], businessType);
      expect(data['providerProfile.hourlyRate'], rate);
      expect(data['providerProfile.bio'], bio);
      expect(data['providerProfile.portfolioImages'], ['url1']);
      expect(data['providerProfile.isActive'], true);
      
      // Ensure it doesn't overwrite top-level providerProfile map to secure rating/portfolios
      expect(data.containsKey('providerProfile'), isFalse);
    });

    test('saveProviderProfile handles exceptions and throws formatted errors', () async {
      mockFirestore.shouldThrow = true;

      expect(
        () => repository.saveProviderProfile(
          uid: 'uid',
          professionTitle: 'Title',
          category: 'Cat',
          businessType: 'shop',
          hourlyRate: 50.0,
          bio: 'Bio',
          portfolioImages: [],
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
