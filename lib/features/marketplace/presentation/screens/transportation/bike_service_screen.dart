import 'dart:async';
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
import '../../../../auth/presentation/providers/auth_provider.dart';
import 'package:hubble/features/marketplace/data/boda_routing_service.dart';
import 'live_ride_tracking_screen.dart';
import 'boda_driver_screen.dart';

class LusakaLocation {
  final String name;
  final LatLng point;
  final String area;
  final IconData icon;

  const LusakaLocation(
    this.name,
    this.point, {
    this.area = 'Lusaka',
    this.icon = Icons.location_on_rounded,
  });
}

const List<LusakaLocation> kLusakaLocations = [
  LusakaLocation('Lusaka CBD (Cairo Road)', LatLng(-15.4167, 28.2833), area: 'Downtown Commercial', icon: Icons.business_rounded),
  LusakaLocation('East Park Mall (Great East Rd)', LatLng(-15.3905, 28.3225), area: 'Shopping & Dining', icon: Icons.shopping_bag_rounded),
  LusakaLocation('Manda Hill Shopping Mall', LatLng(-15.4022, 28.3031), area: 'Retail Hub', icon: Icons.storefront_rounded),
  LusakaLocation('Woodlands Shopping Mall', LatLng(-15.4410, 28.3280), area: 'Woodlands', icon: Icons.shopping_cart_rounded),
  LusakaLocation('Kabulonga Centro Mall', LatLng(-15.4215, 28.3378), area: 'Kabulonga', icon: Icons.local_cafe_rounded),
  LusakaLocation('Intercity Bus Terminus', LatLng(-15.4270, 28.2885), area: 'Transit Terminal', icon: Icons.directions_bus_rounded),
  LusakaLocation('UNZA Great East Campus', LatLng(-15.3920, 28.3330), area: 'University Main Gate', icon: Icons.school_rounded),
  LusakaLocation('Roma Girls High School', LatLng(-15.3780, 28.3100), area: 'Roma', icon: Icons.place_rounded),
  LusakaLocation('Chilenje Market & Station', LatLng(-15.4520, 28.3200), area: 'Chilenje South', icon: Icons.local_grocery_store_rounded),
  LusakaLocation('Kamwala Shopping Center', LatLng(-15.4310, 28.2850), area: 'Kamwala Trading', icon: Icons.store_rounded),
  LusakaLocation('Kenneth Kaunda Int Airport (KKIA)', LatLng(-15.3308, 28.4526), area: 'Airport Terminal', icon: Icons.flight_takeoff_rounded),
  LusakaLocation('Levy Junction Mall', LatLng(-15.4190, 28.2910), area: 'Church Road', icon: Icons.local_mall_rounded),
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
  final bool hasExtraHelmet;

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
    this.hasExtraHelmet = true,
  });
}

class BikeServiceScreen extends ConsumerStatefulWidget {
  final int initialTabIndex; // 0 = Passenger Ride, 1 = Express Parcel, 2 = Comfort
  const BikeServiceScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<BikeServiceScreen> createState() => _BikeServiceScreenState();
}

