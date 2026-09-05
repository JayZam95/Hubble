import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:hubble/features/marketplace/data/boda_routing_service.dart';
import 'package:hubble/features/marketplace/presentation/screens/transportation/live_ride_tracking_screen.dart';

void main() {
  group('Boda-Boda Routing, Tracking & Fare Calculation Tests', () {
    const lusakaCbd = LatLng(-15.4167, 28.2833);
    const eastParkMall = LatLng(-15.3905, 28.3225);
    const mandaHillMall = LatLng(-15.4022, 28.3031);

    test('Haversine distance calculation is accurate within expected tolerances', () {
      final distCbdToEastPark = BodaRoutingService.calculateHaversineDistanceKm(
        lusakaCbd,
        eastParkMall,
      );

      // Distance from Cairo Rd to East Park Mall is approx 5.0 - 5.5 km
      expect(distCbdToEastPark, greaterThan(4.0));
      expect(distCbdToEastPark, lessThan(6.5));
    });

    test('Bearing calculation returns valid angles (0 - 360 degrees)', () {
      final bearingNorthEast = BodaRoutingService.calculateBearing(lusakaCbd, eastParkMall);
      expect(bearingNorthEast, greaterThanOrEqualTo(0.0));
      expect(bearingNorthEast, lessThanOrEqualTo(360.0));

      final bearingSouthWest = BodaRoutingService.calculateBearing(eastParkMall, lusakaCbd);
      expect(bearingSouthWest, greaterThanOrEqualTo(0.0));
      expect(bearingSouthWest, lessThanOrEqualTo(360.0));
    });

    test('Standard Boda fare calculation adheres to minimum base fare and per-km pricing', () {
      // 0 km should still charge minimum base fare K15
      final fareZeroKm = BodaRoutingService.calculateBodaFare(
        distanceKm: 0.0,
        rideType: 'standard',
      );
      expect(fareZeroKm, 15.0);

      // 5 km at K10/km + K15 base fare = K65
      final fareFiveKm = BodaRoutingService.calculateBodaFare(
        distanceKm: 5.0,
        rideType: 'standard',
      );
      expect(fareFiveKm, 65.0);
    });

    test('Express parcel courier fare includes courier handling surcharge', () {
      // 5 km parcel: base K15 + (5 * K10) + K8 handling fee = K73
      final parcelFare = BodaRoutingService.calculateBodaFare(
        distanceKm: 5.0,
        rideType: 'parcel',
      );
      expect(parcelFare, 73.0);
    });

    test('Boda Comfort XL fare uses premium rates', () {
      // 5 km comfort: base K25 + (5 * K14) = K95
      final comfortFare = BodaRoutingService.calculateBodaFare(
        distanceKm: 5.0,
        rideType: 'comfort',
      );
      expect(comfortFare, 95.0);
    });

    test('Promo codes (HUBBLEBODA, FIRSTFREE) apply correct discounts', () {
      final baseFare = BodaRoutingService.calculateBodaFare(
        distanceKm: 5.0,
        rideType: 'standard',
      ); // 65.0

      final discountedWithCode = BodaRoutingService.calculateBodaFare(
        distanceKm: 5.0,
        rideType: 'standard',
        promoCode: 'HUBBLEBODA',
      ); // 65 - 10 = 55.0
      expect(discountedWithCode, 55.0);

      final discountedWithPercent = BodaRoutingService.calculateBodaFare(
        distanceKm: 5.0,
        rideType: 'standard',
        promoCode: 'FIRSTFREE',
      ); // 65 * 0.80 = 52.0
      expect(discountedWithPercent, 52.0);
    });

    test('Road network route generator creates valid multi-step polylines and navigation steps', () async {
      final route = await BodaRoutingService.fetchRoadRoute(lusakaCbd, mandaHillMall);

      expect(route.polylinePoints.length, greaterThanOrEqualTo(2));
      expect(route.distanceKm, greaterThan(0.5));
      expect(route.durationMinutes, greaterThanOrEqualTo(1));
      expect(route.steps.isNotEmpty, true);
    });

    test('RideTrackingState maps correctly between DB and UI states', () {
      expect(RideTrackingState.searching.dbStatus, 'SEARCHING');
      expect(RideTrackingState.driverDispatched.dbStatus, 'DRIVER_DISPATCHED');
      expect(RideTrackingState.arrivedAtPickup.dbStatus, 'ARRIVED_AT_PICKUP');
      expect(RideTrackingState.inTransit.dbStatus, 'IN_TRANSIT');
      expect(RideTrackingState.completed.dbStatus, 'COMPLETED');

      expect(RideTrackingStateExtension.fromDbStatus('DRIVER_DISPATCHED'), RideTrackingState.driverDispatched);
      expect(RideTrackingStateExtension.fromDbStatus('IN_TRANSIT'), RideTrackingState.inTransit);
      expect(RideTrackingStateExtension.fromDbStatus('COMPLETED'), RideTrackingState.completed);
    });
  });
}
