import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:hubble/firebase_options.dart';
import 'package:hubble/features/auth/domain/models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SeederApp());
}

class SeederApp extends StatelessWidget {
  const SeederApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SeederWidget(),
    );
  }
}

class SeederWidget extends StatefulWidget {
  const SeederWidget({super.key});

  @override
  State<SeederWidget> createState() => _SeederWidgetState();
}

class _SeederWidgetState extends State<SeederWidget> {
  bool _isSeeding = false;
  String _status = 'Ready to seed 20 accounts to live Firebase.';

  Future<void> _seedDatabase() async {
    setState(() {
      _isSeeding = true;
      _status = 'Seeding in progress...';
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final usersCollection = firestore.collection('users');

      // Generate 20 realistic Zambian accounts
      final List<UserModel> accountsToSeed = _generateAccounts();

      int count = 0;
      for (var account in accountsToSeed) {
        await usersCollection.doc(account.uid).set(account.toMap());
        count++;
        setState(() {
          _status = 'Seeded $count / 20 accounts...';
        });
      }

      setState(() {
        _isSeeding = false;
        _status = 'Successfully seeded $count accounts! You can close this app.';
      });
      debugPrint('=== SUCCESSFULLY SEEDED 20 ACCOUNTS TO FIREBASE ===');
    } catch (e) {
      setState(() {
        _isSeeding = false;
        _status = 'Error seeding: $e';
      });
      debugPrint('Error seeding: $e');
    }
  }

  List<UserModel> _generateAccounts() {
    List<UserModel> accounts = [];

    // 1. A Maid offering Monthly Services
    accounts.add(_createCustomAccount(
      uid: 'seeded_maid_1',
      firstName: 'Bupe',
      lastName: 'Chilengwe',
      email: 'bupe.maid@example.com',
      isProvider: true,
      businessType: 'individual',
      category: 'Home Services',
      professionTitle: 'Professional Maid & Housekeeper',
      bio: 'I offer comprehensive house cleaning, laundry, and cooking services. I am available for full-time monthly arrangements or regular weekly visits to keep your home spotless.',
      hourlyRate: 1500.0, // Represents monthly base rate for now
      rating: 4.8,
      jobsCompleted: 34,
      lat: -15.4166,
      lng: 28.2833, // Lusaka
      gender: 'women',
      picId: 44,
    ));

    // 2. A Tutor charging per house/session
    accounts.add(_createCustomAccount(
      uid: 'seeded_tutor_1',
      firstName: 'Kondwani',
      lastName: 'Banda',
      email: 'kondwani.tutor@example.com',
      isProvider: true,
      businessType: 'individual',
      category: 'Tutoring',
      professionTitle: 'Mathematics & Science Tutor',
      bio: 'Experienced tutor for Grade 8-12. I charge a fixed rate per house/session regardless of the number of children. Let me help your kids excel in STEM!',
      hourlyRate: 250.0, // Represents per-session rate
      rating: 4.9,
      jobsCompleted: 89,
      lat: -15.3875,
      lng: 28.3228,
      gender: 'men',
      picId: 22,
    ));

    // 3. A Plumbing Shop
    accounts.add(_createCustomAccount(
      uid: 'seeded_shop_plumbing',
      firstName: 'Lusaka',
      lastName: 'Pipes & Fixes',
      email: 'contact@lusakapipes.com',
      isProvider: true,
      businessType: 'shop',
      category: 'Home Repairs',
      professionTitle: 'Plumbing Hardware & Repairs',
      bio: 'We sell top-quality plumbing materials and offer dispatch repair services. Whether you need a new geyser or a pipe fixed, our certified team is ready.',
      hourlyRate: 400.0,
      rating: 4.5,
      jobsCompleted: 156,
      lat: -15.4000,
      lng: 28.3000,
      gender: 'men',
      picId: 60,
    ));

    // 4. An Electrician (Hourly)
    accounts.add(_createCustomAccount(
      uid: 'seeded_electrician_1',
      firstName: 'Mabvuto',
      lastName: 'Tembo',
      email: 'mabvuto.sparks@example.com',
      isProvider: true,
      businessType: 'individual',
      category: 'Home Repairs',
      professionTitle: 'Licensed Electrician',
      bio: 'Fast and safe electrical troubleshooting, wiring, and installations. I charge strictly per hour of work. Safety is my number one priority.',
      hourlyRate: 150.0,
      rating: 4.7,
      jobsCompleted: 42,
      lat: -12.8024,
      lng: 28.2069, // Kitwe
      gender: 'men',
      picId: 15,
    ));

    // 5. A Beauty Parlor Shop
    accounts.add(_createCustomAccount(
      uid: 'seeded_shop_beauty',
      firstName: 'Glamour',
      lastName: 'Studio Kitwe',
      email: 'hello@glamourkitwe.com',
      isProvider: true,
      businessType: 'shop',
      category: 'Beauty & Spa',
      professionTitle: 'Premium Beauty Salon',
      bio: 'A full-service beauty parlor. We offer hair styling, manicures, pedicures, and makeup. Book an appointment with one of our 5 resident stylists.',
      hourlyRate: 300.0,
      rating: 4.9,
      jobsCompleted: 210,
      lat: -12.8167,
      lng: 28.2000,
      gender: 'women',
      picId: 65,
    ));

    // 6. A Freelance Photographer
    accounts.add(_createCustomAccount(
      uid: 'seeded_photo_1',
      firstName: 'Chilufya',
      lastName: 'Mulenga',
      email: 'chilufya.lens@example.com',
      isProvider: true,
      businessType: 'individual',
      category: 'Photography',
      professionTitle: 'Event Photographer',
      bio: 'Capturing your best moments. I cover weddings, corporate events, and personal photoshoots. High-resolution digital copies delivered within 48 hours.',
      hourlyRate: 500.0,
      rating: 4.6,
      jobsCompleted: 27,
      lat: -15.4200,
      lng: 28.2900,
      gender: 'women',
      picId: 33,
    ));
    
    // 7. Event Planner
    accounts.add(_createCustomAccount(
      uid: 'seeded_planner_1',
      firstName: 'Thabo',
      lastName: 'Mwale',
      email: 'thabo.events@example.com',
      isProvider: true,
      businessType: 'individual',
      category: 'Event Planning',
      professionTitle: 'Wedding & Party Planner',
      bio: 'I take the stress out of your big day. From catering to venue decoration, I manage everything. Contact me for custom quotes.',
      hourlyRate: 800.0,
      rating: 5.0,
      jobsCompleted: 15,
      lat: -15.3900,
      lng: 28.3100,
      gender: 'women',
      picId: 50,
    ));

    // Generate remaining dummy clients
    for (int i = 0; i < 5; i++) {
      accounts.add(_createCustomAccount(
        uid: 'seeded_client_$i',
        firstName: 'Client${i + 1}',
        lastName: 'User',
        email: 'client${i + 1}@example.com',
        isProvider: false,
        businessType: 'individual',
        category: '',
        professionTitle: '',
        bio: '',
        hourlyRate: 0.0,
        rating: 4.0 + (i * 0.2),
        jobsCompleted: 0,
        lat: -15.4000 + (i * 0.01),
        lng: 28.3000 + (i * 0.01),
        gender: i % 2 == 0 ? 'men' : 'women',
        picId: 70 + i,
      ));
    }

    return accounts;
  }

  UserModel _createCustomAccount({
    required String uid,
    required String firstName,
    required String lastName,
    required String email,
    required bool isProvider,
    required String businessType,
    required String category,
    required String professionTitle,
    required String bio,
    required double hourlyRate,
    required double rating,
    required int jobsCompleted,
    required double lat,
    required double lng,
    required String gender,
    required int picId,
  }) {
    
    final List<String> blackMenPics = [
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&q=80',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80',
      'https://images.unsplash.com/photo-1522529599102-193c0d76b5b6?w=400&q=80',
      'https://images.unsplash.com/photo-1531384441138-2736e62e0919?w=400&q=80',
      'https://images.unsplash.com/photo-1530268729831-4b0b9e170218?w=400&q=80',
      'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=400&q=80',
      'https://images.unsplash.com/photo-1528892952291-009c663ce843?w=400&q=80',
    ];

    final List<String> blackWomenPics = [
      'https://images.unsplash.com/photo-1531123897727-8f129e1bfa8ea?w=400&q=80',
      'https://images.unsplash.com/photo-1543269664-56d93c1b41a6?w=400&q=80',
      'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=400&q=80',
      'https://images.unsplash.com/photo-1515023115689-589c33041d3c?w=400&q=80',
      'https://images.unsplash.com/photo-1563351672-62b74891a28a?w=400&q=80',
      'https://images.unsplash.com/photo-1531123414708-f47f29bb5b67?w=400&q=80',
      'https://images.unsplash.com/photo-1523825036634-aab3cce0691e?w=400&q=80',
    ];
    
    String profileImageURL = '';
    if (gender == 'men') {
      profileImageURL = blackMenPics[picId % blackMenPics.length];
    } else {
      profileImageURL = blackWomenPics[picId % blackWomenPics.length];
    }

    
    final portfolioImages = <String>[];
    if (isProvider) {
      for (int j = 0; j < 3; j++) {
        portfolioImages.add('https://picsum.photos/seed/${uid}_$j/600/400');
      }
    }

    final personalInfo = PersonalInfo(
      firstName: firstName,
      lastName: lastName,
      phoneNumber: '+260970000${picId.toString().padLeft(2, '0')}',
      email: email,
      isVerified: true,
      profileImageURL: profileImageURL,
    );
    
    final currentLocation = CurrentLocation(
      latitude: lat,
      longitude: lng,
      geohash: 'khgabc', // Dummy geohash
    );
    
    final clientProfile = ClientProfile(
      ratingAsClient: isProvider ? 0.0 : rating,
      totalBookingsMade: isProvider ? 0 : 5,
    );
    
    final providerProfile = ProviderProfile(
      isActive: isProvider,
      professionTitle: professionTitle,
      category: category,
      hourlyRate: hourlyRate,
      currency: 'ZMW',
      bio: bio,
      ratingAsProvider: isProvider ? rating : 0.0,
      totalJobsCompleted: jobsCompleted,
      portfolioImages: portfolioImages,
      businessType: businessType,
      listingsCount: isProvider ? 1 : 0,
    );
    
    final vaultSettings = VaultSettings(
      isAutoSaveEnabled: false,
      autoSavePercentage: 0.0,
      vaultBalance: 0.0,
    );
    
    final investmentPortfolio = InvestmentPortfolio(
      isActive: false,
      totalEstimatedValue: 0.0,
      assets: [],
    );
    
    final financialLedger = FinancialLedger(
      currency: 'ZMW',
      availableBalance: 1500.0,
      vaultSettings: vaultSettings,
      investmentPortfolio: investmentPortfolio,
    );

    return UserModel(
      uid: uid,
      email: personalInfo.email,
      displayName: '${personalInfo.firstName} ${personalInfo.lastName}'.trim(),
      role: isProvider ? UserRole.provider : UserRole.client,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      personalInfo: personalInfo,
      currentLocation: currentLocation,
      clientProfile: clientProfile,
      providerProfile: providerProfile,
      financialLedger: financialLedger,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hubble DB Seeder'),
        backgroundColor: Colors.indigo,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.data_usage, size: 80, color: Colors.indigo),
              const SizedBox(height: 24),
              Text(
                'Phase 2: Live Database Seeder',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _status,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_isSeeding)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _seedDatabase,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Inject 20 Accounts'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
