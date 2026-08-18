import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/search_provider.dart';
import '../../../profile/presentation/screens/public_profile_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'explore_screen.dart' show FilterBottomSheet;

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});
  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  final _searchController =
      TextEditingController(); /* Center map on Lusaka, Zambia by default */
  final _defaultCenter = const LatLng(-15.4167, 28.2833);
  LatLng? _currentPosition;
  LatLng? _selectedProviderPosition;
  bool _isLoadingLocation = false;
  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    if ((!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'))) return;
    final currentUser = ref.read(authStateProvider).user;
    if (currentUser != null && !currentUser.providerProfile.isLocationShared) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Enable "Share My Location on Map" in Settings to use your location.',
            ),
          ),
        );
      }
      return;
    }
    setState(() => _isLoadingLocation = true);
    bool serviceEnabled;
    LocationPermission permission; /* Test if location services are enabled. */
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location services are disabled. Centering on Lusaka.',
            ),
          ),
        );
      }
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() => _isLoadingLocation = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permissions denied. Centering on Lusaka.',
              ),
            ),
          );
        }
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions permanently denied.'),
          ),
        );
      }
      return;
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        _mapController.move(_currentPosition!, 13.0);
      }
    } catch (e) {
      debugPrint("Failed to retrieve coordinates: $e");
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Providers Near You'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => FilterBottomSheet(isDark: isDark),
              );
            },
          ),
          if (_isLoadingLocation)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final providers = searchResultsAsync.value ?? [];
          final markers = <Marker>[];
          final currentUser = ref.watch(authStateProvider).user;
          final isLocationShared =
              currentUser?.providerProfile.isLocationShared ??
              false; /* 1. Plot current user pulse marker if resolved and shared*/
          if (_currentPosition != null && isLocationShared) {
            markers.add(
              Marker(
                point: _currentPosition!,
                width: 50,
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } /* 2. Plot active providers around current center */
          final referenceCenter = _currentPosition ?? _defaultCenter;
          for (int i = 0; i < providers.length; i++) {
            final user =
                providers[i]; /* Render providers with a slight offset from the reference center*/
            final offsetLat = (i % 3 == 0) ? 0.008 * i : -0.005 * i;
            final offsetLng = (i % 2 == 0) ? 0.012 * i : -0.009 * i;
            final position = LatLng(
              referenceCenter.latitude + offsetLat,
              referenceCenter.longitude + offsetLng,
            );
            markers.add(
              Marker(
                point: position,
                width: 60,
                height: 60,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedProviderPosition = position;
                    });
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) => _buildProviderCard(
                        context,
                        user,
                        isDark,
                        position: position,
                      ),
                    ).whenComplete(() {
                      if (mounted) {
                        setState(() {
                          _selectedProviderPosition = null;
                        });
                      }
                    });
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      /* The map pin tail */ Positioned(
                        bottom: -10,
                        child: Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 30,
                        ),
                      ),
                      /* The circular profile picture */ Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.bgDarkCard,
                          backgroundImage:
                              user.personalInfo.profileImageURL.trim().isNotEmpty
                              ? NetworkImage(user.personalInfo.profileImageURL.trim())
                              : null,
                          child: user.personalInfo.profileImageURL.trim().isEmpty
                              ? Text(
                                  user.displayName.isNotEmpty
                                      ? user.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          final mapWidget = Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: referenceCenter,
                  initialZoom: 12.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.hubble',
                  ),
                  if (_currentPosition != null &&
                      _selectedProviderPosition != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [
                            _currentPosition!,
                            _selectedProviderPosition!,
                          ],
                          strokeWidth: 4.0,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  MarkerLayer(markers: markers),
                ],
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.bgDarkCard : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      ref.read(searchQueryProvider.notifier).updateQuery(val);
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search providers...',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
          return SlidingUpPanel(
            minHeight: 80,
            maxHeight: MediaQuery.of(context).size.height * 0.65,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            color: isDark ? AppColors.bgDarkCard : Colors.white,
            boxShadow: [
              BoxShadow(
                blurRadius: 20.0,
                color: Colors.black.withValues(alpha: 0.1),
              ),
            ],
            panelBuilder: (sc) {
              return Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${providers.length} Providers Nearby',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      controller: sc,
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: providers.length,
                      itemBuilder: (context, index) {
                        final offsetLat = (index % 3 == 0)
                            ? 0.008 * index
                            : -0.005 * index;
                        final offsetLng = (index % 2 == 0)
                            ? 0.012 * index
                            : -0.009 * index;
                        final position = LatLng(
                          referenceCenter.latitude + offsetLat,
                          referenceCenter.longitude + offsetLng,
                        );
                        return _buildProviderCard(
                          context,
                          providers[index],
                          isDark,
                          isModal: false,
                          position: position,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            body: mapWidget,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _initLocation,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  Widget _buildProviderCard(
    BuildContext context,
    dynamic user,
    bool isDark, {
    bool isModal = true,
    LatLng? position,
  }) {
    final profile = user.providerProfile;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                backgroundImage: user.personalInfo.profileImageURL.trim().isNotEmpty
                    ? NetworkImage(user.personalInfo.profileImageURL.trim())
                    : null,
                child: user.personalInfo.profileImageURL.trim().isEmpty
                    ? Text(
                        user.displayName.isNotEmpty
                            ? user.displayName[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                          fontSize: 24,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.professionTitle,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          profile.ratingAsProvider.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.attach_money,
                          color: Colors.green,
                          size: 16,
                        ),
                        Text(
                          '${profile.hourlyRate}/hr',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (isModal) {
                      Navigator.pop(context);
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PublicProfileScreen(providerUser: user),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'View Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (position != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final url = Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=${position.latitude},${position.longitude}',
                      );
                      await launchUrl(url);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Start Navigation',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
