import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Representation of a navigation maneuver / turn-by-turn step
class BodaNavStep {
  final String instruction;
  final double distanceMeters;
  final LatLng location;
  final String iconType; // 'straight', 'turn-right', 'turn-left', 'arrive', 'start'

  const BodaNavStep({
    required this.instruction,
    required this.distanceMeters,
    required this.location,
    required this.iconType,
  });
}

/// Result of an OSRM or simulated route calculation
class BodaRouteResult {
  final List<LatLng> polylinePoints;
  final double distanceKm;
  final int durationMinutes;
  final List<BodaNavStep> steps;

  const BodaRouteResult({
    required this.polylinePoints,
    required this.distanceKm,
    required this.durationMinutes,
    required this.steps,
  });
}

/// Service providing routing, real-time GPS tracking, and fare calculations for Boda Boda
class BodaRoutingService {
  static const double baseFareStandard = 15.0; // K15 base fare
  static const double perKmRateStandard = 10.0; // K10 per kilometer
  static const double baseFareComfort = 25.0; // K25 base fare for comfort/XL
  static const double perKmRateComfort = 14.0; // K14/km for comfort
  static const double courierHandlingFee = 8.0; // K8 parcel handling fee

  /// Calculate distance in kilometers between two GPS points using Haversine formula
  static double calculateHaversineDistanceKm(LatLng start, LatLng end) {
    const p = 0.017453292519943295;
    final c = math.cos;
    final a = 0.5 -
        c((end.latitude - start.latitude) * p) / 2 +
        c(start.latitude * p) *
            c(end.latitude * p) *
            (1 - c((end.longitude - start.longitude) * p)) /
            2;
    final dist = 12742 * math.asin(math.sqrt(math.max(0.0, a)));
    return dist < 0.2 ? 0.2 : dist;
  }

