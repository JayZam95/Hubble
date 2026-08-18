import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/bus_trip_model.dart';

// Helper to generate fixed local departure/arrival times for today/tomorrow
DateTime _todayAt(int hour, int minute) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, hour, minute);
}

DateTime _tomorrowAt(int hour, int minute) {
  final now = DateTime.now().add(const Duration(days: 1));
  return DateTime(now.year, now.month, now.day, hour, minute);
}

List<SeatModel> _generateLocalSeats(int count, {int occupiedEvery = 4}) {
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

/// Initial list of 8 Zambian bus companies with 27 trips across various routes & departure times
final List<BusTripModel> _defaultLocalBusTrips = [
  // ── Power Tools Bus ──────────────────────────────────────────────────────────
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
    seats: _generateLocalSeats(44, occupiedEvery: 5),
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
    seats: _generateLocalSeats(44, occupiedEvery: 4),
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
    seats: _generateLocalSeats(44, occupiedEvery: 6),
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
    seats: _generateLocalSeats(44, occupiedEvery: 3),
  ),

  // ── Juldan Motors ─────────────────────────────────────────────────────────────
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
    seats: _generateLocalSeats(52, occupiedEvery: 3),
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
    seats: _generateLocalSeats(52, occupiedEvery: 4),
  ),
  BusTripModel(
    id: 'JLD-003',
    companyName: 'Juldan Motors',
    origin: 'Lusaka',
    destination: 'Chipata',
    departureTime: _todayAt(13, 30),
    arrivalTime: _todayAt(20, 30),
    price: 260.0,
    busClass: 'Standard',
    totalSeats: 52,
    companyColorValue: 0xFFF59E0B,
    seats: _generateLocalSeats(52, occupiedEvery: 5),
  ),
  BusTripModel(
    id: 'JLD-004',
    companyName: 'Juldan Motors',
    origin: 'Lusaka',
    destination: 'Livingstone',
    departureTime: _todayAt(18, 0),
    arrivalTime: _tomorrowAt(0, 30),
    price: 320.0,
    busClass: 'Express',
    totalSeats: 52,
    companyColorValue: 0xFFF59E0B,
    seats: _generateLocalSeats(52, occupiedEvery: 4),
  ),

  // ── Mazhandu Family Bus ──────────────────────────────────────────────────────
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
    seats: _generateLocalSeats(52, occupiedEvery: 6),
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
    seats: _generateLocalSeats(44, occupiedEvery: 5),
  ),
  BusTripModel(
    id: 'MZH-003',
    companyName: 'Mazhandu Family Bus',
    origin: 'Lusaka',
    destination: 'Choma',
    departureTime: _todayAt(12, 45),
    arrivalTime: _todayAt(17, 15),
    price: 230.0,
    busClass: 'Standard',
    totalSeats: 52,
    companyColorValue: 0xFFEF4444,
    seats: _generateLocalSeats(52, occupiedEvery: 4),
  ),
  BusTripModel(
    id: 'MZH-004',
    companyName: 'Mazhandu Family Bus',
    origin: 'Lusaka',
    destination: 'Mongu',
    departureTime: _todayAt(21, 0),
    arrivalTime: _tomorrowAt(6, 30),
    price: 310.0,
    busClass: 'Express',
    totalSeats: 44,
    companyColorValue: 0xFFEF4444,
    seats: _generateLocalSeats(44, occupiedEvery: 3),
  ),

  // ── Kobs Motors ──────────────────────────────────────────────────────────────
  BusTripModel(
    id: 'KBS-001',
    companyName: 'Kobs Motors',
    origin: 'Lusaka',
    destination: 'Chipata',
    departureTime: _todayAt(5, 30),
    arrivalTime: _todayAt(12, 30),
    price: 250.0,
    busClass: 'Express',
    totalSeats: 44,
    companyColorValue: 0xFF10B981,
    seats: _generateLocalSeats(44, occupiedEvery: 2),
  ),
  BusTripModel(
    id: 'KBS-002',
    companyName: 'Kobs Motors',
    origin: 'Lusaka',
    destination: 'Katete',
    departureTime: _todayAt(11, 0),
    arrivalTime: _todayAt(17, 0),
    price: 220.0,
    busClass: 'Standard',
    totalSeats: 52,
    companyColorValue: 0xFF10B981,
    seats: _generateLocalSeats(52, occupiedEvery: 4),
  ),
  BusTripModel(
    id: 'KBS-003',
    companyName: 'Kobs Motors',
    origin: 'Lusaka',
    destination: 'Petauke',
    departureTime: _todayAt(15, 0),
    arrivalTime: _todayAt(20, 0),
    price: 180.0,
    busClass: 'Standard',
    totalSeats: 52,
    companyColorValue: 0xFF10B981,
    seats: _generateLocalSeats(52, occupiedEvery: 5),
  ),

  // ── Shalom Bus Services ──────────────────────────────────────────────────────
  BusTripModel(
    id: 'SHL-001',
    companyName: 'Shalom Bus Services',
    origin: 'Lusaka',
    destination: 'Mongu',
    departureTime: _todayAt(6, 0),
    arrivalTime: _todayAt(15, 0),
    price: 300.0,
    busClass: 'Express',
    totalSeats: 44,
    companyColorValue: 0xFF8B5CF6,
    seats: _generateLocalSeats(44, occupiedEvery: 4),
  ),
  BusTripModel(
    id: 'SHL-002',
    companyName: 'Shalom Bus Services',
    origin: 'Lusaka',
    destination: 'Kaoma',
    departureTime: _todayAt(10, 30),
    arrivalTime: _todayAt(17, 0),
    price: 240.0,
    busClass: 'Standard',
    totalSeats: 52,
    companyColorValue: 0xFF8B5CF6,
    seats: _generateLocalSeats(52, occupiedEvery: 3),
  ),
  BusTripModel(
    id: 'SHL-003',
    companyName: 'Shalom Bus Services',
    origin: 'Lusaka',
    destination: 'Senanga',
    departureTime: _todayAt(16, 0),
    arrivalTime: _tomorrowAt(2, 0),
    price: 350.0,
    busClass: 'Express',
    totalSeats: 44,
    companyColorValue: 0xFF8B5CF6,
    seats: _generateLocalSeats(44, occupiedEvery: 5),
  ),

  // ── Euro Africa Bus ──────────────────────────────────────────────────────────
  BusTripModel(
    id: 'EAB-001',
    companyName: 'Euro Africa Bus',
    origin: 'Lusaka',
    destination: 'Kasama',
    departureTime: _todayAt(5, 0),
    arrivalTime: _todayAt(17, 30),
    price: 280.0,
    busClass: 'Standard',
    totalSeats: 52,
    companyColorValue: 0xFF3B82F6,
    seats: _generateLocalSeats(52, occupiedEvery: 7),
  ),
  BusTripModel(
    id: 'EAB-002',
    companyName: 'Euro Africa Bus',
    origin: 'Lusaka',
    destination: 'Mpika',
    departureTime: _todayAt(8, 0),
    arrivalTime: _todayAt(16, 0),
    price: 230.0,
    busClass: 'Standard',
    totalSeats: 52,
    companyColorValue: 0xFF3B82F6,
    seats: _generateLocalSeats(52, occupiedEvery: 4),
  ),
  BusTripModel(
    id: 'EAB-003',
    companyName: 'Euro Africa Bus',
    origin: 'Lusaka',
    destination: 'Nakonde',
    departureTime: _todayAt(17, 30),
    arrivalTime: _tomorrowAt(7, 0),
    price: 380.0,
    busClass: 'Express',
    totalSeats: 44,
    companyColorValue: 0xFF3B82F6,
    seats: _generateLocalSeats(44, occupiedEvery: 5),
  ),

  // ── United Bus of Zambia (UBZ) ───────────────────────────────────────────────
  BusTripModel(
    id: 'UBZ-001',
    companyName: 'United Bus of Zambia (UBZ)',
    origin: 'Lusaka',
    destination: 'Kabwe',
    departureTime: _todayAt(7, 15),
    arrivalTime: _todayAt(9, 15),
    price: 90.0,
    busClass: 'Standard',
    totalSeats: 52,
    companyColorValue: 0xFF0D9488,
    seats: _generateLocalSeats(52, occupiedEvery: 4),
  ),
  BusTripModel(
    id: 'UBZ-002',
    companyName: 'United Bus of Zambia (UBZ)',
    origin: 'Lusaka',
    destination: 'Luanshya',
    departureTime: _todayAt(11, 30),
    arrivalTime: _todayAt(15, 0),
    price: 175.0,
    busClass: 'Standard',
    totalSeats: 52,
    companyColorValue: 0xFF0D9488,
    seats: _generateLocalSeats(52, occupiedEvery: 3),
  ),
  BusTripModel(
    id: 'UBZ-003',
    companyName: 'United Bus of Zambia (UBZ)',
    origin: 'Lusaka',
    destination: 'Livingstone',
    departureTime: _todayAt(15, 45),
    arrivalTime: _todayAt(22, 15),
    price: 330.0,
    busClass: 'Express',
    totalSeats: 44,
    companyColorValue: 0xFF0D9488,
    seats: _generateLocalSeats(44, occupiedEvery: 5),
  ),

  // ── Likili Bus Service ───────────────────────────────────────────────────────
  BusTripModel(
    id: 'LKL-001',
    companyName: 'Likili Bus Service',
    origin: 'Lusaka',
    destination: 'Mansa',
    departureTime: _todayAt(6, 15),
    arrivalTime: _todayAt(18, 0),
    price: 320.0,
    busClass: 'Express',
    totalSeats: 44,
    companyColorValue: 0xFFEA580C,
    seats: _generateLocalSeats(44, occupiedEvery: 4),
  ),
  BusTripModel(
    id: 'LKL-002',
    companyName: 'Likili Bus Service',
    origin: 'Lusaka',
    destination: 'Luwingu',
    departureTime: _todayAt(12, 0),
    arrivalTime: _todayAt(23, 0),
    price: 340.0,
    busClass: 'Standard',
    totalSeats: 52,
    companyColorValue: 0xFFEA580C,
    seats: _generateLocalSeats(52, occupiedEvery: 5),
  ),
  BusTripModel(
    id: 'LKL-003',
    companyName: 'Likili Bus Service',
    origin: 'Lusaka',
    destination: 'Samfya',
    departureTime: _todayAt(19, 30),
    arrivalTime: _tomorrowAt(6, 0),
    price: 360.0,
    busClass: 'Express',
    totalSeats: 44,
    companyColorValue: 0xFFEA580C,
    seats: _generateLocalSeats(44, occupiedEvery: 3),
  ),

  // ── Return Trips (Interchangeable Origins) ──────────────────────────────────
  BusTripModel(
    id: 'PWR-005',
    companyName: 'Power Tools Bus',
    origin: 'Livingstone',
    destination: 'Lusaka',
    departureTime: _todayAt(7, 0),
    arrivalTime: _todayAt(13, 30),
    price: 350.0,
    busClass: 'Express',
    totalSeats: 44,
    companyColorValue: 0xFF1E40AF,
    seats: _generateLocalSeats(44, occupiedEvery: 4),
  ),
  BusTripModel(
    id: 'JLD-005',
    companyName: 'Juldan Motors',
    origin: 'Kitwe',
    destination: 'Lusaka',
    departureTime: _todayAt(6, 0),
    arrivalTime: _todayAt(10, 30),
    price: 180.0,
    busClass: 'Standard',
    totalSeats: 52,
    companyColorValue: 0xFFF59E0B,
    seats: _generateLocalSeats(52, occupiedEvery: 3),
  ),
  BusTripModel(
    id: 'MZH-005',
    companyName: 'Mazhandu Family Bus',
    origin: 'Ndola',
    destination: 'Lusaka',
    departureTime: _todayAt(13, 0),
    arrivalTime: _todayAt(17, 0),
    price: 170.0,
    busClass: 'Standard',
    totalSeats: 52,
    companyColorValue: 0xFFEF4444,
    seats: _generateLocalSeats(52, occupiedEvery: 5),
  ),
  BusTripModel(
    id: 'KBS-004',
    companyName: 'Kobs Motors',
    origin: 'Chipata',
    destination: 'Lusaka',
    departureTime: _todayAt(6, 0),
    arrivalTime: _todayAt(13, 0),
    price: 250.0,
    busClass: 'Express',
    totalSeats: 44,
    companyColorValue: 0xFF10B981,
    seats: _generateLocalSeats(44, occupiedEvery: 3),
  ),
  BusTripModel(
    id: 'SHL-004',
    companyName: 'Shalom Bus Services',
    origin: 'Mongu',
    destination: 'Lusaka',
    departureTime: _todayAt(7, 0),
    arrivalTime: _todayAt(16, 0),
    price: 300.0,
    busClass: 'Express',
    totalSeats: 44,
    companyColorValue: 0xFF8B5CF6,
    seats: _generateLocalSeats(44, occupiedEvery: 4),
  ),
  BusTripModel(
    id: 'EAB-004',
    companyName: 'Euro Africa Bus',
    origin: 'Kasama',
    destination: 'Lusaka',
    departureTime: _todayAt(5, 30),
    arrivalTime: _todayAt(18, 0),
    price: 280.0,
    busClass: 'Standard',
    totalSeats: 52,
    companyColorValue: 0xFF3B82F6,
    seats: _generateLocalSeats(52, occupiedEvery: 6),
  ),
];

