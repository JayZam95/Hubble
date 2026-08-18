import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/presentation/widgets/hubble_image.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import 'bike_service_screen.dart' show LusakaLocation, kLusakaLocations;
import 'live_ride_tracking_screen.dart';

class NearbyCabModel {
  final String id;
  final String driverName;
  final String driverPhone;
  final String vehicleModel;
  final String licensePlate;
  final double rating;
  final int totalRides;
  final int etaMinutes;
  final double basePrice;
  final String photoUrl;
  final LatLng position;

  NearbyCabModel({
    required this.id,
    required this.driverName,
    this.driverPhone = '+260 977 492011',
    required this.vehicleModel,
    required this.licensePlate,
    required this.rating,
    required this.totalRides,
    required this.etaMinutes,
    required this.basePrice,
    required this.photoUrl,
    required this.position,
  });
}

class AvailableCabsScreen extends ConsumerStatefulWidget {
  const AvailableCabsScreen({super.key});

  @override
  ConsumerState<AvailableCabsScreen> createState() => _AvailableCabsScreenState();
}

class _AvailableCabsScreenState extends ConsumerState<AvailableCabsScreen> {
  LusakaLocation _pickupLocation = kLusakaLocations[0];
  LusakaLocation _dropoffLocation = kLusakaLocations[1];

  final MapController _mapController = MapController();
  bool _isRequesting = false;
  NearbyCabModel? _selectedCab;

