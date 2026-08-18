const admin = require('firebase-admin');

// Initialize Firebase Admin SDK using application default credentials or project config
admin.initializeApp({
  projectId: 'hubble-intentgenesiscorp',
});

const db = admin.firestore();

async function seedFirestore() {
  console.log('=== STARTING ADMIN FIRESTORE POPULATION FOR PROJECT: hubble-intentgenesiscorp ===');

  // 1. Seed Users Collection
  const users = [
    {
      uid: 'dummy_1',
      email: 'plumber.joe@example.com',
      displayName: 'Joe The Plumber',
      role: 'provider',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      personalInfo: {
        firstName: 'Joe',
        lastName: 'Smith',
        phoneNumber: '555-0101',
        email: 'plumber.joe@example.com',
        isVerified: true,
        profileImageURL: 'https://images.unsplash.com/photo-1540569014015-19a7be504e3a?auto=format&fit=crop&q=80',
      },
      currentLocation: { latitude: -15.4167, longitude: 28.2833, geohash: '' },
      clientProfile: { ratingAsClient: 5.0, totalBookingsMade: 2 },
      providerProfile: {
        isActive: true,
        professionTitle: 'Master Plumber',
        category: 'Home Repair & Trades',
        hourlyRate: 65.0,
        currency: 'ZMW',
        bio: 'Over 10 years fixing leaks, unblocking drains, and installing pipes across Lusaka.',
        ratingAsProvider: 4.8,
        totalJobsCompleted: 24,
        portfolioImages: ['https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=600&q=80'],
        businessType: 'individual',
        listingsCount: 2,
      },
      financialLedger: {
        currency: 'ZMW',
        availableBalance: 1250.0,
        vaultSettings: { isAutoSaveEnabled: false, autoSavePercentage: 0.0, vaultBalance: 0.0 },
        investmentPortfolio: { isActive: false, totalEstimatedValue: 0.0, assets: [] }
      }
    },
    {
      uid: 'dummy_2',
      email: 'sarah.cuts@example.com',
      displayName: "Sarah's Hair Studio",
      role: 'provider',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      personalInfo: {
        firstName: 'Sarah',
        lastName: 'Jenkins',
        phoneNumber: '555-0102',
        email: 'sarah.cuts@example.com',
        isVerified: true,
        profileImageURL: 'https://images.unsplash.com/photo-1595152772835-219674b2a8a6?auto=format&fit=crop&q=80',
      },
      currentLocation: { latitude: -15.4200, longitude: 28.2850, geohash: '' },
      clientProfile: { ratingAsClient: 4.9, totalBookingsMade: 5 },
      providerProfile: {
        isActive: true,
        professionTitle: 'Hair Stylist & Skincare',
        category: 'Beauty & Spa Services',
        hourlyRate: 45.0,
        currency: 'ZMW',
        bio: 'Specializing in modern braid cuts, hair styling, and organic skincare spa treatments.',
        ratingAsProvider: 4.9,
        totalJobsCompleted: 156,
        portfolioImages: ['https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=600&q=80'],
        businessType: 'salon',
        listingsCount: 1,
      },
      financialLedger: {
        currency: 'ZMW',
        availableBalance: 2400.0,
        vaultSettings: { isAutoSaveEnabled: true, autoSavePercentage: 5.0, vaultBalance: 500.0 },
        investmentPortfolio: { isActive: false, totalEstimatedValue: 0.0, assets: [] }
      }
    },
    {
      uid: 'dummy_3',
      email: 'mike.mechanic@example.com',
      displayName: "Mike's Auto Repair",
      role: 'provider',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      personalInfo: {
        firstName: 'Mike',
        lastName: 'Oconnor',
        phoneNumber: '555-0103',
        email: 'mike.mechanic@example.com',
        isVerified: true,
        profileImageURL: 'https://images.unsplash.com/photo-1504222490345-c075b6008014?auto=format&fit=crop&q=80',
      },
      currentLocation: { latitude: -15.4100, longitude: 28.2900, geohash: '' },
      clientProfile: { ratingAsClient: 5.0, totalBookingsMade: 1 },
      providerProfile: {
        isActive: true,
        professionTitle: 'Auto Mechanic',
        category: 'Vehicles',
        hourlyRate: 85.0,
        currency: 'ZMW',
        bio: 'Honest and reliable car repairs, engine diagnostic testing, and brake servicing.',
        ratingAsProvider: 4.7,
        totalJobsCompleted: 89,
        portfolioImages: [],
        businessType: 'garage',
        listingsCount: 1,
      },
      financialLedger: {
        currency: 'ZMW',
        availableBalance: 3100.0,
        vaultSettings: { isAutoSaveEnabled: false, autoSavePercentage: 0.0, vaultBalance: 0.0 },
        investmentPortfolio: { isActive: false, totalEstimatedValue: 0.0, assets: [] }
      }
    },
    {
      uid: 'dummy_5',
      email: 'tech.tom@example.com',
      displayName: "Tom's Tech Support",
      role: 'provider',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      personalInfo: {
        firstName: 'Tom',
        lastName: 'Hanks',
        phoneNumber: '555-0105',
        email: 'tech.tom@example.com',
        isVerified: true,
        profileImageURL: 'https://images.unsplash.com/photo-1531427186611-ecfd6d936c79?auto=format&fit=crop&q=80',
      },
      currentLocation: { latitude: -15.4150, longitude: 28.2750, geohash: '' },
      clientProfile: { ratingAsClient: 4.8, totalBookingsMade: 3 },
      providerProfile: {
        isActive: true,
        professionTitle: 'IT Specialist',
        category: 'Electronics & Mobile',
        hourlyRate: 55.0,
        currency: 'ZMW',
        bio: 'Hardware repairs, laptop screen replacements, virus removal, and network setup.',
        ratingAsProvider: 4.9,
        totalJobsCompleted: 112,
        portfolioImages: [],
        businessType: 'company',
        listingsCount: 2,
      },
      financialLedger: {
        currency: 'ZMW',
        availableBalance: 1850.0,
        vaultSettings: { isAutoSaveEnabled: false, autoSavePercentage: 0.0, vaultBalance: 0.0 },
        investmentPortfolio: { isActive: false, totalEstimatedValue: 0.0, assets: [] }
      }
    }
  ];

  for (const user of users) {
    await db.collection('users').doc(user.uid).set(user, { merge: true });
    console.log(`✓ Seeded User: ${user.displayName} (${user.uid})`);
  }

  // 2. Seed Listings Collection
  const listings = [
    {
      id: 'list_1',
      providerId: 'dummy_1',
      providerName: 'Joe The Plumber',
      providerImage: 'https://images.unsplash.com/photo-1540569014015-19a7be504e3a?auto=format&fit=crop&q=80',
      title: 'Emergency Pipe Leak & Tap Repairs',
      description: '24/7 fast emergency plumbing repairs across Lusaka CBD & suburbs.',
      price: 150.0,
      listingType: 'service',
      billingType: 'hourly',
      category: 'Home Repair & Trades',
      images: ['https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=600&q=80'],
      stockCount: 1,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {
      id: 'list_2',
      providerId: 'dummy_2',
      providerName: "Sarah's Hair Studio",
      providerImage: 'https://images.unsplash.com/photo-1595152772835-219674b2a8a6?auto=format&fit=crop&q=80',
      title: 'Full Hair Styling & Skincare Spa Package',
      description: 'Professional hair braid styling, wash, blow dry, and natural skincare treatment.',
      price: 280.0,
      listingType: 'service',
      billingType: 'fixed',
      category: 'Beauty & Spa Services',
      images: ['https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=600&q=80'],
      stockCount: 1,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {
      id: 'list_3',
      providerId: 'dummy_5',
      providerName: "Tom's Tech Support",
      providerImage: 'https://images.unsplash.com/photo-1531427186611-ecfd6d936c79?auto=format&fit=crop&q=80',
      title: 'Laptop Screen Replacement & Virus Clean',
      description: 'Hardware repair, RAM upgrades, malware removal, and speed optimization.',
      price: 220.0,
      listingType: 'service',
      billingType: 'fixed',
      category: 'Electronics & Mobile',
      images: ['https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?auto=format&fit=crop&w=600&q=80'],
      stockCount: 1,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {
      id: 'list_5',
      providerId: 'dummy_5',
      providerName: "Tom's Tech Support",
      providerImage: 'https://images.unsplash.com/photo-1531427186611-ecfd6d936c79?auto=format&fit=crop&q=80',
      title: 'Wireless Noise-Cancelling Headphones',
      description: 'Brand new bluetooth wireless headphones with deep bass and HD microphone.',
      price: 450.0,
      listingType: 'product',
      billingType: 'perItem',
      category: 'Electronics & Mobile',
      images: ['https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=600&q=80'],
      stockCount: 15,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }
  ];

  for (const listing of listings) {
    await db.collection('listings').doc(listing.id).set(listing, { merge: true });
    console.log(`✓ Seeded Listing: ${listing.title} (${listing.id})`);
  }

  // 3. Seed Bus Trips Collection
  const busTrips = [
    {
      id: 'PWR-001',
      companyName: 'Power Tools Bus',
      origin: 'Lusaka',
      destination: 'Livingstone',
      departureTime: new Date(Date.now() + 8 * 3600 * 1000).toISOString(),
      arrivalTime: new Date(Date.now() + 14 * 3600 * 1000).toISOString(),
      price: 350.0,
      busClass: 'Express',
      totalSeats: 44,
      companyColorValue: 0xFF1E40AF,
      seats: Array.from({ length: 44 }, (_, i) => ({
        id: `${Math.floor(i / 4) + 1}${['A', 'B', 'C', 'D'][i % 4]}`,
        status: i % 5 === 0 && i !== 0 ? 'booked' : 'available'
      }))
    },
    {
      id: 'JLD-002',
      companyName: 'Juldan Motors',
      origin: 'Lusaka',
      destination: 'Kitwe',
      departureTime: new Date(Date.now() + 7.5 * 3600 * 1000).toISOString(),
      arrivalTime: new Date(Date.now() + 12 * 3600 * 1000).toISOString(),
      price: 180.0,
      busClass: 'Standard',
      totalSeats: 52,
      companyColorValue: 0xFFF59E0B,
      seats: Array.from({ length: 52 }, (_, i) => ({
        id: `${Math.floor(i / 4) + 1}${['A', 'B', 'C', 'D'][i % 4]}`,
        status: i % 4 === 0 && i !== 0 ? 'booked' : 'available'
      }))
    }
  ];

  for (const trip of busTrips) {
    await db.collection('bus_trips').doc(trip.id).set(trip, { merge: true });
    console.log(`✓ Seeded Bus Trip: ${trip.companyName} (${trip.id})`);
  }

  console.log('=== SUCCESS: ALL FIRESTORE COLLECTIONS SEEDED LIVE ===');
}

seedFirestore().then(() => process.exit(0)).catch(err => {
  console.error('Error seeding Firestore:', err);
  process.exit(1);
});
