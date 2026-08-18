const admin = require('firebase-admin');
const { faker } = require('@faker-js/faker');

// Initialize Firebase Admin (assuming default application credentials)
admin.initializeApp({
  projectId: 'hubble-intentgenesiscorp',
});

const db = admin.firestore();

// Real-world scenarios for a full marketplace
const providerScenarios = [
  {
    professionTitle: 'Math & Science Tutor',
    category: 'Education',
    businessType: 'individual',
    listings: [
      { title: 'In-Person Math Tutoring', description: 'Comprehensive high school math tutoring per session.', price: 150, listingType: 'service', billingType: 'perItem' },
      { title: 'Monthly Exam Prep Package', description: 'Intensive monthly tutoring for final exams.', price: 1200, listingType: 'service', billingType: 'monthly' }
    ]
  },
  {
    professionTitle: 'Professional Cleaning Services',
    category: 'Home Services',
    businessType: 'shop',
    listings: [
      { title: 'Standard House Cleaning', description: 'Complete cleaning of a 2-bedroom house.', price: 300, listingType: 'service', billingType: 'fixed' },
      { title: 'Deep Cleaning (Hourly)', description: 'Thorough deep cleaning services billed by the hour.', price: 75, listingType: 'service', billingType: 'hourly' },
      { title: 'Monthly Maid Service', description: 'Dedicated maid for monthly upkeep.', price: 2500, listingType: 'service', billingType: 'monthly' }
    ]
  },
  {
    professionTitle: 'City Hardware Store',
    category: 'Retail',
    businessType: 'shop',
    listings: [
      { title: 'Cordless Power Drill 20V', description: 'Heavy-duty cordless drill with 2 batteries.', price: 1400, listingType: 'product', billingType: 'perItem', stock: 15 },
      { title: 'Premium Matte Paint (20L)', description: 'High-quality indoor wall paint.', price: 850, listingType: 'product', billingType: 'perItem', stock: 40 },
      { title: 'Cement Bag (50kg)', description: 'Portland cement for construction.', price: 130, listingType: 'product', billingType: 'perItem', stock: 100 }
    ]
  },
  {
    professionTitle: 'Freelance Graphic Designer',
    category: 'Creative',
    businessType: 'individual',
    listings: [
      { title: 'Custom Logo Design', description: 'Professional logo tailored to your brand.', price: 500, listingType: 'service', billingType: 'fixed' },
      { title: 'Social Media Banner Ad', description: 'Eye-catching banners for ad campaigns.', price: 150, listingType: 'service', billingType: 'perItem' },
      { title: 'Retainer - Design Work', description: 'Monthly graphic design retainer.', price: 3000, listingType: 'service', billingType: 'monthly' }
    ]
  },
  {
    professionTitle: 'Expert Plumber',
    category: 'Home Services',
    businessType: 'individual',
    listings: [
      { title: 'Emergency Pipe Repair', description: 'Quick fix for leaking or burst pipes.', price: 200, listingType: 'service', billingType: 'hourly' },
      { title: 'Geyser Installation', description: 'Full installation of a new water heater.', price: 800, listingType: 'service', billingType: 'fixed' }
    ]
  },
  {
    professionTitle: 'Urban Chic Boutique',
    category: 'Fashion',
    businessType: 'shop',
    listings: [
      { title: 'Summer Floral Dress', description: 'Lightweight dress perfect for warm weather.', price: 350, listingType: 'product', billingType: 'perItem', stock: 20 },
      { title: 'Leather Crossbody Bag', description: 'Genuine leather handcrafted bag.', price: 600, listingType: 'product', billingType: 'perItem', stock: 10 },
      { title: 'Unisex Denim Jacket', description: 'Vintage style washed denim jacket.', price: 450, listingType: 'product', billingType: 'perItem', stock: 25 }
    ]
  },
  {
    professionTitle: 'Mobile Mechanic Pros',
    category: 'Auto Services',
    businessType: 'shop',
    listings: [
      { title: 'Standard Vehicle Servicing', description: 'Oil change, filter replacement, and general check.', price: 1200, listingType: 'service', billingType: 'fixed' },
      { title: 'Diagnostics & Troubleshooting', description: 'Engine light checks and complex fault finding.', price: 300, listingType: 'service', billingType: 'hourly' },
      { title: 'Premium Brake Pads', description: 'Set of high-quality ceramic brake pads.', price: 700, listingType: 'product', billingType: 'perItem', stock: 50 }
    ]
  }
];