  final List<NearbyCabModel> _cabs = [
    NearbyCabModel(
      id: 'cab_1',
      driverName: 'Chileshe Mwansa',
      driverPhone: '+260 977 492011',
      vehicleModel: 'Toyota Vitz (Silver)',
      licensePlate: 'BAL 4920',
      rating: 4.9,
      totalRides: 420,
      etaMinutes: 3,
      basePrice: 65.0,
      photoUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=300&q=80',
      position: const LatLng(-15.4140, 28.2850),
    ),
    NearbyCabModel(
      id: 'cab_2',
      driverName: 'Kelvin Zimba',
      driverPhone: '+260 966 102933',
      vehicleModel: 'Nissan Note (White)',
      licensePlate: 'BAZ 1029',
      rating: 4.8,
      totalRides: 310,
      etaMinutes: 5,
      basePrice: 60.0,
      photoUrl: 'https://images.unsplash.com/photo-1522529599102-193c0d76b5b6?auto=format&fit=crop&w=300&q=80',
      position: const LatLng(-15.4200, 28.2820),
    ),
    NearbyCabModel(
      id: 'cab_3',
      driverName: 'Peter Banda',
      driverPhone: '+260 955 883100',
      vehicleModel: 'Honda Fit (Blue)',
      licensePlate: 'ABX 8831',
      rating: 4.95,
      totalRides: 650,
      etaMinutes: 6,
      basePrice: 70.0,
      photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fit=crop&w=300&q=80',
      position: const LatLng(-15.4120, 28.2890),
    ),
    NearbyCabModel(
      id: 'cab_4',
      driverName: 'Emmanuel Phiri',
      driverPhone: '+260 971 339244',
      vehicleModel: 'Toyota Corolla (Black)',
      licensePlate: 'BAC 3392',
      rating: 4.7,
      totalRides: 190,
      etaMinutes: 8,
      basePrice: 75.0,
      photoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80',
      position: const LatLng(-15.4250, 28.2800),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedCab = _cabs.first;
  }

  double _calculateDistanceKm() {
    final start = _pickupLocation.point;
    final end = _dropoffLocation.point;
    const p = 0.017453292519943295;
    final c = math.cos;
    final a = 0.5 -
        c((end.latitude - start.latitude) * p) / 2 +
        c(start.latitude * p) *
            c(end.latitude * p) *
            (1 - c((end.longitude - start.longitude) * p)) /
            2;
    final dist = 12742 * math.asin(math.sqrt(a));
    return dist < 0.5 ? 1.5 : dist;
  }

  double _calculateCabFare() {
    final dist = _calculateDistanceKm();
    // Cab Fare: Base K40, K15 per km
    return 40.0 + (dist * 15.0);
  }

  void _requestCab(NearbyCabModel cab) async {
    setState(() {
      _selectedCab = cab;
      _isRequesting = true;
    });

    final distance = _calculateDistanceKm();
    final fare = _calculateCabFare();
    final safetyPin = '${1000 + math.Random().nextInt(9000)}';
    String rideId = 'cab_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final isTest = (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'));
      if (!isTest) {
        final currentUser = ref.read(authStateProvider).user;
        final docRef = await FirebaseFirestore.instance.collection('ride_requests').add({
          'type': 'cab_ride',
          'userId': currentUser?.uid ?? 'guest_user',
          'userName': currentUser?.displayName ?? 'Valued Client',
          'driverId': cab.id,
          'driverName': cab.driverName,
          'driverPhone': cab.driverPhone,
          'driverPhotoUrl': cab.photoUrl,
          'vehicleModel': cab.vehicleModel,
          'licensePlate': cab.licensePlate,
          'driverRating': cab.rating,
          'totalRides': cab.totalRides,
          'pickupName': _pickupLocation.name,
          'pickupLat': _pickupLocation.point.latitude,
          'pickupLng': _pickupLocation.point.longitude,
          'dropoffName': _dropoffLocation.name,
          'dropoffLat': _dropoffLocation.point.latitude,
          'dropoffLng': _dropoffLocation.point.longitude,
          'distanceKm': distance,
          'totalFare': fare,
          'safetyPin': safetyPin,
          'status': 'DRIVER_DISPATCHED',
          'createdAt': FieldValue.serverTimestamp(),
        });
        rideId = docRef.id;
      }
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() => _isRequesting = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveRideTrackingScreen(
            rideId: rideId,
            rideType: 'cab',
            driverId: cab.id,
            driverName: cab.driverName,
            driverPhone: cab.driverPhone,
            driverPhotoUrl: cab.photoUrl,
            driverRating: cab.rating,
            totalRides: cab.totalRides,
            vehicleModel: cab.vehicleModel,
            licensePlate: cab.licensePlate,
            pickupName: _pickupLocation.name,
            pickupLatLng: _pickupLocation.point,
            dropoffName: _dropoffLocation.name,
            dropoffLatLng: _dropoffLocation.point,
            fare: fare,
            distanceKm: distance,
            safetyPin: safetyPin,
            initialState: RideTrackingState.driverDispatched,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final distance = _calculateDistanceKm();
    final totalFare = _calculateCabFare();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Available Cabs Nearby', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Interactive Route Map
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _pickupLocation.point,
                      initialZoom: 13.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.intentgenesiscorp.hubble',
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [_pickupLocation.point, _dropoffLocation.point],
                            strokeWidth: 4.0,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _pickupLocation.point,
                            width: 36,
                            height: 36,
                            child: const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 30),
                          ),
                          Marker(
                            point: _dropoffLocation.point,
                            width: 36,
                            height: 36,
                            child: const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 34),
                          ),
                          ..._cabs.map(
                            (c) => Marker(
                              point: c.position,
                              width: 30,
                              height: 30,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                                child: const Icon(Icons.local_taxi_rounded, color: Colors.amber, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Location Selectors
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pickup Point:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<LusakaLocation>(
                      initialValue: _pickupLocation,
                      isExpanded: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 20),
                        filled: true,
                        fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: kLusakaLocations.map((loc) {
                        return DropdownMenuItem(
                          value: loc,
                          child: Text(loc.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _pickupLocation = val);
                          _mapController.move(val.point, 13.0);
                        }
                      },
                    ),

                    const SizedBox(height: 14),

                    const Text('Destination:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<LusakaLocation>(
                      initialValue: _dropoffLocation,
                      isExpanded: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 20),
                        filled: true,
                        fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: kLusakaLocations.map((loc) {
                        return DropdownMenuItem(
                          value: loc,
                          child: Text(loc.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _dropoffLocation = val);
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Distance: ${distance.toStringAsFixed(1)} km',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const Text('Est. Cab Rate: Base K40 + K15.00 / km', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          Text(
                            'K ${totalFare.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nearby Cab Drivers',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_cabs.length} Cabs Active',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Available Cabs List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _cabs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final cab = _cabs[index];
                  final isSelected = _selectedCab?.id == cab.id;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCab = cab);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                child: HubbleImage(
                                  imagePath: cab.photoUrl,
                                  width: 56,
                                  height: 56,
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cab.driverName,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${cab.vehicleModel} · ${cab.licensePlate}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${cab.rating} (${cab.totalRides} rides)',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'K ${totalFare.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${cab.etaMinutes} min away',
                                    style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isRequesting && _selectedCab?.id == cab.id
                                  ? null
                                  : () {
                                      HapticFeedback.lightImpact();
                                      _requestCab(cab);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: _isRequesting && _selectedCab?.id == cab.id
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.local_taxi_rounded, size: 18),
                              label: Text(
                                _isRequesting && _selectedCab?.id == cab.id ? 'Dispatching Cab...' : 'Request Cab (K ${totalFare.toStringAsFixed(0)})',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