  /// Calculate bearing in degrees from point A to point B for rotating vehicle markers
  static double calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * (math.pi / 180.0);
    final lon1 = start.longitude * (math.pi / 180.0);
    final lat2 = end.latitude * (math.pi / 180.0);
    final lon2 = end.longitude * (math.pi / 180.0);

    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final radians = math.atan2(y, x);
    final degrees = (radians * (180.0 / math.pi) + 360.0) % 360.0;
    return degrees;
  }

  /// Calculate fare based on ride type, distance, traffic multiplier, and optional promo code
  static double calculateBodaFare({
    required double distanceKm,
    required String rideType, // 'standard', 'parcel', 'comfort'
    double trafficMultiplier = 1.0,
    String? promoCode,
  }) {
    double base;
    double perKm;
    double extra = 0.0;

    switch (rideType) {
      case 'comfort':
      case 'xl':
        base = baseFareComfort;
        perKm = perKmRateComfort;
        break;
      case 'parcel':
      case 'delivery':
        base = baseFareStandard;
        perKm = perKmRateStandard;
        extra = courierHandlingFee;
        break;
      case 'standard':
      default:
        base = baseFareStandard;
        perKm = perKmRateStandard;
        break;
    }

    final rawFare = (base + (distanceKm * perKm) + extra) * trafficMultiplier;
    double finalFare = math.max(base, rawFare);

    // Apply promo codes if present
    if (promoCode != null && promoCode.trim().isNotEmpty) {
      final code = promoCode.trim().toUpperCase();
      if (code == 'HUBBLEBODA' || code == 'BODA10') {
        finalFare = math.max(10.0, finalFare - 10.0);
      } else if (code == 'FIRSTFREE' || code == 'YANGO') {
        finalFare = math.max(10.0, finalFare * 0.80); // 20% discount
      }
    }

    // Round to nearest integer for clean Zambian Kwacha display
    return (finalFare * 2).round() / 2.0;
  }

  /// Fetch realistic road routing from public OSRM, with automatic fallback generator
  static Future<BodaRouteResult> fetchRoadRoute(LatLng start, LatLng end) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson&steps=true',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final distanceM = (route['distance'] as num).toDouble();
          final durationS = (route['duration'] as num).toDouble();

          final coordinates = route['geometry']['coordinates'] as List;
          final polyline = coordinates
              .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();

          final stepsList = <BodaNavStep>[];
          if (route['legs'] != null && (route['legs'] as List).isNotEmpty) {
            final leg = route['legs'][0];
            final steps = leg['steps'] as List? ?? [];

            for (final s in steps) {
              final maneuver = s['maneuver'] ?? {};
              final instruction = (maneuver['instruction'] as String?) ??
                  'Continue on road for ${(s['distance'] as num?)?.toStringAsFixed(0) ?? '0'}m';
              final mType = (maneuver['type'] as String?) ?? 'straight';
              final loc = maneuver['location'] as List?;

              final stepLocation = loc != null && loc.length >= 2
                  ? LatLng((loc[1] as num).toDouble(), (loc[0] as num).toDouble())
                  : (polyline.isNotEmpty ? polyline.first : start);

              stepsList.add(
                BodaNavStep(
                  instruction: instruction,
                  distanceMeters: (s['distance'] as num?)?.toDouble() ?? 100.0,
                  location: stepLocation,
                  iconType: _normalizeIconType(mType),
                ),
              );
            }
          }

          if (polyline.isNotEmpty) {
            return BodaRouteResult(
              polylinePoints: polyline,
              distanceKm: math.max(0.5, distanceM / 1000.0),
              durationMinutes: math.max(2, (durationS / 60.0).round()),
              steps: stepsList.isNotEmpty
                  ? stepsList
                  : _generateDefaultSteps(start, end, distanceM / 1000.0),
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('OSRM routing request fallback invoked: $e');
      }
    }

    // Fallback road polyline generator
    return _generateFallbackCurvedRoute(start, end);
  }

  static String _normalizeIconType(String type) {
    if (type.contains('right')) return 'turn-right';
    if (type.contains('left')) return 'turn-left';
    if (type.contains('arrive')) return 'arrive';
    if (type.contains('depart')) return 'start';
    return 'straight';
  }

  /// Generate a realistic multi-point bezier/waypoint road route connecting start and end
  static BodaRouteResult _generateFallbackCurvedRoute(LatLng start, LatLng end) {
    final directDist = calculateHaversineDistanceKm(start, end);
    final distanceKm = math.max(0.8, directDist * 1.25); // Road network detour factor
    final durationMinutes = math.max(2, (distanceKm * 2.2).round());

    final points = <LatLng>[start];
    const int segments = 16;

    // Create realistic road curvature offset
    final midLat = (start.latitude + end.latitude) / 2;
    final midLng = (start.longitude + end.longitude) / 2;
    final latDiff = end.latitude - start.latitude;
    final lngDiff = end.longitude - start.longitude;

    // Perpendicular vector for road curve
    final perpLat = -lngDiff * 0.18;
    final perpLng = latDiff * 0.18;

    for (int i = 1; i < segments; i++) {
      final t = i / segments.toDouble();
      // Quadratic Bezier interpolation
      final lat = (1 - t) * (1 - t) * start.latitude +
          2 * (1 - t) * t * (midLat + perpLat) +
          t * t * end.latitude;
      final lng = (1 - t) * (1 - t) * start.longitude +
          2 * (1 - t) * t * (midLng + perpLng) +
          t * t * end.longitude;
      points.add(LatLng(lat, lng));
    }
    points.add(end);

    return BodaRouteResult(
      polylinePoints: points,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      steps: _generateDefaultSteps(start, end, distanceKm),
    );
  }

  /// Generate user-friendly step-by-step navigation cues for the trip
  static List<BodaNavStep> _generateDefaultSteps(LatLng start, LatLng end, double distKm) {
    return [
      BodaNavStep(
        instruction: 'Start ride from pickup point',
        distanceMeters: 200,
        location: start,
        iconType: 'start',
      ),
      BodaNavStep(
        instruction: 'Continue on main arterial road for ${(distKm * 0.4).toStringAsFixed(1)} km',
        distanceMeters: (distKm * 400).clamp(200, 3000),
        location: LatLng(
          start.latitude + (end.latitude - start.latitude) * 0.3,
          start.longitude + (end.longitude - start.longitude) * 0.3,
        ),
        iconType: 'straight',
      ),
      BodaNavStep(
        instruction: 'In 300m, Turn Right onto connecting avenue',
        distanceMeters: 300,
        location: LatLng(
          start.latitude + (end.latitude - start.latitude) * 0.7,
          start.longitude + (end.longitude - start.longitude) * 0.7,
        ),
        iconType: 'turn-right',
      ),
      BodaNavStep(
        instruction: 'Arrive at destination on the left',
        distanceMeters: 50,
        location: end,
        iconType: 'arrive',
      ),
    ];
  }

  /// Request GPS permissions and obtain user's current GPS position
  static Future<Position?> getCurrentDeviceLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
