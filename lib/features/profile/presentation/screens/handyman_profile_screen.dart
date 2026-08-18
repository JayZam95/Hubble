import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/presentation/widgets/hubble_image.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../bookings/presentation/screens/booking_creation_screen.dart';
import '../../../marketplace/domain/models/listing_model.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../../marketplace/presentation/screens/listing_detail_screen.dart';
import '../../../marketplace/presentation/providers/cart_provider.dart';
import '../../../marketplace/presentation/screens/cart_screen.dart';
import '../providers/review_provider.dart';
import '../../domain/models/review_model.dart';

class HandymanProfileScreen extends ConsumerStatefulWidget {
  final UserModel providerUser;

  const HandymanProfileScreen({super.key, required this.providerUser});

  @override
  ConsumerState<HandymanProfileScreen> createState() => _HandymanProfileScreenState();
}

class _HandymanProfileScreenState extends ConsumerState<HandymanProfileScreen> {
  final PageController _beforeAfterPageController = PageController();
  int _activeBeforeAfterIndex = 0;
  bool _isEmergencyServiceSelected = false;

  @override
  void dispose() {
    _beforeAfterPageController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No emergency contact number listed for this contractor.')),
      );
      return;
    }
    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open dialer: $e')),
        );
      }
    }
  }

  Future<void> _startChat() async {
    final currentUser = ref.read(authStateProvider).user;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to message this contractor.')),
      );
      return;
    }

    if (currentUser.uid == widget.providerUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot message yourself.')),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );

      final chatRepo = ref.read(chatRepositoryProvider);
      final chatId = await chatRepo.createChatRoom(
        myUid: currentUser.uid,
        myName: currentUser.displayName.isNotEmpty ? currentUser.displayName : 'Client',
        otherUid: widget.providerUser.uid,
        otherName: widget.providerUser.displayName.isNotEmpty ? widget.providerUser.displayName : 'Contractor',
      );

      if (mounted) {
        Navigator.pop(context);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              otherUserId: widget.providerUser.uid,
              otherUserName: widget.providerUser.displayName,
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

  void _requestQuoteOrCallout({ListingModel? prefilledListing, bool isEmergency = false}) {
    final currentUser = ref.read(authStateProvider).user;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to request a quote or callout.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookingCreationScreen(
          providerUser: widget.providerUser,
          prefilledListing: prefilledListing,
        ),
      ),
    );
  }

  void _addToCart(ListingModel listing) {
    ref.read(cartProvider.notifier).addItem(listing);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${listing.title} added to your cart'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool isDark = true,
    Color? borderColor,
  }) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.75) : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor ?? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06)),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFF59E0B), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.heading2.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textLightPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = widget.providerUser.providerProfile;
    final reviewsAsync = ref.watch(reviewProvider(widget.providerUser.uid));
    final listingsAsync = ref.watch(providerListingsProvider(widget.providerUser.uid));
    final hasImage = widget.providerUser.personalInfo.profileImageURL.isNotEmpty;

    final double hourlyRate = profile.hourlyRate > 0 ? profile.hourlyRate : 150.0;
    final String currency = profile.currency.isNotEmpty ? profile.currency : 'K';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Industrial amber ambient glow
          Positioned(
            top: -50,
            left: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
          Positioned(
            top: 400,
            right: -60,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Trade Hero Sliver App Bar
              _buildTradeHeroAppBar(isDark, hasImage),

              // Main Content Body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Emergency Dispatch Status Banner
                      _buildEmergencyBanner(isDark),
                      const SizedBox(height: 20),

                      // Quick Action Row (Request Quote, Emergency Call, Chat)
                      _buildQuickActionButtons(isDark),
                      const SizedBox(height: 24),

                      // Contractor Bio & 30-Day Guarantee Card
                      _buildGuaranteeAndBioCard(profile, isDark),
                      const SizedBox(height: 24),

                      // Trade Licenses & Verified Credentials
                      _buildLicensesSection(profile, isDark),
                      const SizedBox(height: 24),

                      // Before & After Project Gallery Carousel
                      _buildBeforeAfterCarousel(isDark),
                      const SizedBox(height: 24),

                      // Specialized Tool & Equipment Capabilities
                      _buildToolCapabilities(profile, isDark),
                      const SizedBox(height: 24),

                      // Standard & Emergency Pricing Guide
                      _buildPricingGuideSection(hourlyRate, currency, isDark),
                      const SizedBox(height: 24),

                      // Service Listings & Material Packages
                      _buildServiceListings(listingsAsync, currency, isDark),
                      const SizedBox(height: 24),

                      // Verified Client Workmanship Reviews
                      _buildReviewsSection(reviewsAsync, isDark),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Sticky Bottom CTA Bar
          _buildStickyBottomBar(hourlyRate, currency, isDark),
        ],
      ),
    );
  }

  Widget _buildTradeHeroAppBar(bool isDark, bool hasImage) {
    final profile = widget.providerUser.providerProfile;
    final rating = profile.ratingAsProvider > 0 ? profile.ratingAsProvider : 4.95;
    final completedJobs = profile.totalJobsCompleted > 0 ? profile.totalJobsCompleted : 142;

    return SliverAppBar(
      expandedHeight: 330,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF0B1120) : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.share_outlined, color: isDark ? Colors.white : Colors.black87),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contractor profile link copied to clipboard')),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0B1120)]
                      : [const Color(0xFFFFFBEB), const Color(0xFFF8FAFC)],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  Stack(
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFF59E0B), width: 3.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: hasImage
                              ? HubbleImage(
                                  imagePath: widget.providerUser.personalInfo.profileImageURL,
                                  width: 104,
                                  height: 104,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                  child: Center(
                                    child: Text(
                                      widget.providerUser.displayName.isNotEmpty
                                          ? widget.providerUser.displayName[0].toUpperCase()
                                          : 'H',
                                      style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.handyman, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.providerUser.displayName,
                        style: AppTextStyles.heading1.copyWith(
                          fontSize: 22,
                          color: isDark ? Colors.white : AppColors.textLightPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, color: AppColors.primary, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.professionTitle.isNotEmpty
                        ? profile.professionTitle
                        : 'Certified Master Trade Contractor & Electrician',
                    style: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMetricBadge(Icons.star_rounded, '$rating Rating', Colors.amber, isDark),
                      const SizedBox(width: 8),
                      _buildMetricBadge(Icons.construction_rounded, '$completedJobs+ Jobs Done', AppColors.primary, isDark),
                      const SizedBox(width: 8),
                      _buildMetricBadge(Icons.security_rounded, 'Insured & Bonded', const Color(0xFF3B82F6), isDark),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBadge(IconData icon, String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.textLightPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withValues(alpha: 0.2),
            const Color(0xFFF59E0B).withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AVAILABLE NOW FOR EMERGENCY CALLOUTS',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Average local dispatch response: < 30 minutes',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isEmergencyServiceSelected,
            activeTrackColor: const Color(0xFFF59E0B),
            onChanged: (val) {
              setState(() => _isEmergencyServiceSelected = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons(bool isDark) {
    final phone = widget.providerUser.personalInfo.phoneNumber;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            onPressed: () => _requestQuoteOrCallout(isEmergency: _isEmergencyServiceSelected),
            icon: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
            label: Text(
              _isEmergencyServiceSelected ? 'Emergency Dispatch' : 'Request Free Quote',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isEmergencyServiceSelected ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: _startChat,
            icon: Icon(Icons.chat_bubble_outline_rounded, color: isDark ? Colors.white : const Color(0xFFF59E0B), size: 18),
            label: Text('Chat', style: TextStyle(color: isDark ? Colors.white : const Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: isDark ? Colors.white30 : const Color(0xFFF59E0B).withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        if (phone.isNotEmpty) ...[
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
            ),
            child: IconButton(
              icon: const Icon(Icons.phone_in_talk, color: Color(0xFFEF4444)),
              onPressed: () => _makePhoneCall(phone),
              tooltip: 'Emergency Call',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGuaranteeAndBioCard(ProviderProfile profile, bool isDark) {
    final bio = profile.bio.isNotEmpty
        ? profile.bio
        : 'Over 12 years of professional trade contracting experience handling complex plumbing overhauls, commercial electrical wiring, structural leak diagnosis, and emergency repair jobs. Fast, tidy, and fully guaranteed.';

    return _buildGlassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Hubble 30-Day Workmanship Guarantee',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bio,
            style: TextStyle(
              color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black87,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.handyman_outlined, color: Color(0xFFF59E0B), size: 16),
              const SizedBox(width: 6),
              Text(
                'Commercial & Residential • Fully Insured',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLicensesSection(ProviderProfile profile, bool isDark) {
    final licenses = profile.experience.isNotEmpty
        ? profile.experience
        : [
            'National Construction Council (NCC) Certified Contractor',
            'Master Electrician Wireman License (#EW-2024-918)',
            'City & Guilds Certified Pipe & Drainage Specialist',
            'OSHA 30-Hour Construction Safety & Health Certified',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Trade Licenses & Certifications', Icons.badge_outlined, isDark),
        _buildGlassCard(
          isDark: isDark,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: licenses.length,
            separatorBuilder: (context, index) => Divider(
              color: isDark ? Colors.white12 : Colors.black12,
              height: 20,
            ),
            itemBuilder: (context, index) {
              return Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          licenses[index],
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Verified Trade Badge',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBeforeAfterCarousel(bool isDark) {
    final projects = [
      {
        'title': 'Master Bathroom PEX Re-Piping & Pressure Overhaul',
        'desc': 'Replaced corroded galvanized lines with manifold PEX system, restoring full 60 PSI water pressure.',
        'beforeImg': 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=600&q=80',
        'afterImg': 'https://images.unsplash.com/photo-1620626011761-996317b8d101?w=600&q=80',
      },
      {
        'title': 'Main Breaker Panel Upgrade & Surge Protection',
        'desc': 'Replaced dangerous 40-year-old fuse board with clean 200A breaker with whole-home surge suppressors.',
        'beforeImg': 'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=600&q=80',
        'afterImg': 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=600&q=80',
      },
      {
        'title': '5kVA Hybrid Solar Inverter & LiFePO4 Installation',
        'desc': 'Engineered complete off-grid power backup system with dedicated critical load distribution box.',
        'beforeImg': 'https://images.unsplash.com/photo-1509391365360-2e959784a276?w=600&q=80',
        'afterImg': 'https://images.unsplash.com/photo-1548337138-e87d889cc369?w=600&q=80',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Before & After Project Gallery', Icons.compare_arrows_rounded, isDark),
        SizedBox(
          height: 290,
          child: PageView.builder(
            controller: _beforeAfterPageController,
            itemCount: projects.length,
            onPageChanged: (idx) {
              setState(() => _activeBeforeAfterIndex = idx);
            },
            itemBuilder: (context, index) {
              final proj = projects[index];
              return Container(
                margin: const EdgeInsets.only(right: 4),
                child: _buildGlassCard(
                  isDark: isDark,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proj['title'] as String,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        proj['desc'] as String,
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 11.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: HubbleImage(
                                      imagePath: proj['beforeImg'] as String,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('BEFORE', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: HubbleImage(
                                      imagePath: proj['afterImg'] as String,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('AFTER', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: AnimatedSmoothIndicator(
            activeIndex: _activeBeforeAfterIndex,
            count: projects.length,
            effect: WormEffect(
              dotWidth: 8,
              dotHeight: 8,
              activeDotColor: const Color(0xFFF59E0B),
              dotColor: isDark ? Colors.white24 : Colors.black12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolCapabilities(ProviderProfile profile, bool isDark) {
    final tools = profile.skills.isNotEmpty
        ? profile.skills
        : [
            'Thermal Imaging Leak Camera',
            'Hydro-Jet Drain Cleaners',
            'Rotary Hammer & Core Driller',
            'Fluke Pro Digital Multimeter',
            'Laser Pipe Leveling System',
            'Borescope Inspection Scope',
            'Copper & PEX Pro-Press Rig',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Professional Tool & Diagnostic Capabilities', Icons.build_circle_outlined, isDark),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: tools.map((tool) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.handyman, color: Color(0xFFF59E0B), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    tool,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPricingGuideSection(double hourlyRate, String currency, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Contractor Rates & Estimate Guide', Icons.price_change_outlined, isDark),
        _buildGlassCard(
          isDark: isDark,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildPriceRow('Standard Diagnostic / Call-Out', '$currency ${hourlyRate.toStringAsFixed(0)}', 'Includes 1st hour inspection', isDark),
              Divider(color: isDark ? Colors.white12 : Colors.black12, height: 20),
              _buildPriceRow('Emergency 24/7 Dispatch', '$currency ${(hourlyRate * 1.5).toStringAsFixed(0)}', '< 30 min rapid response arrival', isDark, isHighlight: true),
              Divider(color: isDark ? Colors.white12 : Colors.black12, height: 20),
              _buildPriceRow('Full Day Project Contractor', '$currency ${(hourlyRate * 7).toStringAsFixed(0)}', '8 hours continuous trade labor', isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String title, String price, String subtitle, bool isDark, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isHighlight ? const Color(0xFFF59E0B) : (isDark ? Colors.white : Colors.black87),
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        Text(
          price,
          style: TextStyle(
            color: isHighlight ? const Color(0xFFF59E0B) : AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceListings(AsyncValue<List<ListingModel>> listingsAsync, String currency, bool isDark) {
    return listingsAsync.when(
      data: (listings) {
        if (listings.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Bookable Services & Replacement Parts', Icons.inventory_2_outlined, isDark),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: listings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final listing = listings[index];
                final isProduct = listing.listingType == ListingType.product;

                return _buildGlassCard(
                  isDark: isDark,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      if (listing.images.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: HubbleImage(
                            imagePath: listing.images.first,
                            width: 65,
                            height: 65,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isProduct ? Icons.plumbing : Icons.construction,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing.title,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              listing.isVariablePrice
                                  ? 'Custom Quote on Inspection'
                                  : '$currency ${listing.price.toStringAsFixed(0)} ${listing.billingType == BillingType.hourly ? '/hr' : ''}',
                              style: const TextStyle(
                                color: Color(0xFFF59E0B),
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isProduct)
                            IconButton(
                              icon: const Icon(Icons.add_shopping_cart, color: Color(0xFFF59E0B), size: 20),
                              onPressed: () => _addToCart(listing),
                              tooltip: 'Add Part to Cart',
                            ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ListingDetailScreen(listing: listing),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('View', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  Widget _buildReviewsSection(AsyncValue<List<ReviewModel>> reviewsAsync, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Client Reviews & Workmanship Ratings', Icons.rate_review_outlined, isDark),
        reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return _buildGlassCard(
                isDark: isDark,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No reviews yet. Request a service call to be the first to review!',
                      style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
                    ),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final review = reviews[index];
                return _buildGlassCard(
                  isDark: isDark,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                child: Text(
                                  review.clientName.isNotEmpty ? review.clientName[0].toUpperCase() : 'C',
                                  style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review.clientName,
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(review.createdAt),
                                    style: TextStyle(
                                      color: isDark ? Colors.white38 : Colors.black38,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          RatingBarIndicator(
                            rating: review.rating,
                            itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                            itemCount: 5,
                            itemSize: 14.0,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        review.text,
                        style: TextStyle(
                          color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black87,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B))),
          error: (e, st) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildStickyBottomBar(double hourlyRate, String currency, bool isDark) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B1120).withValues(alpha: 0.88) : Colors.white.withValues(alpha: 0.92),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEmergencyServiceSelected ? 'Emergency Rate' : 'Standard Rate',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _isEmergencyServiceSelected
                            ? '$currency ${(hourlyRate * 1.5).toStringAsFixed(0)}'
                            : '$currency ${hourlyRate.toStringAsFixed(0)}/hr',
                        style: TextStyle(
                          color: _isEmergencyServiceSelected ? const Color(0xFFEF4444) : (isDark ? Colors.white : AppColors.textLightPrimary),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _requestQuoteOrCallout(isEmergency: _isEmergencyServiceSelected),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isEmergencyServiceSelected ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        _isEmergencyServiceSelected ? 'Dispatch Emergency Callout' : 'Request Free Quote',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
