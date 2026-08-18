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
import 'live_ride_tracking_screen.dart';

class LusakaLocation {
  final String name;
  final LatLng point;
  const LusakaLocation(this.name, this.point);
}

const List<LusakaLocation> kLusakaLocations = [
  LusakaLocation('Lusaka CBD (Cairo Road)', LatLng(-15.4167, 28.2833)),
  LusakaLocation('East Park Mall (Great East Rd)', LatLng(-15.3905, 28.3225)),
  LusakaLocation('Manda Hill Shopping Mall', LatLng(-15.4022, 28.3031)),
  LusakaLocation('Woodlands Shopping Mall', LatLng(-15.4410, 28.3280)),
  LusakaLocation('Kabulonga Centro Mall', LatLng(-15.4215, 28.3378)),
  LusakaLocation('Intercity Bus Terminus', LatLng(-15.4270, 28.2885)),
  LusakaLocation('UNZA Great East Campus', LatLng(-15.3920, 28.3330)),
  LusakaLocation('Roma Girls High School', LatLng(-15.3780, 28.3100)),
  LusakaLocation('Chilenje Market & Station', LatLng(-15.4520, 28.3200)),
  LusakaLocation('Kamwala Shopping Center', LatLng(-15.4310, 28.2850)),
];

class BodaRiderModel {
  final String id;
  final String driverName;
  final String driverPhone;
  final String bikeModel;
  final String licensePlate;
  final double rating;
  final int totalRides;
  final int etaMinutes;
  final String photoUrl;
  final LatLng position;

  BodaRiderModel({
    required this.id,
    required this.driverName,
    this.driverPhone = '+260 977 293122',
    required this.bikeModel,
    required this.licensePlate,
    required this.rating,
    required this.totalRides,
    required this.etaMinutes,
    required this.photoUrl,
    required this.position,
  });
}

class BikeServiceScreen extends ConsumerStatefulWidget {
  final int initialTabIndex; // 0 = Ride, 1 = Delivery
  const BikeServiceScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<BikeServiceScreen> createState() => _BikeServiceScreenState();
}

class _BikeServiceScreenState extends ConsumerState<BikeServiceScreen> {
  late int _selectedTab; // 0 = Passenger Ride, 1 = Package Delivery

  LusakaLocation _pickupLocation = kLusakaLocations[0];
  LusakaLocation _dropoffLocation = kLusakaLocations[1];

  // Delivery extra details
  final TextEditingController _parcelDescController = TextEditingController();
  final TextEditingController _recipientPhoneController = TextEditingController();

  final MapController _mapController = MapController();
  bool _isSubmitting = false;
  BodaRiderModel? _selectedRider;

