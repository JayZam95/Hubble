const admin = require('firebase-admin');

admin.initializeApp({
  projectId: 'hubble-intentgenesiscorp',
});

const db = admin.firestore();

function generateAccounts() {
  const accounts = [];
  const firstNames = ['Chanda', 'Mwansa', 'Bwalya', 'Mutale', 'Kabungo', 'Mabvuto', 'Thabo', 'Lushomo', 'Sipho', 'Mulenga', 'Chilufya', 'Bupe', 'Kondwani', 'Tembo', 'Banda', 'Daka', 'Phiri', 'Mwanza', 'Ngoma', 'Lungowe'];
  const lastNames = ['Phiri', 'Banda', 'Mwale', 'Zulu', 'Mulenga', 'Mwape', 'Chirwa', 'Tembo', 'Ngoma', 'Daka', 'Mwanza', 'Sakala', 'Nyirenda', 'Lungu', 'Kaluba', 'Chewe', 'Chisenga', 'Simutowe', 'Sichone', 'Malungo'];
  
  const categories = ['Tutoring', 'Beauty & Spa', 'Tech Support', 'Home Repairs', 'Transit & Moving', 'Event Planning', 'Photography'];
  const titles = {
    'Tutoring': ['Math Tutor', 'Science Instructor', 'English Teacher'],
    'Beauty & Spa': ['Makeup Artist', 'Hair Stylist', 'Nail Technician'],
    'Tech Support': ['PC Repair Specialist', 'Network Setup Guru', 'Mobile Phone Technician'],
    'Home Repairs': ['Plumber', 'Electrician', 'Carpenter'],
    'Transit & Moving': ['Moving Van Driver', 'Logistics Coordinator', 'Courier'],
    'Event Planning': ['Wedding Planner', 'Party Decorator', 'DJ'],
    'Photography': ['Portrait Photographer', 'Event Photographer', 'Videographer']
  };
  
  const locations = [
    {lat: -15.3875, lng: 28.3228, name: 'Lusaka'},
    {lat: -12.8024, lng: 28.2069, name: 'Kitwe'},
    {lat: -15.4166, lng: 28.2833, name: 'Lusaka West'},
    {lat: -12.8167, lng: 28.2000, name: 'Kitwe Central'},
  ];

  for (let i = 0; i < 20; i++) {
    const isProvider = i < 15;
    const isShop = isProvider && i % 3 === 0;
    
    const firstName = firstNames[i % firstNames.length];
    const lastName = lastNames[(i * 3) % lastNames.length];
    
    const loc = locations[i % locations.length];
    const lat = loc.lat + (Math.random() * 0.05 - 0.025);
    const lng = loc.lng + (Math.random() * 0.05 - 0.025);
    
    const category = categories[i % categories.length];
    const titleList = titles[category];
    const professionTitle = titleList[i % titleList.length];
    
    const hourlyRate = 100.0 + Math.floor(Math.random() * 400);
    const rating = 3.5 + Math.random() * 1.5;
    
    const gender = i % 2 === 0 ? 'men' : 'women';
    const profileImageId = 10 + i;
    const profileImageURL = `https://randomuser.me/api/portraits/${gender}/${profileImageId}.jpg`;
    
    const portfolioImages = [];
    if (isProvider) {
      for (let j = 0; j < 3; j++) {
        portfolioImages.push(`https://picsum.photos/seed/provider${i}_${j}/600/400`);
      }
    }

    let bio = '';
    if (isProvider) {
      if (isShop) {
        bio = `We are a premier established business in ${loc.name} offering top-notch ${category} services. Our team of professionals guarantees satisfaction.`;
      } else {
        bio = `Hi, I am ${firstName}! I am a passionate ${professionTitle} based in ${loc.name}. I have been doing this for over 5 years and love helping my clients.`;
      }
    }

    const uid = `seeded_user_${i}`;
    
    accounts.push({
      userId: uid,
      email: `${firstName.toLowerCase()}.${lastName.toLowerCase()}@example.com`,
      displayName: isShop ? `${firstName} ${lastName} & Co.` : `${firstName} ${lastName}`,
      role: isProvider ? 'provider' : 'client',
      createdAt: admin.firestore.Timestamp.fromDate(new Date()),
      personalInfo: {
        firstName: firstName,
        lastName: isShop ? `${lastName} & Co.` : lastName,
        phoneNumber: `+260970000${String(i).padStart(2, '0')}`,
        email: `${firstName.toLowerCase()}.${lastName.toLowerCase()}@example.com`,
        isVerified: true,
        profileImageURL: profileImageURL,
      },
      currentLocation: {
        latitude: lat,
        longitude: lng,
        geohash: `khg${i}abc`,
      },
      clientProfile: {
        ratingAsClient: isProvider ? 0.0 : rating,
        totalBookingsMade: Math.floor(Math.random() * 20),
      },
      providerProfile: {
        isActive: isProvider,
        professionTitle: isProvider ? professionTitle : '',
        category: isProvider ? category : '',
        hourlyRate: isProvider ? hourlyRate : 0.0,
        currency: 'ZMW',
        bio: bio,
        ratingAsProvider: isProvider ? rating : 0.0,
        totalJobsCompleted: isProvider ? Math.floor(Math.random() * 50) + 5 : 0,
        portfolioImages: portfolioImages,
        businessType: isShop ? 'shop' : 'individual',
        listingsCount: isProvider ? Math.floor(Math.random() * 5) + 1 : 0,
      },
      financialLedger: {
        currency: 'ZMW',
        availableBalance: Math.random() * 1000,
        vaultSettings: {
          isAutoSaveEnabled: false,
          autoSavePercentage: 0.0,
          vaultBalance: 0.0,
        },
        investmentPortfolio: {
          isActive: false,
          totalEstimatedValue: 0.0,
          assets: [],
        }
      }
    });
  }
  return accounts;
}

async function seed() {
  const accounts = generateAccounts();
  const batch = db.batch();
  
  accounts.forEach(acc => {
    const ref = db.collection('users').doc(acc.userId);
    batch.set(ref, acc);
  });
  
  await batch.commit();
  console.log('Successfully seeded 20 Zambian accounts into Live Firebase via Admin SDK!');
}

seed().catch(console.error);