async function seedMarketplace() {
  console.log('Seeding comprehensive marketplace data...');
  const batch = db.batch();

  // We will create the scenario providers, plus a few normal clients
  const totalUsers = 15; 
  
  for (let i = 0; i < totalUsers; i++) {
    // Make the first 7 users our specific scenario providers, the rest are pure clients
    const isProvider = i < providerScenarios.length;
    const scenario = isProvider ? providerScenarios[i] : null;
    
    const uid = faker.string.uuid();
    const userRef = db.collection('users').doc(uid);
    
    const firstName = faker.person.firstName();
    const lastName = faker.person.lastName();
    const displayName = isProvider && scenario.businessType === 'shop' 
      ? scenario.professionTitle 
      : `${firstName} ${lastName}`;
      
    const profileImageURL = faker.image.avatar();

    // 1. Create User Document
    const userData = {
      userId: uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      personalInfo: {
        firstName: firstName,
        lastName: lastName,
        phoneNumber: faker.phone.number(),
        email: faker.internet.email({ firstName, lastName }),
        isVerified: faker.datatype.boolean(),
        profileImageURL: profileImageURL,
      },
      currentLocation: {
        latitude: faker.location.latitude({ max: -15.3, min: -15.5 }), // Approx Lusaka bounds
        longitude: faker.location.longitude({ max: 28.4, min: 28.2 }),
        geohash: faker.string.alphanumeric(8),
      },
      clientProfile: {
        ratingAsClient: faker.number.float({ min: 3, max: 5, multipleOf: 0.1 }),
        totalBookingsMade: faker.number.int({ min: 0, max: 20 }),
      },
      providerProfile: {
        isActive: isProvider,
        professionTitle: isProvider ? scenario.professionTitle : '',
        category: isProvider ? scenario.category : '',
        hourlyRate: isProvider ? faker.number.float({ min: 50, max: 300, multipleOf: 5 }) : 0,
        currency: 'ZMW',
        bio: isProvider ? faker.lorem.paragraph() : '',
        ratingAsProvider: isProvider ? faker.number.float({ min: 4, max: 5, multipleOf: 0.1 }) : 0,
        totalJobsCompleted: isProvider ? faker.number.int({ min: 5, max: 150 }) : 0,
        portfolioImages: isProvider ? Array.from({ length: 3 }).map(() => faker.image.urlLoremFlickr({ category: 'work' })) : [],
        businessType: isProvider ? scenario.businessType : 'individual',
        listingsCount: isProvider ? scenario.listings.length : 0,
      },
      financialLedger: {
        currency: 'ZMW',
        availableBalance: faker.number.float({ min: 100, max: 10000, multipleOf: 0.5 }),
        vaultSettings: {
          isAutoSaveEnabled: false,
          autoSavePercentage: 0,
          vaultBalance: 0,
        },
        investmentPortfolio: {
          isActive: false,
          brokeragePartnerId: null,
          totalEstimatedValue: 0,
          assets: [],
        }
      }
    };
    batch.set(userRef, userData);

    // 2. Create Listings for the Provider
    if (isProvider) {
      for (const listData of scenario.listings) {
        const listingId = faker.string.uuid();
        const listingRef = db.collection('listings').doc(listingId);
        
        const listingDoc = {
          listingId: listingId,
          providerId: uid,
          providerName: displayName,
          providerImage: profileImageURL,
          title: listData.title,
          description: listData.description,
          price: listData.price,
          listingType: listData.listingType, // 'product' or 'service'
          billingType: listData.billingType, // 'hourly', 'fixed', 'monthly', 'perItem'
          category: scenario.category,
          images: Array.from({ length: 2 }).map(() => faker.image.urlLoremFlickr({ category: listData.listingType === 'product' ? 'product' : 'business' })),
          stockCount: listData.stock || 0,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        batch.set(listingRef, listingDoc);
      }
    }
  }

  await batch.commit();
  console.log('Successfully seeded highly realistic marketplace accounts and listings!');
}

seedMarketplace().catch(console.error);
