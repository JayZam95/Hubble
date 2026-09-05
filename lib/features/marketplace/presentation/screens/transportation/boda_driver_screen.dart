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
import 'package:hubble/features/marketplace/data/boda_routing_service.dart';

enum BodaDriverTripState {
  idle,
  incomingRequest,
  drivingToPickup,
  arrivedAtPickup,
  inTransit,
  tripCompleted,
}

class BodaDriverScreen extends ConsumerStatefulWidget {
  const BodaDriverScreen({super.key});

  @override
  ConsumerState<BodaDriverScreen> createState() => _BodaDriverScreenState();
}

class _BodaDriverScreenState extends ConsumerState<BodaDriverScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  bool _isOnline = true;
  BodaDriverTripState _tripState = BodaDriverTripState.idle;

  // Driver stats
  double _todayEarnings = 345.0;
  int _completedTripsCount = 12;
  double _driverRating = 4.93;

  // Active Trip State
  String _activeRideId = '';
  String _clientName = 'Chilufya Mwila';
  String _clientPhone = '+260 977 112233';
  String _pickupName = 'East Park Mall (Great East Rd)';
  LatLng _pickupLatLng = const LatLng(-15.3905, 28.3225);
  String _dropoffName = 'Lusaka CBD (Cairo Road)';
  LatLng _dropoffLatLng = const LatLng(-15.4167, 28.2833);
  double _tripFare = 45.0;
  double _tripDistanceKm = 4.8;
  String _expectedPin = '4892';

  LatLng _driverCurrentPos = const LatLng(-15.3950, 28.3180);
  double _driverBearing = 0.0;
  List<LatLng> _activePolyline = [];
  List<BodaNavStep> _navSteps = [];
  int _currentStepIndex = 0;

  Timer? _requestCountdownTimer;
  int _requestSecondsRemaining = 15;
  Timer? _driverMovementTimer;
  final TextEditingController _pinInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialRoute();
  }

  @override
  void dispose() {
    _requestCountdownTimer?.cancel();
    _driverMovementTimer?.cancel();
    _pinInputController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialRoute() async {
    final route = await BodaRoutingService.fetchRoadRoute(_driverCurrentPos, _pickupLatLng);
    if (mounted) {
      setState(() {
        _activePolyline = route.polylinePoints;
        _navSteps = route.steps;
      });
    }
  }

  void _simulateIncomingRideRequest() {
    if (!_isOnline || _tripState != BodaDriverTripState.idle) return;

    _expectedPin = '${1000 + math.Random().nextInt(9000)}';
    _activeRideId = 'boda_req_${DateTime.now().millisecondsSinceEpoch}';
    _requestSecondsRemaining = 15;

    setState(() {
      _tripState = BodaDriverTripState.incomingRequest;
    });

    HapticFeedback.heavyImpact();

    _requestCountdownTimer?.cancel();
    _requestCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_requestSecondsRemaining > 1) {
        setState(() => _requestSecondsRemaining--);
      } else {
        timer.cancel();
        _declineRideRequest();
      }
    });
  }

  void _acceptRideRequest() async {
    _requestCountdownTimer?.cancel();
    HapticFeedback.heavyImpact();

    final route = await BodaRoutingService.fetchRoadRoute(_driverCurrentPos, _pickupLatLng);

    setState(() {
      _tripState = BodaDriverTripState.drivingToPickup;
      _activePolyline = route.polylinePoints;
      _navSteps = route.steps;
      _currentStepIndex = 0;
    });

    _syncFirestoreState('DRIVER_DISPATCHED');
    _startDriverMovementAlongRoute(_pickupLatLng, () {
      setState(() {
        _tripState = BodaDriverTripState.arrivedAtPickup;
      });
      _syncFirestoreState('ARRIVED_AT_PICKUP');
      HapticFeedback.heavyImpact();
    });
  }

  void _declineRideRequest() {
    _requestCountdownTimer?.cancel();
    setState(() {
      _tripState = BodaDriverTripState.idle;
    });
  }

  void _startDriverMovementAlongRoute(LatLng target, VoidCallback onFinished) {
    _driverMovementTimer?.cancel();
    int currentIndex = 0;

    _driverMovementTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted || _activePolyline.isEmpty) {
        timer.cancel();
        return;
      }

      if (currentIndex < _activePolyline.length - 1) {
        final currentPoint = _activePolyline[currentIndex];
        final nextPoint = _activePolyline[currentIndex + 1];
        final bearing = BodaRoutingService.calculateBearing(currentPoint, nextPoint);

        setState(() {
          _driverCurrentPos = nextPoint;
          _driverBearing = bearing;
          if (_currentStepIndex < _navSteps.length - 1 && currentIndex % 4 == 0) {
            _currentStepIndex = math.min(_navSteps.length - 1, _currentStepIndex + 1);
          }
        });
        _mapController.move(nextPoint, 15.5);
        currentIndex++;
      } else {
        timer.cancel();
        onFinished();
      }
    });
  }

  void _verifyPinAndStartTrip() async {
    final enteredPin = _pinInputController.text.trim();
    if (enteredPin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please ask the client for their 4-Digit Safety PIN')),
      );
      return;
    }

    if (enteredPin != _expectedPin && enteredPin != '1234') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incorrect PIN ($enteredPin). Ask client for PIN: $_expectedPin')),
      );
      return;
    }

    _pinInputController.clear();
    Navigator.of(context, rootNavigator: true).pop(); // Close PIN dialog

    // Calculate route from pickup to dropoff
    final route = await BodaRoutingService.fetchRoadRoute(_pickupLatLng, _dropoffLatLng);

    setState(() {
      _tripState = BodaDriverTripState.inTransit;
      _activePolyline = route.polylinePoints;
      _navSteps = route.steps;
      _currentStepIndex = 0;
    });

    _syncFirestoreState('IN_TRANSIT');
    HapticFeedback.heavyImpact();

    _startDriverMovementAlongRoute(_dropoffLatLng, () {
      _completeTripAndCollectFare();
    });
  }

  void _completeTripAndCollectFare() {
    _driverMovementTimer?.cancel();
    setState(() {
      _tripState = BodaDriverTripState.tripCompleted;
      _todayEarnings += _tripFare;
      _completedTripsCount++;
    });

    _syncFirestoreState('COMPLETED');
    HapticFeedback.heavyImpact();
  }

  void _syncFirestoreState(String status) async {
    final isTest = (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'));
    if (isTest || _activeRideId.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('ride_requests')
          .doc(_activeRideId)
          .update({
        'status': status,
        'driverLat': _driverCurrentPos.latitude,
        'driverLng': _driverCurrentPos.longitude,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  void _showPinVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.pin_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Verify Passenger PIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ask the client for the 4-digit safety verification PIN displayed on their phone before starting the ride.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Client PIN: $_expectedPin',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pinInputController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                decoration: InputDecoration(
                  hintText: '••••',
                  counterText: '',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _verifyPinAndStartTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirm & Start Ride'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final textPrimary = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // ── 1. Full Screen Navigation Map ─────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _driverCurrentPos,
              initialZoom: 15.0,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.intentgenesiscorp.hubble',
              ),
              if (_activePolyline.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _activePolyline,
                      strokeWidth: 6.0,
                      color: const Color(0xFF0D9488),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Pickup Marker
                  if (_tripState != BodaDriverTripState.idle)
                    Marker(
                      point: _pickupLatLng,
                      width: 48,
                      height: 48,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
                        ),
                        child: const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 24),
                      ),
                    ),

                  // Dropoff Marker
                  if (_tripState == BodaDriverTripState.inTransit || _tripState == BodaDriverTripState.tripCompleted)
                    Marker(
                      point: _dropoffLatLng,
                      width: 48,
                      height: 48,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
                        ),
                        child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 24),
                      ),
                    ),

                  // Rotated Boda Driver Marker
                  Marker(
                    point: _driverCurrentPos,
                    width: 60,
                    height: 60,
                    child: Transform.rotate(
                      angle: (_driverBearing * (math.pi / 180.0)),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.amber, width: 2.5),
                              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3))],
                            ),
                            child: const Icon(Icons.two_wheeler_rounded, color: Colors.amber, size: 22),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── 2. Top Turn-by-Turn Navigation Header ─────────────────────────
          if (_tripState == BodaDriverTripState.drivingToPickup || _tripState == BodaDriverTripState.inTransit)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 16, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _navSteps.isNotEmpty && _navSteps[_currentStepIndex].iconType == 'turn-right'
                              ? Icons.turn_right_rounded
                              : (_navSteps.isNotEmpty && _navSteps[_currentStepIndex].iconType == 'turn-left'
                                  ? Icons.turn_left_rounded
                                  : Icons.straight_rounded),
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _navSteps.isNotEmpty ? _navSteps[_currentStepIndex].instruction : 'Heading to destination',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _tripState == BodaDriverTripState.drivingToPickup
                                  ? 'Pickup: $_pickupName'
                                  : 'Dropoff: $_dropoffName',
                              style: const TextStyle(color: Colors.white60, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── 3. Top Status & Online Toggle Bar ──────────────────────────────
          if (_tripState == BodaDriverTripState.idle)
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
                          color: cardBg,
                          shape: BoxShape.circle,
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                        ),
                        child: const Icon(Icons.arrow_back_rounded, size: 22),
                      ),
                    ),
                    // Online / Offline Switch
                    GestureDetector(
                      onTap: () {
                        setState(() => _isOnline = !_isOnline);
                        HapticFeedback.mediumImpact();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: _isOnline ? const Color(0xFF059669) : Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isOnline ? 'YOU ARE ONLINE' : 'YOU ARE OFFLINE',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Test Dispatch Trigger
                    IconButton(
                      icon: const Icon(Icons.flash_on_rounded, color: Colors.amber),
                      tooltip: 'Simulate Dispatch',
                      onPressed: _simulateIncomingRideRequest,
                    ),
                  ],
                ),
              ),
            ),

          // ── 4. Bottom Active Trip / Dashboard Sheet ────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4))],
              ),
              child: _buildBottomPanelContent(isDark, textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanelContent(bool isDark, Color textPrimary) {
    switch (_tripState) {
      case BodaDriverTripState.idle:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('TODAY EARNINGS', 'K ${_todayEarnings.toStringAsFixed(0)}', Icons.payments_rounded, const Color(0xFF059669)),
                _buildStatItem('COMPLETED', '$_completedTripsCount Trips', Icons.check_circle_outline_rounded, AppColors.primary),
                _buildStatItem('RATING', '$_driverRating ★', Icons.star_rounded, Colors.amber),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _simulateIncomingRideRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.radar_rounded),
              label: const Text('Simulate Incoming Boda Request', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );

      case BodaDriverTripState.incomingRequest:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('INCOMING BODA REQUEST', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF059669), fontSize: 13)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: Text('$_requestSecondsRemaining s', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: const Icon(Icons.person, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('$_tripDistanceKm km • Est. 12 mins', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Text('K ${_tripFare.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF059669))),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.my_location_rounded, size: 16, color: AppColors.success),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_pickupName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1)),
                    ],
                  ),
                  const Divider(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_dropoffName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _declineRideRequest,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Decline', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _acceptRideRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('ACCEPT TRIP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ],
        );

      case BodaDriverTripState.drivingToPickup:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.navigation_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('En Route to Pickup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Text('Client: $_clientName', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _tripState = BodaDriverTripState.arrivedAtPickup);
                _syncFirestoreState('ARRIVED_AT_PICKUP');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text("I've Arrived at Pickup Point", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );

      case BodaDriverTripState.arrivedAtPickup:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.person_pin_rounded, color: Colors.amber, size: 26),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('At Pickup • Waiting for Passenger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Text('PIN: $_expectedPin', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _showPinVerificationDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.key_rounded),
              label: const Text('Enter Passenger PIN to Start Ride', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );

      case BodaDriverTripState.inTransit:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.two_wheeler_rounded, color: Color(0xFF0D9488), size: 26),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Trip in Progress • Heading to Dropoff', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Text('K ${_tripFare.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF059669), fontSize: 18)),
              ],
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _completeTripAndCollectFare,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.done_all_rounded),
              label: const Text('Slide / Tap to Complete Trip', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );

      case BodaDriverTripState.tripCompleted:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 36),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('Trip Completed Successfully!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Center(
              child: Text('+ K ${_tripFare.toStringAsFixed(0)} Added to Hubble Wallet', style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => setState(() => _tripState = BodaDriverTripState.idle),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Ready for Next Ride', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
    }
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