  final List<BodaRiderModel> _availableRiders = [
    BodaRiderModel(
      id: 'boda_1',
      driverName: 'Moses Sakala',
      driverPhone: '+260 977 293122',
      bikeModel: 'TVS HLX 150 (Red)',
      licensePlate: 'BAR 2931',
      rating: 4.9,
      totalRides: 340,
      etaMinutes: 2,
      photoUrl: 'https://images.unsplash.com/photo-1522529599102-193c0d76b5b6?auto=format&fit=crop&w=300&q=80',
      position: const LatLng(-15.4150, 28.2840),
    ),
    BodaRiderModel(
      id: 'boda_2',
      driverName: 'Kabwe Musonda',
      driverPhone: '+260 966 882044',
      bikeModel: 'Bajaj Boxer BM150 (Black)',
      licensePlate: 'BAT 8820',
      rating: 4.8,
      totalRides: 210,
      etaMinutes: 4,
      photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fit=crop&w=300&q=80',
      position: const LatLng(-15.4190, 28.2810),
    ),
    BodaRiderModel(
      id: 'boda_3',
      driverName: 'Gershom Nyirenda',
      driverPhone: '+260 955 410288',
      bikeModel: 'Lifan 125 (Blue)',
      licensePlate: 'BAV 4102',
      rating: 4.95,
      totalRides: 510,
      etaMinutes: 5,
      photoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80',
      position: const LatLng(-15.4130, 28.2870),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
    _selectedRider = _availableRiders.first;
  }

  @override
  void dispose() {
    _parcelDescController.dispose();
    _recipientPhoneController.dispose();
    super.dispose();
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

  double _calculateFare() {
    final dist = _calculateDistanceKm();
    // Standard Boda Rate: strictly K10 per kilometer, minimum K15
    final fare = (dist * 10.0).clamp(15.0, 9999.0);
    return fare;
  }

  void _submitRequest() async {
    final isRide = _selectedTab == 0;
    if (!isRide &&
        (_parcelDescController.text.trim().isEmpty ||
            _recipientPhoneController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter parcel description and recipient contact number.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final rider = _selectedRider ?? _availableRiders.first;
    final distance = _calculateDistanceKm();
    final fare = _calculateFare();
    final safetyPin = '${1000 + math.Random().nextInt(9000)}';
    String rideId = 'boda_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final isTest = (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'));
      if (!isTest) {
        final currentUser = ref.read(authStateProvider).user;
        final docRef = await FirebaseFirestore.instance.collection('ride_requests').add({
          'type': isRide ? 'boda_ride' : 'boda_parcel',
          'userId': currentUser?.uid ?? 'guest_user',
          'userName': currentUser?.displayName ?? 'Valued Client',
          'driverId': rider.id,
          'driverName': rider.driverName,
          'driverPhone': rider.driverPhone,
          'driverPhotoUrl': rider.photoUrl,
          'vehicleModel': rider.bikeModel,
          'licensePlate': rider.licensePlate,
          'driverRating': rider.rating,
          'totalRides': rider.totalRides,
          'pickupName': _pickupLocation.name,
          'pickupLat': _pickupLocation.point.latitude,
          'pickupLng': _pickupLocation.point.longitude,
          'dropoffName': _dropoffLocation.name,
          'dropoffLat': _dropoffLocation.point.latitude,
          'dropoffLng': _dropoffLocation.point.longitude,
          'distanceKm': distance,
          'totalFare': fare,
          'safetyPin': safetyPin,
          'parcelDescription': isRide ? '' : _parcelDescController.text.trim(),
          'recipientPhone': isRide ? '' : _recipientPhoneController.text.trim(),
          'status': 'DRIVER_DISPATCHED',
          'createdAt': FieldValue.serverTimestamp(),
        });
        rideId = docRef.id;
      }
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveRideTrackingScreen(
            rideId: rideId,
            rideType: isRide ? 'boda' : 'parcel',
            driverId: rider.id,
            driverName: rider.driverName,
            driverPhone: rider.driverPhone,
            driverPhotoUrl: rider.photoUrl,
            driverRating: rider.rating,
            totalRides: rider.totalRides,
            vehicleModel: rider.bikeModel,
            licensePlate: rider.licensePlate,
            pickupName: _pickupLocation.name,
            pickupLatLng: _pickupLocation.point,
            dropoffName: _dropoffLocation.name,
            dropoffLatLng: _dropoffLocation.point,
            fare: fare,
            distanceKm: distance,
            safetyPin: safetyPin,
            parcelDescription: isRide ? null : _parcelDescController.text.trim(),
            recipientPhone: isRide ? null : _recipientPhoneController.text.trim(),
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
    final totalFare = _calculateFare();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Boda Boda & Express', style: TextStyle(fontWeight: FontWeight.bold)),
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
              // Standard Rate Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: Colors.white, size: 26),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Standard Boda Rate: K 10.00 / km',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            'Flat, transparent pricing across all Lusaka routes!',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Segmented Tab Toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedTab = 0);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0 ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.two_wheeler_rounded, color: _selectedTab == 0 ? Colors.white : Colors.grey, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Boda Ride',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _selectedTab == 0 ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedTab = 1);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1 ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_shipping_rounded, color: _selectedTab == 1 ? Colors.white : Colors.grey, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Express Delivery',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _selectedTab == 1 ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

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

                    if (_selectedTab == 1) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: _parcelDescController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Parcel Description / Contents',
                          hintText: 'e.g. Important Documents, Package, Spare Part',
                          prefixIcon: const Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 20),
                          filled: true,
                          fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _recipientPhoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Recipient Phone Number',
                          hintText: '097XXXXXXX',
                          prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.success, size: 20),
                          filled: true,
                          fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Fare Breakdown
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
                              const Text('Rate: K10.00 / km', style: TextStyle(fontSize: 11, color: Colors.grey)),
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

              const SizedBox(height: 20),

              // Available Zambian Boda Riders Section
              const Text('Nearby Available Riders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _availableRiders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final rider = _availableRiders[index];
                  final isSelected = _selectedRider?.id == rider.id;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedRider = rider);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            child: HubbleImage(
                              imagePath: rider.photoUrl,
                              width: 48,
                              height: 48,
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(rider.driverName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('${rider.bikeModel} · ${rider.licensePlate}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                    const SizedBox(width: 2),
                                    Text('${rider.rating} (${rider.totalRides} rides)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${rider.etaMinutes} mins', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 12)),
                              const SizedBox(height: 4),
                              Icon(
                                isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                                color: isSelected ? AppColors.primary : Colors.grey,
                                size: 22,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Icon(_selectedTab == 0 ? Icons.two_wheeler_rounded : Icons.local_shipping_rounded, size: 20),
                  label: Text(
                    _isSubmitting
                        ? 'Broadcasting to Rider...'
                        : (_selectedTab == 0
                            ? 'Request Boda (K ${totalFare.toStringAsFixed(0)})'
                            : 'Dispatch Parcel Delivery (K ${totalFare.toStringAsFixed(0)})'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
