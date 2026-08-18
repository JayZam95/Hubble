import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../bookings/presentation/screens/booking_creation_screen.dart';
import '../../../marketplace/domain/models/listing_model.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../../marketplace/presentation/screens/listing_detail_screen.dart';
import '../providers/review_provider.dart';
import '../../../../core/presentation/widgets/hubble_image.dart';

class ServicePortfolioScreen extends ConsumerStatefulWidget {
  final UserModel providerUser;

  const ServicePortfolioScreen({super.key, required this.providerUser});

  @override
  ConsumerState<ServicePortfolioScreen> createState() => _ServicePortfolioScreenState();
}

class _ServicePortfolioScreenState extends ConsumerState<ServicePortfolioScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Widget _buildContactRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassContainer({required Widget child, EdgeInsetsGeometry? padding, bool isDark = true}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
          fontSize: 14,
        ),
      ),
    );
  }

  void _initiateReferenceCheck(String clientId, String clientName) async {
    final currentUser = ref.read(authStateProvider).user;
    if (currentUser == null) return;
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );

      final chatRepo = ref.read(chatRepositoryProvider);
      final chatId = await chatRepo.createChatRoom(
        myUid: currentUser.uid,
        myName: currentUser.displayName,
        otherUid: clientId,
        otherName: clientName,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              otherUserId: clientId,
              otherUserName: clientName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    }
  }

  Widget _buildServiceListings(AsyncValue<List<ListingModel>> listingsAsync, bool isDark) {
    return listingsAsync.when(
      data: (listings) {
        if (listings.isEmpty) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Services Offered', isDark),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: listings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final listing = listings[index];
                final hasImage = listing.images.isNotEmpty && listing.images.first.isNotEmpty;
                final billingLabel = listing.billingType == BillingType.hourly ? '/hr' : '';
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ListingDetailScreen(listing: listing),
                      ),
                    );
                  },
                  child: _buildGlassContainer(
                    isDark: isDark,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        if (hasImage)
                          HubbleImage(
                            imagePath: listing.images.first,
                            width: 80,
                            height: 80,
                            borderRadius: BorderRadius.circular(12),
                          )
                        else
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white12 : Colors.black12,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.handyman, color: isDark ? Colors.white54 : Colors.black54),
                          ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listing.title,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                listing.isVariablePrice 
                                  ? 'Request Quote'
                                  : 'K ${listing.price.toStringAsFixed(0)}$billingLabel',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: isDark ? Colors.white54 : Colors.black54, size: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.providerUser.providerProfile;
    final hasImage = widget.providerUser.personalInfo.profileImageURL.isNotEmpty;
    final reviewsAsync = ref.watch(reviewProvider(widget.providerUser.uid));
    final listingsAsync = ref.watch(providerListingsProvider(widget.providerUser.uid));
    final currentUser = ref.watch(authStateProvider).user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B101E) : const Color(0xFFF8FAFC), // Deep luxury dark background
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            right: -150,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),

          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 350.0,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Header Profile Info
                      SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            Hero(
                              tag: 'portfolio_pic_${widget.providerUser.uid}',
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary, width: 3),
                                ),
                                child: hasImage
                                    ? HubbleImage(
                                        imagePath: widget.providerUser.personalInfo.profileImageURL,
                                        width: 120,
                                        height: 120,
                                        borderRadius: BorderRadius.circular(60),
                                      )
                                    : Center(
                                        child: Text(
                                          widget.providerUser.displayName.isNotEmpty ? widget.providerUser.displayName[0].toUpperCase() : 'P',
                                          style: const TextStyle(fontSize: 40, color: AppColors.primary, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              widget.providerUser.displayName,
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black, letterSpacing: 1.0),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              profile.professionTitle,
                              style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 2.0),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 20),
                                const SizedBox(width: 4),
                                Text(profile.ratingAsProvider.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 16),
                                Icon(Icons.work, color: isDark ? Colors.white70 : Colors.black54, size: 20),
                                const SizedBox(width: 4),
                                Text('${profile.totalJobsCompleted} Jobs', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 16)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // About Me
                      _buildSectionTitle('Executive Summary', isDark),
                      _buildGlassContainer(
                        isDark: isDark,
                        child: Text(
                          profile.bio.isNotEmpty ? profile.bio : 'Professional details coming soon.',
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15, height: 1.6),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Skills & Experience
                      if (profile.skills.isNotEmpty) ...[
                        _buildSectionTitle('Core Competencies', isDark),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: profile.skills.map((skill) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                skill,
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                      ],

                      if (profile.experience.isNotEmpty) ...[
                        _buildSectionTitle('Professional Experience', isDark),
                        _buildGlassContainer(
                          isDark: isDark,
                          padding: EdgeInsets.zero,
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(20),
                            itemCount: profile.experience.length,
                            separatorBuilder: (context, index) => Divider(color: isDark ? Colors.white24 : Colors.black12, height: 32),
                            itemBuilder: (context, index) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.business_center, color: AppColors.secondary, size: 24),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      profile.experience[index],
                                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15, height: 1.5),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Contact Section
                      if (widget.providerUser.personalInfo.phoneNumber.isNotEmpty || widget.providerUser.personalInfo.email.isNotEmpty) ...[
                        _buildSectionTitle('Contact Details', isDark),
                        _buildGlassContainer(
                          isDark: isDark,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              if (widget.providerUser.personalInfo.phoneNumber.isNotEmpty)
                                _buildContactRow(Icons.phone, widget.providerUser.personalInfo.phoneNumber, isDark),
                              if (widget.providerUser.personalInfo.phoneNumber.isNotEmpty && widget.providerUser.personalInfo.email.isNotEmpty)
                                Divider(color: isDark ? Colors.white24 : Colors.black12, height: 32),
                              if (widget.providerUser.personalInfo.email.isNotEmpty)
                                _buildContactRow(Icons.email, widget.providerUser.personalInfo.email, isDark),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Portfolio Images
                      if (profile.portfolioImages.isNotEmpty) ...[
                        _buildSectionTitle('Featured Work', isDark),
                        SizedBox(
                          height: 200,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: profile.portfolioImages.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FullScreenImageViewer(
                                        imageUrls: profile.portfolioImages,
                                        initialIndex: index,
                                      ),
                                    ),
                                  );
                                },
                                child: HubbleImage(
                                  imagePath: profile.portfolioImages[index],
                                  width: 140, // derived from AspectRatio
                                  height: 116,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                      
                      // Service Listings
                      _buildServiceListings(listingsAsync, isDark),

                      // Calendar Widget
                      _buildSectionTitle('Schedule Availability', isDark),
                      _buildGlassContainer(
                        isDark: isDark,
                        padding: const EdgeInsets.all(12),
                        child: TableCalendar(
                          firstDay: DateTime.now(),
                          lastDay: DateTime.now().add(const Duration(days: 90)),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          calendarStyle: CalendarStyle(
                            defaultTextStyle: TextStyle(color: isDark ? Colors.white : Colors.black),
                            weekendTextStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                            outsideTextStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                            selectedDecoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: isDark ? Colors.white24 : Colors.black12,
                              shape: BoxShape.circle,
                            ),
                          ),
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                            leftChevronIcon: Icon(Icons.chevron_left, color: isDark ? Colors.white : Colors.black),
                            rightChevronIcon: Icon(Icons.chevron_right, color: isDark ? Colors.white : Colors.black),
                          ),
                          daysOfWeekStyle: DaysOfWeekStyle(
                            weekdayStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                            weekendStyle: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _initiateReferenceCheck(widget.providerUser.uid, widget.providerUser.displayName),
                              icon: Icon(Icons.message, color: isDark ? Colors.white : AppColors.primary),
                              label: Text('Message', style: TextStyle(color: isDark ? Colors.white : AppColors.primary, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: isDark ? Colors.white54 : Colors.black54),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                if (currentUser == null) return;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => BookingCreationScreen(providerUser: widget.providerUser),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text(
                                _selectedDay != null 
                                  ? 'Book for ${DateFormat('MMM dd').format(_selectedDay!)}'
                                  : 'Book Consultation',
                                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Reference Check / Reviews
                      _buildSectionTitle('Verified References', isDark),
                      reviewsAsync.when(
                        data: (reviews) {
                          if (reviews.isEmpty) {
                            return _buildGlassContainer(
                              isDark: isDark,
                              child: Center(
                                child: Text('No references available yet.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                              ),
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: reviews.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final review = reviews[index];
                              final isHighRated = review.rating >= 4.0;

                              return _buildGlassContainer(
                                isDark: isDark,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: isDark ? Colors.white12 : Colors.black12,
                                          child: Text(
                                            review.clientName.isNotEmpty ? review.clientName[0].toUpperCase() : 'C',
                                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(review.clientName, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                                              Text(
                                                DateFormat('MMM dd, yyyy').format(review.createdAt),
                                                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ),
                                        RatingBarIndicator(
                                          rating: review.rating,
                                          itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                                          itemCount: 5,
                                          itemSize: 16.0,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      review.text,
                                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14, height: 1.5),
                                    ),
                                    
                                    // Reference Check Button
                                    if (isHighRated && review.allowsReferences && review.clientId != currentUser?.uid) ...[
                                      const SizedBox(height: 16),
                                      OutlinedButton.icon(
                                        onPressed: () => _initiateReferenceCheck(review.clientId, review.clientName),
                                        icon: const Icon(Icons.verified_user, color: AppColors.success, size: 18),
                                        label: const Text('Ask About Experience', style: TextStyle(color: AppColors.success)),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: AppColors.success),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        error: (err, stack) => Text('Error loading reviews: $err', style: const TextStyle(color: Colors.red)),
                      ),
                      
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        elevation: 0,
      ),
      body: PageView.builder(
        itemCount: imageUrls.length,
        controller: PageController(initialPage: initialIndex),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4,
            child: HubbleImage(
              imagePath: imageUrls[index],
              fit: BoxFit.contain,
            ),
          );
        },
      ),
    );
  }
}
