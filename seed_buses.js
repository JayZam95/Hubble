const admin = require('firebase-admin');

admin.initializeApp({
  projectId: 'hubble-intentgenesiscorp',
});

const db = admin.firestore();

function generateSeats(count, occupiedEvery = 4) {
  const seats = [];
  const letters = ['A', 'B', 'C', 'D'];
  let row = 1;
  let generated = 0;

  while (generated < count) {
    for (let col = 0; col < 4 && generated < count; col++) {
      const id = `${row}${letters[col]}`;
      const isBooked = (generated % occupiedEvery) === 0 && generated !== 0;
      seats.push({
        id: id,
        status: isBooked ? 'booked' : 'available',
      });
      generated++;
    }
    row++;
  }
  return seats;
}

const busTrips = [
  {
    id: 'PWR-001',
    companyName: 'Power Tools Bus',
    origin: 'Lusaka',
    destination: 'Livingstone',
    departureTime: new Date(Date.now() + 8 * 60 * 60 * 1000).toISOString(),
    arrivalTime: new Date(Date.now() + 14 * 60 * 60 * 1000).toISOString(),
    price: 350.0,
    busClass: 'Express',
    totalSeats: 44,
    companyColorValue: 0xFF1E40AF,
    seats: generateSeats(44, 5),
  },
  {
    id: 'JLD-002',
    companyName: 'Juldan Motors',
    origin: 'Lusaka',
    destination: 'Kitwe',
    departureTime: new Date(Date.now() + 7.5 * 60 * 60 * 1000).toISOString(),
    arrivalTime: new Date(Date.now() + 12 * 60 * 60 * 1000).toISOString(),
    price: 180.0,
    busClass: 'Standard',
    totalSeats: 52,
    companyColorValue: 0xFFF59E0B,
    seats: generateSeats(52, 3),
  },
  {
    id: 'MZH-003',
    companyName: 'Mazhandu Family Bus',
    origin: 'Lusaka',
    destination: 'Ndola',
    departureTime: new Date(Date.now() + 9 * 60 * 60 * 1000).toISOString(),
    arrivalTime: new Date(Date.now() + 13.5 * 60 * 60 * 1000).toISOString(),
    price: 160.0,
    busClass: 'Standard',
    totalSeats: 52,
    companyColorValue: 0xFFEF4444,
    seats: generateSeats(52, 6),
  },
  {
    id: 'KBS-004',
    companyName: 'Kobs Motors',
    origin: 'Lusaka',
    destination: 'Chipata',
    departureTime: new Date(Date.now() + 6 * 60 * 60 * 1000).toISOString(),
    arrivalTime: new Date(Date.now() + 15 * 60 * 60 * 1000).toISOString(),
    price: 250.0,
    busClass: 'Express',
    totalSeats: 44,
    companyColorValue: 0xFF10B981,
    seats: generateSeats(44, 2),
  },
  {
    id: 'SHL-005',
    companyName: 'Shalom Bus Services',
    origin: 'Lusaka',
    destination: 'Mongu',
    departureTime: new Date(Date.now() + 10 * 60 * 60 * 1000).toISOString(),
    arrivalTime: new Date(Date.now() + 19 * 60 * 60 * 1000).toISOString(),
    price: 300.0,
    busClass: 'Express',
    totalSeats: 44,
    companyColorValue: 0xFF8B5CF6,
    seats: generateSeats(44, 4),
  },
  {
    id: 'EAB-006',
    companyName: 'Euro Africa Bus',
    origin: 'Lusaka',
    destination: 'Kasama',
    departureTime: new Date(Date.now() + 5.5 * 60 * 60 * 1000).toISOString(),
    arrivalTime: new Date(Date.now() + 18 * 60 * 60 * 1000).toISOString(),
    price: 280.0,
    busClass: 'Standard',
    totalSeats: 52,
    companyColorValue: 0xFF3B82F6,
    seats: generateSeats(52, 7),
  },
];

async function seed() {
  const batch = db.batch();
  
  for (const trip of busTrips) {
    const ref = db.collection('bus_trips').doc(trip.id);
    batch.set(ref, trip, { merge: true });
  }
  
  await batch.commit();
  console.log('Successfully seeded 6 Zambian intercity bus companies!');
}

seed().catch(console.error);
