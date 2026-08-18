import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/marketplace/domain/models/bus_trip_model.dart';

class DummyDataSeeder {
  static Future<void> seedDatabase() async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    final List<Map<String, dynamic>> dummyProviders = [
      {
        'id': 'dummy_1',
        'email': 'kondwani.phiri@example.com',
        'displayName': 'Kondwani Phiri',
        'roles': ['client', 'provider'],
        'personalInfo': {
          'firstName': 'Kondwani',
          'lastName': 'Phiri',
          'phoneNumber': '+260 977 101010',
          'dateOfBirth': '1988-04-14',
          'profileImageURL': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fit=crop&w=300&q=80',
        },
        'providerProfile': {
          'professionTitle': 'Master Plumber',
          'bio': 'Over 10 years fixing leaks, boreholes and installing pipes across Lusaka.',
          'hourlyRate': 65.0,
          'yearsOfExperience': 10,
          'ratingAsProvider': 4.8,
          'totalProviderReviews': 24,
          'isAvailable': true,
          'searchKeywords': ['plumber', 'pipes', 'leak', 'water', 'kondwani'],
        },
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'dummy_2',
        'email': 'mutinta.mwale@example.com',
        'displayName': 'Mutinta Mwale',
        'roles': ['client', 'provider'],
        'personalInfo': {
          'firstName': 'Mutinta',
          'lastName': 'Mwale',
          'phoneNumber': '+260 966 202020',
          'dateOfBirth': '1992-05-12',
          'profileImageURL': 'https://images.unsplash.com/photo-1589156280159-27698a70f29e?auto=format&fit=crop&w=300&q=80',
        },
        'providerProfile': {
          'professionTitle': 'Hair & Beauty Stylist',
          'bio': 'Specializing in modern African braids, wigs, makeup and vibrant styling.',
          'hourlyRate': 45.0,
          'yearsOfExperience': 6,
          'ratingAsProvider': 4.9,
          'totalProviderReviews': 156,
          'isAvailable': true,
          'searchKeywords': ['hair', 'stylist', 'barber', 'salon', 'beauty', 'mutinta'],
        },
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'dummy_3',
        'email': 'bwalya.chanda@example.com',
        'displayName': 'Bwalya Chanda',
        'roles': ['client', 'provider'],
        'personalInfo': {
          'firstName': 'Bwalya',
          'lastName': 'Chanda',
          'phoneNumber': '+260 955 303030',
          'dateOfBirth': '1985-11-20',
          'profileImageURL': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80',
        },
        'providerProfile': {
          'professionTitle': 'Auto Mechanic & Electrician',
          'bio': 'Honest and reliable vehicle diagnostics and engine repairs in Rhodespark.',
          'hourlyRate': 85.0,
          'yearsOfExperience': 14,
          'ratingAsProvider': 4.7,
          'totalProviderReviews': 89,
          'isAvailable': true,
          'searchKeywords': ['mechanic', 'auto', 'car', 'repair', 'bwalya'],
        },
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'dummy_4',
        'email': 'chileshe.mwamba@example.com',
        'displayName': 'Chileshe Mwamba',
        'roles': ['client', 'provider'],
        'personalInfo': {
          'firstName': 'Chileshe',
          'lastName': 'Mwamba',
          'phoneNumber': '+260 978 404040',
          'dateOfBirth': '1990-03-15',
          'profileImageURL': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=300&q=80',
        },
        'providerProfile': {
          'professionTitle': 'Professional House Cleaner',
          'bio': 'Deep home cleaning, laundry services, and office sanitization.',
          'hourlyRate': 30.0,
          'yearsOfExperience': 5,
          'ratingAsProvider': 4.6,
          'totalProviderReviews': 42,
          'isAvailable': true,
          'searchKeywords': ['clean', 'cleaning', 'house', 'maid', 'chileshe'],
        },
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'dummy_5',
        'email': 'thandiwe.tembo@example.com',
        'displayName': 'Thandiwe Tembo',
        'roles': ['client', 'provider'],
        'personalInfo': {
          'firstName': 'Thandiwe',
          'lastName': 'Tembo',
          'phoneNumber': '+260 967 505050',
          'dateOfBirth': '1994-08-30',
          'profileImageURL': 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?auto=format&fit=crop&w=300&q=80',
        },
        'providerProfile': {
          'professionTitle': 'IT & Device Specialist',
          'bio': 'Laptop screen repairs, smartphone flashing, networking, and software setup.',
          'hourlyRate': 55.0,
          'yearsOfExperience': 7,
          'ratingAsProvider': 4.9,
          'totalProviderReviews': 112,
          'isAvailable': true,
          'searchKeywords': ['tech', 'computer', 'it', 'support', 'network', 'thandiwe'],
        },
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'dummy_6',
        'email': 'nchimunya.banda@example.com',
        'displayName': 'Nchimunya Banda',
        'roles': ['client', 'provider'],
        'personalInfo': {
          'firstName': 'Nchimunya',
          'lastName': 'Banda',
          'phoneNumber': '+260 950 606060',
          'dateOfBirth': '1987-04-18',
          'profileImageURL': 'https://images.unsplash.com/photo-1567532939604-b6b5b0db2604?auto=format&fit=crop&w=300&q=80',
        },
        'providerProfile': {
          'professionTitle': 'Custom Baker & Caterer',
          'bio': 'Delicious wedding cakes, event catering, and traditional Zambian bites.',
          'hourlyRate': 40.0,
          'yearsOfExperience': 12,
          'ratingAsProvider': 5.0,
          'totalProviderReviews': 200,
          'isAvailable': true,
          'searchKeywords': ['cake', 'bake', 'food', 'pastry', 'restaurant', 'nchimunya'],
        },
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'dummy_7',
        'email': 'lubinda.zimba@example.com',
        'displayName': 'Lubinda Zimba',
        'roles': ['client', 'provider'],
        'personalInfo': {
          'firstName': 'Lubinda',
          'lastName': 'Zimba',
          'phoneNumber': '+260 971 707070',
          'dateOfBirth': '1991-09-22',
          'profileImageURL': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=300&q=80',
        },
        'providerProfile': {
          'professionTitle': 'City Taxi & Cab Driver',
          'bio': 'Safe, air-conditioned city rides and airport transfers across Lusaka.',
          'hourlyRate': 25.0,
          'yearsOfExperience': 6,
          'ratingAsProvider': 4.95,
          'totalProviderReviews': 310,
          'isAvailable': true,
          'searchKeywords': ['taxi', 'ride', 'drive', 'transport', 'lubinda', 'cab'],
        },
        'createdAt': FieldValue.serverTimestamp(),
      }
    ];

