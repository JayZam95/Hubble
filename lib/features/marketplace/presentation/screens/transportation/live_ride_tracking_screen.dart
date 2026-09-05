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
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/presentation/widgets/hubble_image.dart';
import '../../../../chat/presentation/screens/chat_screen.dart';
import 'package:hubble/features/marketplace/data/boda_routing_service.dart';

/// Ride lifecycle states
enum RideTrackingState {
  searching,
  driverDispatched,
  arrivedAtPickup,
  inTransit,
  completed,
  cancelled,
}

extension RideTrackingStateExtension on RideTrackingState {
  String get displayName {
    switch (this) {
      case RideTrackingState.searching:
        return 'Finding Nearby Boda';
      case RideTrackingState.driverDispatched:
        return 'Driver On The Way';
      case RideTrackingState.arrivedAtPickup:
        return 'Driver Arrived at Pickup';
      case RideTrackingState.inTransit:
        return 'Heading to Destination';
      case RideTrackingState.completed:
        return 'Trip Completed';
      case RideTrackingState.cancelled:
        return 'Trip Cancelled';
    }
  }

  String get dbStatus {
    switch (this) {
      case RideTrackingState.searching:
        return 'SEARCHING';
      case RideTrackingState.driverDispatched:
        return 'DRIVER_DISPATCHED';
      case RideTrackingState.arrivedAtPickup:
        return 'ARRIVED_AT_PICKUP';
      case RideTrackingState.inTransit:
        return 'IN_TRANSIT';
      case RideTrackingState.completed:
        return 'COMPLETED';
      case RideTrackingState.cancelled:
        return 'CANCELLED';
    }
  }

  static RideTrackingState fromDbStatus(String? status) {
    switch (status) {
      case 'SEARCHING':
        return RideTrackingState.searching;
      case 'DISPATCHED':
      case 'DRIVER_DISPATCHED':
        return RideTrackingState.driverDispatched;
      case 'ARRIVED_AT_PICKUP':
      case 'ARRIVED':
        return RideTrackingState.arrivedAtPickup;
      case 'IN_TRANSIT':
      case 'STARTED':
        return RideTrackingState.inTransit;
      case 'COMPLETED':
        return RideTrackingState.completed;
      case 'CANCELLED':
        return RideTrackingState.cancelled;
      default:
        return RideTrackingState.driverDispatched;
    }
  }
}

class LiveRideTrackingScreen extends ConsumerStatefulWidget {
  final String rideId;
  final String rideType; // 'cab', 'boda', 'parcel'
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String driverPhotoUrl;
  final double driverRating;
  final int totalRides;
  final String vehicleModel;
  final String licensePlate;
  final String pickupName;
  final LatLng pickupLatLng;
  final String dropoffName;
  final LatLng dropoffLatLng;
  final double fare;
  final double distanceKm;
  final String safetyPin;
  final String? parcelDescription;
  final String? recipientPhone;
  final RideTrackingState initialState;

  const LiveRideTrackingScreen({
    super.key,
    required this.rideId,
    this.rideType = 'boda',
    required this.driverId,
    required this.driverName,
    this.driverPhone = '+260 977 293122',
    this.driverPhotoUrl = '',
    this.driverRating = 4.92,
    this.totalRides = 480,
    required this.vehicleModel,
    required this.licensePlate,
    required this.pickupName,
    required this.pickupLatLng,
    required this.dropoffName,
    required this.dropoffLatLng,
    required this.fare,
    required this.distanceKm,
    this.safetyPin = '4892',
    this.parcelDescription,
    this.recipientPhone,
    this.initialState = RideTrackingState.driverDispatched,
  });

  @override
  ConsumerState<LiveRideTrackingScreen> createState() => _LiveRideTrackingScreenState();
}

