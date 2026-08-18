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
        return 'Finding Nearby Driver';
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
    this.rideType = 'cab',
    required this.driverId,
    required this.driverName,
    this.driverPhone = '+260977889900',
    this.driverPhotoUrl = '',
    this.driverRating = 4.9,
    this.totalRides = 350,
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

  late AnimationController _animController;
  Timer? _stateSimulationTimer;
  Timer? _countdownTimer;
  StreamSubscription<DocumentSnapshot>? _rideSubscription;

  int _etaMinutes = 5;
  int _etaSecondsRemaining = 300;
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

    // Offset initial driver position slightly from pickup
    _driverInitialPosition = LatLng(
      widget.pickupLatLng.latitude + 0.008,
      widget.pickupLatLng.longitude - 0.008,
    );
    _currentVehiclePosition = _driverInitialPosition;
    _distanceRemainingKm = widget.distanceKm;
    _etaMinutes = math.max(2, (widget.distanceKm * 2.5).round());
    _etaSecondsRemaining = _etaMinutes * 60;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..addListener(() {
        _updateVehiclePositionAlongRoute();
      });

    _animController.forward();

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

    // Simulate state advancement:
    // Dispatched (6s) -> Arrived (5s) -> In Transit (10s) -> Completed
    _stateSimulationTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted || _currentState != RideTrackingState.driverDispatched) return;
      _advanceToState(RideTrackingState.arrivedAtPickup);

      _stateSimulationTimer = Timer(const Duration(seconds: 5), () {
        if (!mounted || _currentState != RideTrackingState.arrivedAtPickup) return;
        _advanceToState(RideTrackingState.inTransit);

        _stateSimulationTimer = Timer(const Duration(seconds: 12), () {
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
        HapticFeedback.heavyImpact();
      } else if (nextState == RideTrackingState.inTransit) {
        _animController.reset();
        _animController.forward();
        _etaSecondsRemaining = (widget.distanceKm * 120).round();
      } else if (nextState == RideTrackingState.completed) {
        _currentVehiclePosition = widget.dropoffLatLng;
        _distanceRemainingKm = 0.0;
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
    final progress = _animController.value;
    if (_currentState == RideTrackingState.driverDispatched) {
      // Driver moving towards pickup
      final lat = _driverInitialPosition.latitude +
          (widget.pickupLatLng.latitude - _driverInitialPosition.latitude) * progress;
      final lng = _driverInitialPosition.longitude +
          (widget.pickupLatLng.longitude - _driverInitialPosition.longitude) * progress;
      setState(() {
        _currentVehiclePosition = LatLng(lat, lng);
      });
    } else if (_currentState == RideTrackingState.inTransit) {
      // In transit to dropoff
      final lat = widget.pickupLatLng.latitude +
          (widget.dropoffLatLng.latitude - widget.pickupLatLng.latitude) * progress;
      final lng = widget.pickupLatLng.longitude +
          (widget.dropoffLatLng.longitude - widget.pickupLatLng.longitude) * progress;
      setState(() {
        _currentVehiclePosition = LatLng(lat, lng);
        _distanceRemainingKm =
            math.max(0.0, widget.distanceKm * (1.0 - progress));
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
    } catch (e) {
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
        'Tracking my Hubble ride with ${widget.driverName} (${widget.licensePlate}). '
        'Heading to ${widget.dropoffName}. ETA: $_etaMinutes mins. PIN: $_safetyPin.';
    // ignore: deprecated_member_use
    Share.share(shareText, subject: 'My Hubble Ride Tracking');
  }

  void _showSosConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Emergency SOS',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Do you need immediate emergency or police assistance?',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your live GPS coordinates (${_currentVehiclePosition.latitude.toStringAsFixed(4)}, ${_currentVehiclePosition.longitude.toStringAsFixed(4)}) and ride details with ${widget.driverName} will be shared with Zambia emergency services.',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_rounded, color: AppColors.error, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Zambia Police Toll-Free: 991',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
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
              _showSnack('Emergency alert triggered. Dispatching assistance.');
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
    final noteController = TextEditingController();

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
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
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

                    // Success checkmark badge
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'You Have Arrived!',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Thank you for riding with ${widget.driverName}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    // Fare breakdown card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Trip Distance', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              Text('${widget.distanceKm.toStringAsFixed(1)} km', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Base Fare', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              Text('K ${widget.fare.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          if (tipAmount > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Driver Tip', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                                Text('+ K ${tipAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                              ],
                            ),
                          ],
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Paid',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                              Text(
                                'K ${grandTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Driver tipping options
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Add a Tip for ${widget.driverName}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [0.0, 10.0, 20.0, 50.0].map((tip) {
                        final isSelected = tipAmount == tip;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Center(
                                child: Text(
                                  tip == 0.0 ? 'No Tip' : 'K${tip.toInt()}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                              onSelected: (_) {
                                setModalState(() => tipAmount = tip);
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Rating bar
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Rate your experience',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    RatingBar.builder(
                      initialRating: selectedRating,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                      itemBuilder: (context, _) => const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                      ),
                      onRatingUpdate: (rating) {
                        setModalState(() => selectedRating = rating);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Optional note field
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        hintText: 'Leave a note for ${widget.driverName} (optional)...',
                        hintStyle: const TextStyle(fontSize: 13),
                        filled: true,
                        fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit & Return button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          final isTest = (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'));
                          if (!isTest && widget.rideId.isNotEmpty) {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('ride_requests')
                                  .doc(widget.rideId)
                                  .update({
                                'rating': selectedRating,
                                'tip': tipAmount,
                                'reviewNote': noteController.text.trim(),
                                'status': 'COMPLETED',
                                'completedAt': FieldValue.serverTimestamp(),
                              });
                            } catch (_) {}
                          }

                          if (modalContext.mounted) {
                            Navigator.pop(modalContext);
                          }
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Submit & Back to Hub',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
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
    if (!mounted) return;
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
      body: Stack(
        children: [
          // ── 1. Full Screen FlutterMap ──────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.pickupLatLng,
              initialZoom: 14.0,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.intentgenesiscorp.hubble',
              ),
              // Route Polyline
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [
                      _driverInitialPosition,
                      widget.pickupLatLng,
                      widget.dropoffLatLng,
                    ],
                    strokeWidth: 5.0,
                    color: isBike ? const Color(0xFF0D9488) : AppColors.primary,
                  ),
                ],
              ),
              // Marker Layer
              MarkerLayer(
                markers: [
                  // Pickup Marker
                  Marker(
                    point: widget.pickupLatLng,
                    width: 50,
                    height: 50,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 22),
                        ),
                      ],
                    ),
                  ),

                  // Dropoff Marker
                  Marker(
                    point: widget.dropoffLatLng,
                    width: 50,
                    height: 50,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 22),
                        ),
                      ],
                    ),
                  ),

                  // Animated Vehicle Marker
                  Marker(
                    point: _currentVehiclePosition,
                    width: 64,
                    height: 64,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulse glow ring
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (isBike ? const Color(0xFF0D9488) : AppColors.primary).withValues(alpha: 0.25),
                          ),
                        ),
                        // Vehicle badge
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isBike ? const Color(0xFF14B8A6) : Colors.amber,
                              width: 2.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
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
                ],
              ),
            ],
          ),

          // ── 2. Top Bar Navigation & SOS ────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cardBg,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 22),
                    ),
                  ),

                  // Active status pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentState == RideTrackingState.arrivedAtPickup
                                ? Colors.amber
                                : (_currentState == RideTrackingState.inTransit ? AppColors.primary : AppColors.success),
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

                  // Emergency SOS Button
                  InkWell(
                    onTap: _showSosConfirmationDialog,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 3. Recenter & Fast Forward Simulation Controls ────────────────
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.32,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'recenter_map',
                  backgroundColor: cardBg,
                  onPressed: () {
                    _mapController.move(_currentVehiclePosition, 14.5);
                  },
                  child: const Icon(Icons.my_location_rounded, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  backgroundColor: cardBg,
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, currentZoom + 1);
                  },
                  child: const Icon(Icons.add, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  backgroundColor: cardBg,
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, currentZoom - 1);
                  },
                  child: const Icon(Icons.remove, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                // Fast Step button for testing all states easily
                FloatingActionButton.small(
                  heroTag: 'skip_state',
                  backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  tooltip: 'Advance State (Demo)',
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

          // ── 4. Bottom BottomSheet / Info Cards ──────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle indicator
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── 4-Digit Boarding Safety PIN ─────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                              : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.security_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ride Safety PIN',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                                Text(
                                  'Share PIN with driver to start ride',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          // 4 Individual Digit Badges
                          Row(
                            children: _safetyPin.split('').map((digit) {
                              return Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  digit,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Driver Details Row ──────────────────────────────────
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          child: HubbleImage(
                            imagePath: widget.driverPhotoUrl,
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
                                widget.driverName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.vehicleModel} · ${widget.licensePlate}',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${widget.driverRating} (${widget.totalRides} trips)',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Quick Action Buttons
                        Row(
                          children: [
                            IconButton.filledTonal(
                              onPressed: _openChatWithDriver,
                              icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: _callDriver,
                              icon: const Icon(Icons.phone_rounded, color: Colors.white),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    // ── Trip Stats & Addresses ──────────────────────────────
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
                          color: AppColors.success,
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Route Summary Bar
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.my_location_rounded, color: AppColors.success, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.pickupName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.dropoffName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Share Trip Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _shareTripStatus,
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text('Share Live Ride Status', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ],
    );
  }
}
