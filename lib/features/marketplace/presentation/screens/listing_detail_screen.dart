import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/models/listing_model.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../profile/presentation/screens/public_profile_screen.dart';
import '../../../bookings/presentation/screens/booking_creation_screen.dart';
import '../providers/cart_provider.dart';
import '../../../../core/presentation/widgets/hubble_image.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  final ListingModel listing;

  const ListingDetailScreen({super.key, required this.listing});

  @override
  ConsumerState<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  final PageController _pageController = PageController();
  bool _isLoadingProvider = false;

  void _navigateToProviderProfile() async {
    setState(() {
      _isLoadingProvider = true;
    });
    try {
      final firestore = FirebaseFirestore.instance;
      final providerDoc = await firestore.collection('users').doc(widget.listing.providerId).get();
      if (providerDoc.exists && mounted) {
        final providerUser = UserModel.fromMap(providerDoc.data()!..putIfAbsent('userId', () => widget.listing.providerId));
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PublicProfileScreen(providerUser: providerUser),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load provider profile.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProvider = false;
        });
      }
    }
  }

  void _checkoutOrBook() async {
    setState(() {
      _isLoadingProvider = true;
    });
    try {
      final firestore = FirebaseFirestore.instance;
      final providerDoc = await firestore.collection('users').doc(widget.listing.providerId).get();
      if (providerDoc.exists && mounted) {
        final providerUser = UserModel.fromMap(providerDoc.data()!..putIfAbsent('userId', () => widget.listing.providerId));
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingCreationScreen(
              providerUser: providerUser,
              prefilledListing: widget.listing,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initialize booking.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProvider = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasImages = widget.listing.images.isNotEmpty && widget.listing.images.first.trim().isNotEmpty;
    final isService = widget.listing.listingType == ListingType.service;
    
    final billingLabel = widget.listing.billingType == BillingType.hourly
        ? '/hr'
        : widget.listing.billingType == BillingType.monthly
            ? '/mo'
            : '';

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Image Header
              SliverAppBar(
                expandedHeight: 350.0,
                pinned: true,
                backgroundColor: isDark ? AppColors.bgDarkCard : Colors.white,
                iconTheme: IconThemeData(
                  color: isDark ? Colors.white : Colors.black,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasImages)
                        PageView.builder(
                          controller: _pageController,
                          itemCount: widget.listing.images.length,
                          itemBuilder: (context, index) {
                            return HubbleImage(
                              imagePath: widget.listing.images[index],
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      else
                        Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: Icon(
                            isService ? Icons.handyman : Icons.shopping_bag,
                            size: 80,
                            color: isDark ? Colors.white30 : Colors.black26,
                          ),
                        ),
                      
                      // Gradient to make app bar icons visible
                      Positioned(
                        top: 0, left: 0, right: 0,
                        height: 100,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black54, Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                      
                      if (hasImages && widget.listing.images.length > 1)
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: SmoothPageIndicator(
                              controller: _pageController,
                              count: widget.listing.images.length,
                              effect: const ExpandingDotsEffect(
                                dotHeight: 8,
                                dotWidth: 8,
                                activeDotColor: AppColors.primary,
                                dotColor: Colors.white54,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.listing.category,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Title & Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.listing.title,
                              style: AppTextStyles.heading2.copyWith(
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            widget.listing.isVariablePrice 
                                ? 'Request Quote' 
                                : 'K ${widget.listing.price.toStringAsFixed(0)}$billingLabel',
                            style: AppTextStyles.heading2.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: widget.listing.isVariablePrice ? 18 : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Provider Banner
                      InkWell(
                        onTap: _navigateToProviderProfile,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.bgDarkCard : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.white10 : Colors.black12,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (widget.listing.providerImage.trim().isNotEmpty)
                                HubbleImage(
                                  imagePath: widget.listing.providerImage,
                                  width: 48,
                                  height: 48,
                                  borderRadius: BorderRadius.circular(24),
                                )
                              else
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.person, color: isDark ? Colors.white54 : Colors.black54),
                                ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Provided by',
                                      style: TextStyle(
                                        color: isDark ? Colors.white54 : Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      widget.listing.providerName,
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: isDark ? Colors.white54 : Colors.black54),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Description
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.listing.description,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      
                      if (isService) ...[
                        const SizedBox(height: 32),
                        Text(
                          'Service Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (widget.listing.estimatedDuration != null)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.timer_outlined, color: AppColors.primary),
                            title: const Text('Estimated Duration'),
                            subtitle: Text(widget.listing.estimatedDuration!),
                          ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                          title: const Text('Location'),
                          subtitle: Text(widget.listing.travelsToClient 
                              ? 'Travels to you (Up to ${widget.listing.travelRadius ?? 0}km)' 
                              : 'Service performed at provider location'),
                        ),
                      ],
                      
                      const SizedBox(height: 120), // Bottom padding for CTA
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom CTA
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgDark : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoadingProvider ? null : () {
                      if (isService) {
                        _checkoutOrBook();
                      } else {
                        ref.read(cartProvider.notifier).addItem(widget.listing);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to Cart')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoadingProvider
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            isService 
                                ? (widget.listing.isVariablePrice ? 'Request Quote' : 'Book Now') 
                                : 'Add to Cart',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