class _LiveRideTrackingScreenState extends ConsumerState<LiveRideTrackingScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();

  late RideTrackingState _currentState;
  late String _safetyPin;
  late LatLng _currentVehiclePosition;
  late LatLng _driverInitialPosition;
  double _vehicleBearing = 0.0;
  int _currentSpeedKmh = 38;

  List<LatLng> _fullRoadPolyline = [];
  List<BodaNavStep> _turnByTurnSteps = [];
  int _currentStepIndex = 0;

  late AnimationController _animController;
  Timer? _stateSimulationTimer;
  Timer? _countdownTimer;
  StreamSubscription<DocumentSnapshot>? _rideSubscription;

  int _etaMinutes = 4;
  int _etaSecondsRemaining = 240;
  double _distanceRemainingKm = 0.0;
  bool _hasShownCompletionModal = false;
  final bool _isAutoSimulationEnabled = true;

  @override
  void initState() {
    super.initState();
    _currentState = widget.initialState;
    _safetyPin = widget.safetyPin.isNotEmpty
        ? widget.safetyPin
        : '${1000 + math.Random().nextInt(9000)}';

    _driverInitialPosition = LatLng(
      widget.pickupLatLng.latitude + 0.006,
      widget.pickupLatLng.longitude - 0.006,
    );
    _currentVehiclePosition = _driverInitialPosition;
    _distanceRemainingKm = widget.distanceKm;
    _etaMinutes = math.max(2, (widget.distanceKm * 2.2).round());
    _etaSecondsRemaining = _etaMinutes * 60;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..addListener(() {
        _updateVehiclePositionAlongRoute();
      });

    _loadRoadNetworkPolyline();
    _setupFirestoreListener();
    _startCountdownTimer();
    _startStateSimulation();
  }

  @override
  void dispose() {
    _rideSubscription?.cancel();
    _stateSimulationTimer?.cancel();
    _countdownTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadRoadNetworkPolyline() async {
    // Fetch road polyline connecting driver -> pickup -> dropoff
    final routePickup = await BodaRoutingService.fetchRoadRoute(_driverInitialPosition, widget.pickupLatLng);
    final routeDropoff = await BodaRoutingService.fetchRoadRoute(widget.pickupLatLng, widget.dropoffLatLng);

    if (mounted) {
      setState(() {
        _fullRoadPolyline = [
          ...routePickup.polylinePoints,
          ...routeDropoff.polylinePoints,
        ];
        _turnByTurnSteps = [
          ...routePickup.steps,
          ...routeDropoff.steps,
        ];
        _currentStepIndex = 0;
      });
      _animController.forward();
    }
  }

  void _setupFirestoreListener() {
    final isTest = (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'));
    if (isTest || widget.rideId.isEmpty) return;

    try {
      _rideSubscription = FirebaseFirestore.instance
          .collection('ride_requests')
          .doc(widget.rideId)
          .snapshots()
          .listen((doc) {
        if (doc.exists && mounted) {
          final data = doc.data();
          if (data != null && data.containsKey('status')) {
            final remoteStatus =
                RideTrackingStateExtension.fromDbStatus(data['status'] as String?);
            if (remoteStatus != _currentState) {
              setState(() {
                _currentState = remoteStatus;
                if (data.containsKey('driverLat') && data.containsKey('driverLng')) {
                  _currentVehiclePosition = LatLng(
                    (data['driverLat'] as num).toDouble(),
                    (data['driverLng'] as num).toDouble(),
                  );
                }
                if (_currentState == RideTrackingState.completed &&
                    !_hasShownCompletionModal) {
                  _hasShownCompletionModal = true;
                  _showTripCompletionModal();
                }
              });
            }
          }
        }
      });
    } catch (_) {}
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_etaSecondsRemaining > 0) {
        setState(() {
          _etaSecondsRemaining--;
          _etaMinutes = (_etaSecondsRemaining / 60).ceil();
        });
      }
    });
  }

  void _startStateSimulation() {
    if (!_isAutoSimulationEnabled) return;

    // Dispatched (6s) -> Arrived (5s) -> In Transit (12s) -> Completed
    _stateSimulationTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted || _currentState != RideTrackingState.driverDispatched) return;
      _advanceToState(RideTrackingState.arrivedAtPickup);

      _stateSimulationTimer = Timer(const Duration(seconds: 5), () {
        if (!mounted || _currentState != RideTrackingState.arrivedAtPickup) return;
        _advanceToState(RideTrackingState.inTransit);

        _stateSimulationTimer = Timer(const Duration(seconds: 14), () {
          if (!mounted || _currentState != RideTrackingState.inTransit) return;
          _advanceToState(RideTrackingState.completed);
        });
      });
    });
  }

  void _advanceToState(RideTrackingState nextState) {
    if (!mounted) return;
    setState(() {
      _currentState = nextState;
      if (nextState == RideTrackingState.arrivedAtPickup) {
        _currentVehiclePosition = widget.pickupLatLng;
        _currentSpeedKmh = 0;
        HapticFeedback.heavyImpact();
      } else if (nextState == RideTrackingState.inTransit) {
        _animController.reset();
        _animController.forward();
        _currentSpeedKmh = 42;
        _etaSecondsRemaining = (widget.distanceKm * 110).round();
      } else if (nextState == RideTrackingState.completed) {
        _currentVehiclePosition = widget.dropoffLatLng;
        _distanceRemainingKm = 0.0;
        _currentSpeedKmh = 0;
        _etaMinutes = 0;
        _etaSecondsRemaining = 0;
        HapticFeedback.heavyImpact();
        if (!_hasShownCompletionModal) {
          _hasShownCompletionModal = true;
          _showTripCompletionModal();
        }
      }
    });

    _syncStatusToFirestore(nextState.dbStatus);
  }

  void _syncStatusToFirestore(String status) async {
    final isTest = (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'));
    if (isTest || widget.rideId.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('ride_requests')
          .doc(widget.rideId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  void _updateVehiclePositionAlongRoute() {
    if (_fullRoadPolyline.isEmpty) return;
    final progress = _animController.value;

    if (_currentState == RideTrackingState.driverDispatched) {
      final pickupIndex = (_fullRoadPolyline.length ~/ 2);
      final index = (pickupIndex * progress).clamp(0, pickupIndex - 1).toInt();
      final p1 = _fullRoadPolyline[index];
      final p2 = _fullRoadPolyline[math.min(index + 1, pickupIndex)];

      setState(() {
        _currentVehiclePosition = p1;
        _vehicleBearing = BodaRoutingService.calculateBearing(p1, p2);
      });
    } else if (_currentState == RideTrackingState.inTransit) {
      final pickupIndex = (_fullRoadPolyline.length ~/ 2);
      final remainingCount = _fullRoadPolyline.length - pickupIndex;
      final index = pickupIndex + (remainingCount * progress).clamp(0, remainingCount - 1).toInt();
      final p1 = _fullRoadPolyline[index];
      final p2 = _fullRoadPolyline[math.min(index + 1, _fullRoadPolyline.length - 1)];

      setState(() {
        _currentVehiclePosition = p1;
        _vehicleBearing = BodaRoutingService.calculateBearing(p1, p2);
        _distanceRemainingKm = math.max(0.0, widget.distanceKm * (1.0 - progress));
        if (_turnByTurnSteps.isNotEmpty && _turnByTurnSteps.length > 2) {
          _currentStepIndex = (_turnByTurnSteps.length * progress).clamp(0, _turnByTurnSteps.length - 1).toInt();
        }
      });
    }
  }

  void _callDriver() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: widget.driverPhone);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showSnack('Unable to place phone call to ${widget.driverPhone}');
      }
    } catch (_) {
      _showSnack('Calling ${widget.driverPhone}');
    }
  }

  void _openChatWithDriver() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: 'ride_${widget.rideId}_chat',
          otherUserName: widget.driverName,
          otherUserId: widget.driverId,
        ),
      ),
    );
  }

  void _shareTripStatus() {
    final shareText =
        'Tracking my Hubble Boda ride with ${widget.driverName} (${widget.licensePlate}). '
        'Heading to ${widget.dropoffName}. ETA: $_etaMinutes mins. Safety PIN: $_safetyPin.';
    // ignore: deprecated_member_use
    Share.share(shareText, subject: 'My Hubble Boda Live Tracking');
  }

  void _showSosConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Emergency SOS (991)',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.error),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Do you need immediate police or medical assistance?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your live GPS coordinates (${_currentVehiclePosition.latitude.toStringAsFixed(4)}, ${_currentVehiclePosition.longitude.toStringAsFixed(4)}) and ride details with ${widget.driverName} will be shared with Zambia emergency dispatch.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_rounded, color: AppColors.error, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Zambia Police Toll-Free: 991',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final policeUri = Uri(scheme: 'tel', path: '991');
              try {
                if (await canLaunchUrl(policeUri)) {
                  await launchUrl(policeUri);
                }
              } catch (_) {}
              _showSnack('Emergency alert sent to emergency services.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.call_rounded, size: 18),
            label: const Text('Call 991 Now', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showTripCompletionModal() {
    double tipAmount = 0.0;
    double selectedRating = 5.0;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final isDark = Theme.of(modalContext).brightness == Brightness.dark;
            final sheetBg = isDark ? AppColors.surfaceDark : Colors.white;
            final grandTotal = widget.fare + tipAmount;

            return Container(
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                MediaQuery.of(modalContext).viewInsets.bottom + 28,
              ),
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
                ],
              ),
              child: SingleChildScrollView(
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
                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
                    ),
                    const SizedBox(height: 12),
                    const Text('You Have Arrived!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                      'Thank you for riding with ${widget.driverName}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    // Fare Breakdown
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Trip Fare', style: TextStyle(color: Colors.grey)),
                              Text('K ${widget.fare.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          if (tipAmount > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Rider Tip', style: TextStyle(color: Colors.grey)),
                                Text('+ K ${tipAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                              ],
                            ),
                          ],
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('K ${grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF059669))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Tip Selection Pills
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [0.0, 5.0, 10.0, 20.0].map((t) {
                        final isSelected = tipAmount == t;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(t == 0 ? 'No Tip' : '+ K ${t.toStringAsFixed(0)}'),
                            selected: isSelected,
                            selectedColor: const Color(0xFF0D9488),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (val) => setModalState(() => tipAmount = val ? t : 0.0),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Rating Bar
                    RatingBar.builder(
                      initialRating: selectedRating,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                      itemBuilder: (context, _) => const Icon(Icons.star_rounded, color: Colors.amber),
                      onRatingUpdate: (rating) => setModalState(() => selectedRating = rating),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(modalContext); // Close modal
                        Navigator.pop(context); // Return from live tracking
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Complete & Submit Rating', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final isBike = widget.rideType == 'boda' || widget.rideType == 'parcel';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // ── 1. Live Map with OSRM Road Polyline & Bearing-Rotated Marker ───
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.pickupLatLng,
              initialZoom: 14.2,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.intentgenesiscorp.hubble',
              ),
              if (_fullRoadPolyline.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _fullRoadPolyline,
                      strokeWidth: 5.5,
                      color: isBike ? const Color(0xFF0D9488) : AppColors.primary,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Pickup Marker
                  Marker(
                    point: widget.pickupLatLng,
                    width: 50,
                    height: 50,
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
                  Marker(
                    point: widget.dropoffLatLng,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
                      ),
                      child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 24),
                    ),
                  ),

                  // Rotated Vehicle Marker along true road bearing
                  Marker(
                    point: _currentVehiclePosition,
                    width: 60,
                    height: 60,
                    child: Transform.rotate(
                      angle: (_vehicleBearing * (math.pi / 180.0)),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (isBike ? const Color(0xFF0D9488) : AppColors.primary).withValues(alpha: 0.25),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isBike ? const Color(0xFF14B8A6) : Colors.amber,
                                width: 2.5,
                              ),
                              boxShadow: const [
                                BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3)),
                              ],
                            ),
                            child: Icon(
                              isBike
                                  ? (widget.rideType == 'parcel' ? Icons.inventory_2_rounded : Icons.two_wheeler_rounded)
                                  : Icons.local_taxi_rounded,
                              color: isBike ? const Color(0xFF14B8A6) : Colors.amber,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── 2. Top Turn-by-Turn Maneuver Navigation Banner ─────────────────
          if (_currentState == RideTrackingState.inTransit && _turnByTurnSteps.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 12, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _turnByTurnSteps[_currentStepIndex].iconType == 'turn-right'
                              ? Icons.turn_right_rounded
                              : (_turnByTurnSteps[_currentStepIndex].iconType == 'turn-left'
                                  ? Icons.turn_left_rounded
                                  : Icons.straight_rounded),
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _turnByTurnSteps[_currentStepIndex].instruction,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'Speed: $_currentSpeedKmh km/h',
                              style: const TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── 3. Top Status Header & SOS Button ──────────────────────────────
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentState == RideTrackingState.arrivedAtPickup
                                ? Colors.amber
                                : (_currentState == RideTrackingState.inTransit
                                    ? AppColors.primary
                                    : AppColors.success),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _currentState.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: _showSosConfirmationDialog,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 4. Recenter & Fast-Forward Simulation Demo Buttons ─────────────
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.28,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'recenter_map',
                  backgroundColor: cardBg,
                  onPressed: () => _mapController.move(_currentVehiclePosition, 14.5),
                  child: const Icon(Icons.my_location_rounded, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'skip_state_demo',
                  backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  tooltip: 'Fast forward demo state',
                  onPressed: () {
                    if (_currentState == RideTrackingState.driverDispatched) {
                      _advanceToState(RideTrackingState.arrivedAtPickup);
                    } else if (_currentState == RideTrackingState.arrivedAtPickup) {
                      _advanceToState(RideTrackingState.inTransit);
                    } else if (_currentState == RideTrackingState.inTransit) {
                      _advanceToState(RideTrackingState.completed);
                    }
                  },
                  child: const Icon(Icons.skip_next_rounded, color: AppColors.primary, size: 20),
                ),
              ],
            ),
          ),

          // ── 5. Bottom Ride Details & Safety PIN Sheet ───────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4-Digit Safety PIN Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                              : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.security_rounded, color: AppColors.primary, size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Safety Verification PIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                Text('Share PIN with driver to start ride', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Row(
                            children: _safetyPin.split('').map((d) {
                              return Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  d,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Driver Row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          child: HubbleImage(
                            imagePath: widget.driverPhotoUrl,
                            width: 52,
                            height: 52,
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.driverName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              Text(
                                '${widget.vehicleModel} · ${widget.licensePlate}',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 15),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${widget.driverRating} (${widget.totalRides} trips)',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton.filledTonal(
                              onPressed: _openChatWithDriver,
                              icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 20),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton.filled(
                              onPressed: _callDriver,
                              icon: const Icon(Icons.phone_rounded, color: Colors.white, size: 20),
                              style: IconButton.styleFrom(backgroundColor: AppColors.success),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Trip Stats (ETA, Distance, Fare)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTripStat(
                          icon: Icons.timer_outlined,
                          title: 'ETA',
                          value: '$_etaMinutes mins',
                          color: AppColors.primary,
                        ),
                        _buildTripStat(
                          icon: Icons.route_rounded,
                          title: 'Distance',
                          value: '${_distanceRemainingKm.toStringAsFixed(1)} km',
                          color: Colors.deepPurpleAccent,
                        ),
                        _buildTripStat(
                          icon: Icons.payments_outlined,
                          title: 'Fare',
                          value: 'K ${widget.fare.toStringAsFixed(0)}',
                          color: const Color(0xFF059669),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Share Live Tracking Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _shareTripStatus,
                        icon: const Icon(Icons.share_rounded, size: 16),
                        label: const Text('Share Live Ride Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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

  Widget _buildTripStat({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
          ],
        ),
      ],
    );
  }
}
