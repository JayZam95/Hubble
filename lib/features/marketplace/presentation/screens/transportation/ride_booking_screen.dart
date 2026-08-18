import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import 'live_ride_tracking_screen.dart';

class RideBookingScreen extends ConsumerStatefulWidget {
  final String vehicleType;
  const RideBookingScreen({super.key, required this.vehicleType});

  @override
  ConsumerState<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends ConsumerState<RideBookingScreen> {
  final _pickupController = TextEditingController(text: 'Lusaka CBD (Cairo Road)');
  final _dropoffController = TextEditingController(text: 'East Park Mall');
  bool _isRequesting = false;

  void _requestRide() async {
    if (_pickupController.text.trim().isEmpty || _dropoffController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both pickup and drop-off locations')),
      );
      return;
    }

    setState(() => _isRequesting = true);

    final isBike = widget.vehicleType == 'motorbike' || widget.vehicleType == 'bike';
    final safetyPin = '${1000 + math.Random().nextInt(9000)}';
    final fare = isBike ? 35.0 : 75.0;
    String rideId = 'ride_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final currentUser = ref.read(authStateProvider).user;
      final docRef = await FirebaseFirestore.instance.collection('ride_requests').add({
        'type': isBike ? 'boda_ride' : 'cab_ride',
        'userId': currentUser?.uid ?? 'guest_user',
        'userName': currentUser?.displayName ?? 'Valued Client',
        'driverId': isBike ? 'boda_1' : 'cab_1',
        'driverName': isBike ? 'Moses Sakala' : 'Chileshe Mwansa',
        'driverPhone': isBike ? '+260 977 293122' : '+260 977 492011',
        'driverPhotoUrl': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=300&q=80',
        'vehicleModel': isBike ? 'TVS HLX 150 (Red)' : 'Toyota Vitz (Silver)',
        'licensePlate': isBike ? 'BAR 2931' : 'BAL 4920',
        'driverRating': 4.9,
        'totalRides': 350,
        'pickupName': _pickupController.text.trim(),
        'pickupLat': -15.4167,
        'pickupLng': 28.2833,
        'dropoffName': _dropoffController.text.trim(),
        'dropoffLat': -15.3905,
        'dropoffLng': 28.3225,
        'distanceKm': 4.5,
        'totalFare': fare,
        'safetyPin': safetyPin,
        'status': 'DRIVER_DISPATCHED',
        'createdAt': FieldValue.serverTimestamp(),
      });
      rideId = docRef.id;
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() => _isRequesting = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LiveRideTrackingScreen(
            rideId: rideId,
            rideType: isBike ? 'boda' : 'cab',
            driverId: isBike ? 'boda_1' : 'cab_1',
            driverName: isBike ? 'Moses Sakala' : 'Chileshe Mwansa',
            driverPhone: isBike ? '+260 977 293122' : '+260 977 492011',
            driverPhotoUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=300&q=80',
            driverRating: 4.9,
            totalRides: 350,
            vehicleModel: isBike ? 'TVS HLX 150 (Red)' : 'Toyota Vitz (Silver)',
            licensePlate: isBike ? 'BAR 2931' : 'BAL 4920',
            pickupName: _pickupController.text.trim(),
            pickupLatLng: const LatLng(-15.4167, 28.2833),
            dropoffName: _dropoffController.text.trim(),
            dropoffLatLng: const LatLng(-15.3905, 28.3225),
            fare: fare,
            distanceKm: 4.5,
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
    final isBike = widget.vehicleType == 'motorbike';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(isBike ? 'Request Biker' : 'Request Ride'),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              isBike ? Icons.two_wheeler_rounded : Icons.local_taxi_rounded,
              size: 80,
              color: isBike ? Colors.orangeAccent : Colors.blueAccent,
            ),
            const SizedBox(height: 24),
            Text(
              'Where are you right now?',
              style: AppTextStyles.h3.copyWith(
                color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pickupController,
              decoration: InputDecoration(
                hintText: 'Enter pickup location',
                prefixIcon: const Icon(Icons.my_location_rounded, color: Colors.green),
                filled: true,
                fillColor: isDark ? Colors.white12 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Where are you going?',
              style: AppTextStyles.h3.copyWith(
                color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _dropoffController,
              decoration: InputDecoration(
                hintText: 'Enter drop-off location',
                prefixIcon: const Icon(Icons.location_on_rounded, color: Colors.red),
                filled: true,
                fillColor: isDark ? Colors.white12 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isRequesting ? null : _requestRide,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isRequesting 
                ? const SizedBox(
                    height: 20, 
                    width: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : const Text(
                    'Request Ride',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