/// Notifier to manage local state for bus trips & seat bookings in-memory
class LocalBusTripsNotifier extends Notifier<List<BusTripModel>> {
  @override
  List<BusTripModel> build() {
    return _defaultLocalBusTrips;
  }

  void bookSeats(String tripId, List<String> seatIds) {
    state = state.map((trip) {
      if (trip.id == tripId) {
        final updatedSeats = trip.seats.map((seat) {
          if (seatIds.contains(seat.id)) {
            return seat.copyWith(status: SeatStatus.booked);
          }
          return seat;
        }).toList();
        return trip.copyWith(seats: updatedSeats);
      }
      return trip;
    }).toList();
  }
}

final localBusTripsNotifierProvider =
    NotifierProvider<LocalBusTripsNotifier, List<BusTripModel>>(() {
  return LocalBusTripsNotifier();
});

final transportationProvider = Provider<TransportationProvider>((ref) {
  return TransportationProvider();
});

/// Bus trips stream provider: streams from Firestore when available,
/// and falls back to local bus trips if Firestore returns 0 trips or encounters error.
final busTripsStreamProvider = StreamProvider<List<BusTripModel>>((ref) async* {
  final localTrips = ref.watch(localBusTripsNotifierProvider);
  yield localTrips;

  try {
    final checkDocs = await FirebaseFirestore.instance.collection('bus_trips').limit(1).get();
    if (checkDocs.docs.isEmpty) {
      for (final trip in _defaultLocalBusTrips) {
        await FirebaseFirestore.instance.collection('bus_trips').doc(trip.id).set(trip.toMap());
      }
    }

    final snapshots = FirebaseFirestore.instance
        .collection('bus_trips')
        .orderBy('departureTime', descending: false)
        .snapshots();

    await for (final snapshot in snapshots) {
      if (snapshot.docs.isNotEmpty) {
        final firestoreTrips = snapshot.docs
            .map((doc) => BusTripModel.fromMap(doc.data(), doc.id))
            .toList();
        if (firestoreTrips.isNotEmpty) {
          yield firestoreTrips;
        }
      }
    }
  } catch (_) {
    // Local trips yielded above on error
  }
});

class TransportationProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addDummyBusTrips() async {
    for (var trip in _defaultLocalBusTrips) {
      await _firestore.collection('bus_trips').doc(trip.id).set(trip.toMap());
    }
  }
}

