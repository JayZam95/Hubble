import 'package:flutter_test/flutter_test.dart';
import 'package:hubble/features/marketplace/domain/models/bus_trip_model.dart';

void main() {
  group('Bus Ticketing & Seat Reservation Lifecycle Tests', () {
    late BusTripModel initialTrip;

    setUp(() {
      initialTrip = BusTripModel(
        id: 'PWR-LUS-LIV-01',
        companyName: 'Power Tools Bus',
        origin: 'Lusaka',
        destination: 'Livingstone',
        departureTime: DateTime.now().add(const Duration(hours: 4)),
        arrivalTime: DateTime.now().add(const Duration(hours: 10)),
        price: 350.0,
        busClass: 'Luxury Express',
        totalSeats: 8,
        companyColorValue: 0xFF1E40AF,
        seats: [
          SeatModel(id: '1A', status: SeatStatus.available),
          SeatModel(id: '1B', status: SeatStatus.available),
          SeatModel(id: '1C', status: SeatStatus.available),
          SeatModel(id: '1D', status: SeatStatus.available),
          SeatModel(id: '2A', status: SeatStatus.available),
          SeatModel(id: '2B', status: SeatStatus.available),
          SeatModel(id: '2C', status: SeatStatus.available),
          SeatModel(id: '2D', status: SeatStatus.available),
        ],
      );
    });

    test('Initial schedule shows all 8 seats available', () {
      expect(initialTrip.totalSeats, 8);
      expect(initialTrip.availableCount, 8);
    });

    test('Passenger selects 2 seats and reserves them atomically', () {
      final selectedSeatIds = {'1A', '1B'};
      const ticketPricePerSeat = 350.0;
      final totalFare = ticketPricePerSeat * selectedSeatIds.length;

      expect(totalFare, 700.0);

      // Verify selected seats are currently available
      final areAvailable = initialTrip.seats
          .where((s) => selectedSeatIds.contains(s.id))
          .every((s) => s.status == SeatStatus.available);
      expect(areAvailable, true);

      // Transition seats to booked
      final updatedSeats = initialTrip.seats.map((s) {
        if (selectedSeatIds.contains(s.id)) {
          return s.copyWith(status: SeatStatus.booked);
        }
        return s;
      }).toList();

      final updatedTrip = initialTrip.copyWith(seats: updatedSeats);

      expect(updatedTrip.availableCount, 6);
      expect(updatedTrip.seats.firstWhere((s) => s.id == '1A').status, SeatStatus.booked);
      expect(updatedTrip.seats.firstWhere((s) => s.id == '1B').status, SeatStatus.booked);
      expect(updatedTrip.seats.firstWhere((s) => s.id == '1C').status, SeatStatus.available);
    });

    test('Concurrent booking attempt on already booked seat is rejected', () {
      final tripWithBookedSeat = initialTrip.copyWith(
        seats: initialTrip.seats.map((s) {
          if (s.id == '1A') {
            return s.copyWith(status: SeatStatus.booked);
          }
          return s;
        }).toList(),
      );

      final secondUserSelectedIds = {'1A', '1C'};
      final hasConflict = tripWithBookedSeat.seats
          .where((s) => secondUserSelectedIds.contains(s.id))
          .any((s) => s.status != SeatStatus.available);

      expect(hasConflict, true);
    });

    test('BusTripModel serialization and deserialization retains full seat maps', () {
      final map = initialTrip.toMap();
      final reconstructed = BusTripModel.fromMap(map, 'PWR-LUS-LIV-01');

      expect(reconstructed.id, 'PWR-LUS-LIV-01');
      expect(reconstructed.companyName, 'Power Tools Bus');
      expect(reconstructed.seats.length, 8);
      expect(reconstructed.availableCount, 8);
      expect(reconstructed.price, 350.0);
    });
  });
}