class _BikeServiceScreenState extends ConsumerState<BikeServiceScreen>
    with SingleTickerProviderStateMixin {
  late int _selectedTab; // 0 = Standard Ride, 1 = Express Parcel, 2 = Comfort XL

  LusakaLocation _pickupLocation = kLusakaLocations[0];
  LusakaLocation _dropoffLocation = kLusakaLocations[1];
  LatLng? _clientGpsLocation;

  // Delivery details
  final TextEditingController _parcelDescController = TextEditingController();
  final TextEditingController _recipientPhoneController = TextEditingController();
  final TextEditingController _promoController = TextEditingController();

  String _selectedPaymentMethod = 'Wallet'; // 'Wallet', 'MTN MoMo', 'Airtel Money', 'Cash'
  String? _appliedPromoCode;
  double _promoDiscount = 0.0;

  final MapController _mapController = MapController();
  bool _isSearchingLocation = false;
  bool _isLocatingGps = false;
  List<LatLng> _routePolyline = [];

  BodaRiderModel? _selectedRider;
  Timer? _roamingTimer;

  final List<BodaRiderModel> _availableRiders = [
    BodaRiderModel(
      id: 'boda_1',
      driverName: 'Moses Sakala',
      driverPhone: '+260 977 293122',
      bikeModel: 'TVS HLX 150 (Red)',
      licensePlate: 'BAR 2931',
      rating: 4.92,
      totalRides: 480,
      etaMinutes: 2,
      photoUrl: 'https://images.unsplash.com/photo-1522529599102-193c0d76b5b6?auto=format&fit=crop&w=300&q=80',
      position: const LatLng(-15.4150, 28.2840),
      hasExtraHelmet: true,
    ),
    BodaRiderModel(
      id: 'boda_2',
      driverName: 'Kabwe Musonda',
      driverPhone: '+260 966 882044',
      bikeModel: 'Bajaj Boxer BM150 (Black)',
      licensePlate: 'BAT 8820',
      rating: 4.88,
      totalRides: 310,
      etaMinutes: 4,
      photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fit=crop&w=300&q=80',
      position: const LatLng(-15.4190, 28.2810),
      hasExtraHelmet: true,
    ),
    BodaRiderModel(
      id: 'boda_3',
      driverName: 'Gershom Nyirenda',
      driverPhone: '+260 955 410288',
      bikeModel: 'Lifan 125 (Blue)',
      licensePlate: 'BAV 4102',
      rating: 4.96,
      totalRides: 620,
      etaMinutes: 5,
      photoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80',
      position: const LatLng(-15.4130, 28.2870),
      hasExtraHelmet: true,
    ),
    BodaRiderModel(
      id: 'boda_4',
      driverName: 'Enoch Phiri',
      driverPhone: '+260 971 559022',
      bikeModel: 'Haojue Express 150',
      licensePlate: 'ABC 3391',
      rating: 4.85,
      totalRides: 270,
      etaMinutes: 3,
      photoUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=300&q=80',
      position: const LatLng(-15.4180, 28.2860),
      hasExtraHelmet: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
    _selectedRider = _availableRiders.first;
    _fetchRoadPolyline();
    _startRiderRoamingSimulation();
  }

  @override
  void dispose() {
    _roamingTimer?.cancel();
    _parcelDescController.dispose();
    _recipientPhoneController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  void _startRiderRoamingSimulation() {
    // Periodically update boda positions slightly for active dynamic map feel
    _roamingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < _availableRiders.length; i++) {
          final r = _availableRiders[i];
          final latOffset = (math.Random().nextDouble() - 0.5) * 0.0004;
          final lngOffset = (math.Random().nextDouble() - 0.5) * 0.0004;
          _availableRiders[i] = BodaRiderModel(
            id: r.id,
            driverName: r.driverName,
            driverPhone: r.driverPhone,
            bikeModel: r.bikeModel,
            licensePlate: r.licensePlate,
            rating: r.rating,
            totalRides: r.totalRides,
            etaMinutes: math.max(1, r.etaMinutes),
            photoUrl: r.photoUrl,
            position: LatLng(r.position.latitude + latOffset, r.position.longitude + lngOffset),
            hasExtraHelmet: r.hasExtraHelmet,
          );
        }
      });
    });
  }

  Future<void> _detectClientGps() async {
    setState(() => _isLocatingGps = true);
    final pos = await BodaRoutingService.getCurrentDeviceLocation();
    if (!mounted) return;
    setState(() => _isLocatingGps = false);

    if (pos != null) {
      final gpsPoint = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _clientGpsLocation = gpsPoint;
        _pickupLocation = LusakaLocation('Current GPS Location', gpsPoint, icon: Icons.my_location_rounded);
      });
      _mapController.move(gpsPoint, 15.0);
      _fetchRoadPolyline();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Accurate GPS Location Locked!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Using default Lusaka CBD location (GPS permission disabled or unavailable).'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _fetchRoadPolyline() async {
    final start = _pickupLocation.point;
    final end = _dropoffLocation.point;
    final result = await BodaRoutingService.fetchRoadRoute(start, end);
    if (mounted) {
      setState(() {
        _routePolyline = result.polylinePoints;
      });
    }
  }

  double _getCalculatedDistance() {
    return BodaRoutingService.calculateHaversineDistanceKm(
      _pickupLocation.point,
      _dropoffLocation.point,
    );
  }

  double _getCalculatedFare() {
    final dist = _getCalculatedDistance();
    String typeKey = 'standard';
    if (_selectedTab == 1) typeKey = 'parcel';
    if (_selectedTab == 2) typeKey = 'comfort';

    return BodaRoutingService.calculateBodaFare(
      distanceKm: dist,
      rideType: typeKey,
      promoCode: _appliedPromoCode,
    );
  }

  void _applyPromoCode() {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    if (code == 'HUBBLEBODA' || code == 'BODA10' || code == 'FIRSTFREE' || code == 'YANGO') {
      setState(() {
        _appliedPromoCode = code;
        _promoDiscount = code == 'FIRSTFREE' || code == 'YANGO' ? 0.20 : 10.0;
      });
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Promo "$code" applied successfully!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid promo code. Try "HUBBLEBODA" or "FIRSTFREE".'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showLocationPicker(bool isPickup) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final sheetBg = isDark ? AppColors.surfaceDark : Colors.white;
            final textPrimary = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;

            final filteredLocations = kLusakaLocations.where((loc) {
              return loc.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  loc.area.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isPickup ? 'Select Pickup Point' : 'Select Destination',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // Search box
                  TextField(
                    onChanged: (val) => setModalState(() => searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search landmark, mall, or street...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: isDark ? Colors.white12 : Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (isPickup)
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.my_location_rounded, color: AppColors.primary),
                      ),
                      title: const Text('Use Current GPS Location', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('High accuracy device coordinates'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _detectClientGps();
                      },
                    ),
                  const Divider(),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filteredLocations.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final loc = filteredLocations[idx];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(loc.icon, color: AppColors.primary, size: 22),
                          ),
                          title: Text(loc.name, style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                          subtitle: Text(loc.area, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
                          onTap: () {
                            setState(() {
                              if (isPickup) {
                                _pickupLocation = loc;
                              } else {
                                _dropoffLocation = loc;
                              }
                            });
                            _mapController.move(loc.point, 14.0);
                            _fetchRoadPolyline();
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _initiateYangoRadarDispatch() {
    final isRide = _selectedTab != 1;
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

    final rider = _selectedRider ?? _availableRiders.first;
    final distance = _getCalculatedDistance();
    final fare = _getCalculatedFare();
    final safetyPin = '${1000 + math.Random().nextInt(9000)}';

    // Show Yango-Style Radar Matching Screen
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (radarContext) {
        return _YangoRadarDispatchSheet(
          pickupName: _pickupLocation.name,
          dropoffName: _dropoffLocation.name,
          fare: fare,
          matchedRider: rider,
          onMatched: () async {
            String rideId = 'boda_${DateTime.now().millisecondsSinceEpoch}';
            try {
              final isTest = (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'));
              if (!isTest) {
                final currentUser = ref.read(authStateProvider).user;
                final docRef = await FirebaseFirestore.instance.collection('ride_requests').add({
                  'type': _selectedTab == 1 ? 'boda_parcel' : (_selectedTab == 2 ? 'boda_comfort' : 'boda_ride'),
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
                  'paymentMethod': _selectedPaymentMethod,
                  'safetyPin': safetyPin,
                  'parcelDescription': isRide ? '' : _parcelDescController.text.trim(),
                  'recipientPhone': isRide ? '' : _recipientPhoneController.text.trim(),
                  'status': 'DRIVER_DISPATCHED',
                  'createdAt': FieldValue.serverTimestamp(),
                });
                rideId = docRef.id;
              }
            } catch (_) {}

            if (context.mounted) {
              Navigator.pop(radarContext); // Dismiss radar sheet
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LiveRideTrackingScreen(
                    rideId: rideId,
                    rideType: _selectedTab == 1 ? 'parcel' : 'boda',
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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textPrimary = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final distance = _getCalculatedDistance();
    final totalFare = _getCalculatedFare();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // ── 1. Map View with Live Boda Riders ──────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pickupLocation.point,
              initialZoom: 13.8,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.intentgenesiscorp.hubble',
              ),
              // Route Polyline
              if (_routePolyline.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePolyline,
                      strokeWidth: 5.0,
                      color: const Color(0xFF0D9488),
                    ),
                  ],
                ),
              // Marker Layer
              MarkerLayer(
                markers: [
                  // Pickup Marker
                  Marker(
                    point: _pickupLocation.point,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 24),
                    ),
                  ),

                  // Dropoff Marker
                  Marker(
                    point: _dropoffLocation.point,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 24),
                    ),
                  ),

                  // Roaming Boda Riders
                  ..._availableRiders.map(
                    (rider) => Marker(
                      point: rider.position,
                      width: 56,
                      height: 56,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedRider = rider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${rider.driverName} (${rider.bikeModel}) selected • ${rider.etaMinutes} mins away'),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedRider?.id == rider.id ? Colors.amber : const Color(0xFF14B8A6),
                                  width: 2.0,
                                ),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
                                ],
                              ),
                              child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF14B8A6), size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── 2. Top Header Bar & Driver Partner Mode Switch ────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cardColor,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 22),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bolt_rounded, color: Color(0xFF059669), size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Hubble Boda Express',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  // Boda Driver Mode Button
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BodaDriverScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.sports_motorsports_rounded, color: Colors.amber, size: 16),
                          SizedBox(width: 6),
                          Text('Driver Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 3. Floating GPS Center Action Button ──────────────────────────
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).size.height * 0.46,
            child: FloatingActionButton.small(
              heroTag: 'boda_gps_btn',
              onPressed: _detectClientGps,
              backgroundColor: cardColor,
              foregroundColor: AppColors.primary,
              elevation: 4,
              child: _isLocatingGps
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
            ),
          ),

          // ── 4. Bottom Booking Control Sheet ───────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.44,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag indicator
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category Toggle Pills (Standard, Parcel, Comfort)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _buildTabPill(0, 'Boda Standard', Icons.two_wheeler_rounded),
                          _buildTabPill(1, 'Express Parcel', Icons.inventory_2_rounded),
                          _buildTabPill(2, 'Comfort XL', Icons.electric_moped_rounded),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Pickup and Dropoff Address Cards
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          // Pickup
                          InkWell(
                            onTap: () => _showLocationPicker(true),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('PICKUP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                      Text(
                                        _pickupLocation.name,
                                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.edit_location_alt_rounded, size: 18, color: Colors.grey),
                              ],
                            ),
                          ),
                          const Divider(height: 16),
                          // Dropoff
                          InkWell(
                            onTap: () => _showLocationPicker(false),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('DROP-OFF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                      Text(
                                        _dropoffLocation.name,
                                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.edit_location_alt_rounded, size: 18, color: Colors.grey),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Parcel Fields if Express Delivery is active
                    if (_selectedTab == 1) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _parcelDescController,
                              decoration: InputDecoration(
                                hintText: 'Parcel details (e.g. Documents, Bag)',
                                hintStyle: const TextStyle(fontSize: 12),
                                isDense: true,
                                prefixIcon: const Icon(Icons.inventory_rounded, size: 18),
                                filled: true,
                                fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _recipientPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                hintText: 'Recipient Phone',
                                hintStyle: const TextStyle(fontSize: 12),
                                isDense: true,
                                prefixIcon: const Icon(Icons.phone_rounded, size: 18),
                                filled: true,
                                fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Payment & Promo Row
                    Row(
                      children: [
                        // Payment Method Dropdown
                        Expanded(
                          child: InkWell(
                            onTap: _showPaymentMethodSheet,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(_getPaymentIcon(_selectedPaymentMethod), size: 18, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedPaymentMethod,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down_rounded, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Promo Button
                        InkWell(
                          onTap: _showPromoDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _appliedPromoCode != null
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : (isDark ? Colors.white10 : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.local_offer_rounded,
                                  size: 16,
                                  color: _appliedPromoCode != null ? AppColors.success : Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _appliedPromoCode != null ? '-$_appliedPromoCode' : 'Promo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _appliedPromoCode != null ? AppColors.success : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Fare and Request Button
                    ElevatedButton(
                      onPressed: _initiateYangoRadarDispatch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.two_wheeler_rounded, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'Request Boda • K ${totalFare.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${distance.toStringAsFixed(1)} km)',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _selectedTab = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0D9488) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'MTN MoMo':
      case 'Airtel Money':
        return Icons.phone_android_rounded;
      case 'Cash':
        return Icons.money_rounded;
      case 'Wallet':
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  void _showPaymentMethodSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Payment Option', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
                title: const Text('Hubble Escrow Wallet (Recommended)'),
                subtitle: const Text('Fast, secure instant release on safe arrival'),
                trailing: _selectedPaymentMethod == 'Wallet' ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                onTap: () {
                  setState(() => _selectedPaymentMethod = 'Wallet');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone_android_rounded, color: Colors.amber),
                title: const Text('MTN Mobile Money'),
                trailing: _selectedPaymentMethod == 'MTN MoMo' ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                onTap: () {
                  setState(() => _selectedPaymentMethod = 'MTN MoMo');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone_android_rounded, color: Colors.redAccent),
                title: const Text('Airtel Money'),
                trailing: _selectedPaymentMethod == 'Airtel Money' ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                onTap: () {
                  setState(() => _selectedPaymentMethod = 'Airtel Money');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.payments_rounded, color: Colors.green),
                title: const Text('Cash to Driver'),
                trailing: _selectedPaymentMethod == 'Cash' ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                onTap: () {
                  setState(() => _selectedPaymentMethod = 'Cash');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPromoDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.local_offer_rounded, color: Color(0xFF0D9488)),
              SizedBox(width: 8),
              Text('Enter Promo Code'),
            ],
          ),
          content: TextField(
            controller: _promoController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'e.g. HUBBLEBODA or FIRSTFREE',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _applyPromoCode();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }
}

/// Yango-style animated radar matching bottom sheet
class _YangoRadarDispatchSheet extends StatefulWidget {
  final String pickupName;
  final String dropoffName;
  final double fare;
  final BodaRiderModel matchedRider;
  final VoidCallback onMatched;

  const _YangoRadarDispatchSheet({
    required this.pickupName,
    required this.dropoffName,
    required this.fare,
    required this.matchedRider,
    required this.onMatched,
  });

  @override
  State<_YangoRadarDispatchSheet> createState() => _YangoRadarDispatchSheetState();
}

class _YangoRadarDispatchSheetState extends State<_YangoRadarDispatchSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarAnim;
  bool _isDriverMatched = false;
  int _nearbyContacted = 1;
  Timer? _matchingTimer;

  @override
  void initState() {
    super.initState();
    _radarAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Radar simulation: sweep for 3 seconds then match driver
    _matchingTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _isDriverMatched = true;
        _nearbyContacted = 4;
      });
      HapticFeedback.heavyImpact();

      // Hold matched card for 1.2s then navigate
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) {
          widget.onMatched();
        }
      });
    });
  }

  @override
  void dispose() {
    _matchingTimer?.cancel();
    _radarAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.surfaceDark : Colors.white;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 24, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 20),

          if (!_isDriverMatched) ...[
            // Animated Radar Pulse
            AnimatedBuilder(
              animation: _radarAnim,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120 * _radarAnim.value,
                      height: 120 * _radarAnim.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0D9488).withValues(
                          alpha: (1.0 - _radarAnim.value) * 0.4,
                        ),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                      ),
                      child: const Icon(
                        Icons.radar_rounded,
                        color: Color(0xFF0D9488),
                        size: 40,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Finding Closest Boda Rider...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Contacted $_nearbyContacted nearby riders in your area',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
            ),
          ] else ...[
            // Driver Matched Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.success, size: 36),
            ),
            const SizedBox(height: 12),
            const Text(
              'Boda Rider Found!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.matchedRider.driverName} is on the way (${widget.matchedRider.etaMinutes} min away)',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(widget.matchedRider.photoUrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.matchedRider.driverName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          '${widget.matchedRider.bikeModel} • ${widget.matchedRider.licensePlate}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          widget.matchedRider.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
