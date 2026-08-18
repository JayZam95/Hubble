import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:hubble/features/marketplace/data/repositories/marketplace_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MarketplaceRepository repository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = MarketplaceRepository(firestore: fakeFirestore);
  });

  test('searchProviders returns filtered users based on query (including inactive if matched)', () async {
    // Add dummy active provider
    await fakeFirestore.collection('users').doc('1').set({
      'providerProfile': {
        'isActive': true,
        'professionTitle': 'Plumber',
        'category': 'Repairs',
        'bio': 'Expert plumber',
        'hourlyRate': 50.0,
        'currency': 'USD',
        'ratingAsProvider': 4.5,
        'totalJobsCompleted': 10,
        'portfolioImages': [],
      },
      'personalInfo': {'firstName': 'John', 'lastName': 'Doe', 'email': 'john@example.com', 'phoneNumber': '123', 'isVerified': true, 'profileImageURL': ''},
      'email': 'john@example.com',
      'displayName': 'John Doe',
      'createdAt': DateTime.now(),
    });
    
    // Add dummy inactive provider
    await fakeFirestore.collection('users').doc('2').set({
      'providerProfile': {
        'isActive': false,
        'professionTitle': 'Plumber',
      },
      'personalInfo': {'firstName': 'Bob', 'lastName': 'Smith', 'email': 'bob@example.com', 'phoneNumber': '123', 'isVerified': true, 'profileImageURL': ''},
      'email': 'bob@example.com',
      'displayName': 'Bob Smith',
      'createdAt': DateTime.now(),
    });

    // Add dummy active provider not matching
    await fakeFirestore.collection('users').doc('3').set({
      'providerProfile': {
        'isActive': true,
        'professionTitle': 'Electrician',
        'category': 'Repairs',
        'bio': 'Wiring expert',
        'hourlyRate': 60.0,
        'currency': 'USD',
        'ratingAsProvider': 4.8,
        'totalJobsCompleted': 20,
        'portfolioImages': [],
      },
      'personalInfo': {'firstName': 'Jane', 'lastName': 'Doe', 'email': 'jane@example.com', 'phoneNumber': '123', 'isVerified': true, 'profileImageURL': ''},
      'email': 'jane@example.com',
      'displayName': 'Jane Doe',
      'createdAt': DateTime.now(),
    });

    final results = await repository.searchProviders('plumber');
    expect(results.length, 2); // Both active and inactive plumbers
    expect(results.first.providerProfile.professionTitle, 'Plumber');
    
    final allResults = await repository.searchProviders('');
    expect(allResults.length, 3); // All 3 have professionTitle
  });
}
