import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/booking_model.dart';

class LiveTrackingScreen extends StatefulWidget {
  final BookingModel booking;

  const LiveTrackingScreen({super.key, required this.booking});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final _mapController = MapController();
  
  // Fake client location (Lusaka center)
  final LatLng _clientLocation = const LatLng(-15.4167, 28.2833);
  
  // Fake provider starting location
  late LatLng _providerLocation;
  
  Timer? _trackingTimer;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    // Start provider a bit far away
    _providerLocation = LatLng(_clientLocation.latitude - 0.015, _clientLocation.longitude + 0.02);
    
    // Simulate provider moving towards client
    _trackingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      setState(() {
        _progress += 0.05;
        if (_progress > 1.0) _progress = 1.0;
        
        // Linear interpolation towards client
        final newLat = _providerLocation.latitude + (_clientLocation.latitude - _providerLocation.latitude) * 0.1;
        final newLng = _providerLocation.longitude + (_clientLocation.longitude - _providerLocation.longitude) * 0.1;
        
        _providerLocation = LatLng(newLat, newLng);
      });
    });
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        backgroundColor: isDark ? AppColors.bgDarkCard : Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _clientLocation,
              initialZoom: 13.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.hubble',
              ),
              MarkerLayer(
                markers: [
                  // Client Destination Marker
                  Marker(
                    point: _clientLocation,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.home_filled, color: AppColors.error, size: 40),
                  ),
                  // Provider Moving Marker
                  Marker(
                    point: _providerLocation,
                    width: 60,
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          bottom: -10,
                          child: const Icon(Icons.location_on, color: AppColors.primary, size: 30),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 3),
                            color: AppColors.bgDarkCard,
                          ),
                          child: const CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.bgDarkCard,
                            child: Icon(Icons.person, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Bottom ETA Panel
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgDarkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.directions_car, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _progress >= 1.0 ? 'Provider Arrived' : 'Provider is on the way',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _progress >= 1.0
                                  ? 'Provider has reached your location'
                                  : 'Estimated arrival: ${15 - (_progress * 15).toInt()} mins',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    borderRadius: BorderRadius.circular(10),
                    minHeight: 8,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