    for (var provider in dummyProviders) {
      final docRef = firestore.collection('users').doc(provider['id']);
      batch.set(docRef, provider, SetOptions(merge: true));
    }

    try {
      await batch.commit();
      debugPrint('=== SUCCESSFULLY SEEDED 7 DUMMY PROVIDERS ===');
    } catch (e) {
      debugPrint('=== ERROR SEEDING DUMMY PROVIDERS: $e ===');
    }
  }

  static List<SeatModel> _generateSeats(int count, {int occupiedEvery = 4}) {
    final List<SeatModel> seats = [];
    const letters = ['A', 'B', 'C', 'D'];
    int row = 1;
    int generated = 0;

    while (generated < count) {
      for (int col = 0; col < 4 && generated < count; col++) {
        final id = '$row${letters[col]}';
        final isBooked = (generated % occupiedEvery) == 0 && generated != 0;
        seats.add(SeatModel(
          id: id,
          status: isBooked ? SeatStatus.booked : SeatStatus.available,
        ));
        generated++;
      }
      row++;
    }
    return seats;
  }

  static DateTime _todayAt(int hour, int minute) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  static DateTime _tomorrowAt(int hour, int minute) {
    final now = DateTime.now().add(const Duration(days: 1));
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  static Future<void> seedBusTrips() async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    final List<BusTripModel> dummyTrips = [
      BusTripModel(
        id: 'PWR-001',
        companyName: 'Power Tools Bus',
        origin: 'Lusaka',
        destination: 'Livingstone',
        departureTime: _todayAt(6, 0),
        arrivalTime: _todayAt(12, 30),
        price: 350.0,
        busClass: 'Express',
        totalSeats: 44,
        companyColorValue: 0xFF1E40AF,
        seats: _generateSeats(44, occupiedEvery: 5),
      ),
      BusTripModel(
        id: 'PWR-002',
        companyName: 'Power Tools Bus',
        origin: 'Lusaka',
        destination: 'Kitwe',
        departureTime: _todayAt(8, 30),
        arrivalTime: _todayAt(13, 0),
        price: 220.0,
        busClass: 'Luxury',
        totalSeats: 44,
        companyColorValue: 0xFF1E40AF,
        seats: _generateSeats(44, occupiedEvery: 4),
      ),
      BusTripModel(
        id: 'PWR-003',
        companyName: 'Power Tools Bus',
        origin: 'Lusaka',
        destination: 'Ndola',
        departureTime: _todayAt(14, 0),
        arrivalTime: _todayAt(18, 0),
        price: 200.0,
        busClass: 'Executive',
        totalSeats: 44,
        companyColorValue: 0xFF1E40AF,
        seats: _generateSeats(44, occupiedEvery: 6),
      ),
      BusTripModel(
        id: 'PWR-004',
        companyName: 'Power Tools Bus',
        origin: 'Lusaka',
        destination: 'Solwezi',
        departureTime: _todayAt(20, 0),
        arrivalTime: _tomorrowAt(6, 0),
        price: 450.0,
        busClass: 'Sleeper',
        totalSeats: 44,
        companyColorValue: 0xFF1E40AF,
        seats: _generateSeats(44, occupiedEvery: 3),
      ),
      BusTripModel(
        id: 'JLD-001',
        companyName: 'Juldan Motors',
        origin: 'Lusaka',
        destination: 'Kitwe',
        departureTime: _todayAt(7, 0),
        arrivalTime: _todayAt(11, 30),
        price: 180.0,
        busClass: 'Standard',
        totalSeats: 52,
        companyColorValue: 0xFFF59E0B,
        seats: _generateSeats(52, occupiedEvery: 3),
      ),
      BusTripModel(
        id: 'JLD-002',
        companyName: 'Juldan Motors',
        origin: 'Lusaka',
        destination: 'Ndola',
        departureTime: _todayAt(9, 15),
        arrivalTime: _todayAt(13, 15),
        price: 160.0,
        busClass: 'Standard',
        totalSeats: 52,
        companyColorValue: 0xFFF59E0B,
        seats: _generateSeats(52, occupiedEvery: 4),
      ),
      BusTripModel(
        id: 'MZH-001',
        companyName: 'Mazhandu Family Bus',
        origin: 'Lusaka',
        destination: 'Ndola',
        departureTime: _todayAt(6, 30),
        arrivalTime: _todayAt(10, 30),
        price: 170.0,
        busClass: 'Standard',
        totalSeats: 52,
        companyColorValue: 0xFFEF4444,
        seats: _generateSeats(52, occupiedEvery: 6),
      ),
      BusTripModel(
        id: 'MZH-002',
        companyName: 'Mazhandu Family Bus',
        origin: 'Lusaka',
        destination: 'Livingstone',
        departureTime: _todayAt(10, 0),
        arrivalTime: _todayAt(16, 30),
        price: 340.0,
        busClass: 'Express',
        totalSeats: 44,
        companyColorValue: 0xFFEF4444,
        seats: _generateSeats(44, occupiedEvery: 5),
      ),
    ];

    for (var trip in dummyTrips) {
      final docRef = firestore.collection('bus_trips').doc(trip.id);
      batch.set(docRef, trip.toMap(), SetOptions(merge: true));
    }

    try {
      await batch.commit();
      debugPrint('=== SUCCESSFULLY SEEDED BUS TRIPS ===');
    } catch (e) {
      debugPrint('=== ERROR SEEDING BUS TRIPS: $e ===');
    }
  }

  static Future<void> seedSampleListings() async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore.collection('listings').limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final batch = firestore.batch();
    final List<Map<String, dynamic>> sampleListings = [
      {
        'id': 'list_1',
        'providerId': 'dummy_1',
        'providerName': 'Joe The Plumber',
        'providerImage': 'https://images.unsplash.com/photo-1540569014015-19a7be504e3a?auto=format&fit=crop&q=80',
        'title': 'Emergency Pipe Leak & Tap Repairs',
        'description': '24/7 fast emergency plumbing repairs across Lusaka CBD & suburbs.',
        'price': 150.0,
        'listingType': 'service',
        'billingType': 'hourly',
        'category': 'Trades & Repair',
        'images': ['https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=600&q=80'],
        'stockCount': 1,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'list_2',
        'providerId': 'dummy_2',
        'providerName': 'Sarahs Hair Studio',
        'providerImage': 'https://images.unsplash.com/photo-1595152772835-219674b2a8a6?auto=format&fit=crop&q=80',
        'title': 'Full Hair Styling & Skincare Spa Package',
        'description': 'Professional hair braid styling, wash, blow dry, and natural skincare treatment.',
        'price': 280.0,
        'listingType': 'service',
        'billingType': 'fixed',
        'category': 'Beauty & Wellness',
        'images': ['https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=600&q=80'],
        'stockCount': 1,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'list_3',
        'providerId': 'dummy_5',
        'providerName': 'Toms Tech Support',
        'providerImage': 'https://images.unsplash.com/photo-1531427186611-ecfd6d936c79?auto=format&fit=crop&q=80',
        'title': 'Laptop Screen Replacement & Virus Clean',
        'description': 'Hardware repair, RAM upgrades, malware removal, and speed optimization.',
        'price': 220.0,
        'listingType': 'service',
        'billingType': 'fixed',
        'category': 'Technology & Software',
        'images': ['https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?auto=format&fit=crop&w=600&q=80'],
        'stockCount': 1,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'list_4',
        'providerId': 'dummy_6',
        'providerName': 'Fresh Bakes by Maria',
        'providerImage': 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?auto=format&fit=crop&q=80',
        'title': 'Custom Birthday & Wedding Cake (2-Tier)',
        'description': 'Freshly baked custom decorated cake with choice of vanilla, chocolate, or red velvet.',
        'price': 350.0,
        'listingType': 'product',
        'billingType': 'perItem',
        'category': 'Food & Catering',
        'images': ['https://images.unsplash.com/photo-1578985545062-69928b1d9587?auto=format&fit=crop&w=600&q=80'],
        'stockCount': 10,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'list_5',
        'providerId': 'dummy_5',
        'providerName': 'Toms Tech Support',
        'providerImage': 'https://images.unsplash.com/photo-1531427186611-ecfd6d936c79?auto=format&fit=crop&q=80',
        'title': 'Wireless Noise-Cancelling Headphones',
        'description': 'Brand new bluetooth wireless headphones with deep bass and HD microphone.',
        'price': 450.0,
        'listingType': 'product',
        'billingType': 'perItem',
        'category': 'Electronics & Gadgets',
        'images': ['https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=600&q=80'],
        'stockCount': 15,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (var l in sampleListings) {
      final docRef = firestore.collection('listings').doc(l['id']);
      batch.set(docRef, l, SetOptions(merge: true));
    }

    try {
      await batch.commit();
      debugPrint('=== SUCCESSFULLY SEEDED SAMPLE LISTINGS ===');
    } catch (e) {
      debugPrint('=== ERROR SEEDING SAMPLE LISTINGS: $e ===');
    }
  }

  static Future<void> seedAllMockData() async {
    debugPrint('=== STARTING MASTER FIREBASE DATA SEEDING ===');
    await seedDatabase();
    await seedBusTrips();
    await seedSampleListings();
    debugPrint('=== MASTER FIREBASE DATA SEEDING COMPLETE ===');
  }
}
