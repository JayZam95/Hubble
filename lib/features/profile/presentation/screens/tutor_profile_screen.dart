import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
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

class TutorProfileScreen extends ConsumerStatefulWidget {
  final UserModel providerUser;

  const TutorProfileScreen({super.key, required this.providerUser});

  @override
  ConsumerState<TutorProfileScreen> createState() => _TutorProfileScreenState();
}

class _TutorProfileScreenState extends ConsumerState<TutorProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedPackageIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number provided by tutor.')),
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
          SnackBar(content: Text('Unable to make call: $e')),
        );
      }
    }
  }

  Future<void> _startChat() async {
    final currentUser = ref.read(authStateProvider).user;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to send a message.')),
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
        myName: currentUser.displayName.isNotEmpty ? currentUser.displayName : 'Student',
        otherUid: widget.providerUser.uid,
        otherName: widget.providerUser.displayName.isNotEmpty ? widget.providerUser.displayName : 'Tutor',
      );

      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
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
          SnackBar(content: Text('Failed to initiate chat: $e')),
        );
      }
    }
  }

  void _bookTrialLesson({ListingModel? prefilledListing}) {
    final currentUser = ref.read(authStateProvider).user;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to book a session.')),
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
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.9),
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
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
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

    final double hourlyRate = profile.hourlyRate > 0 ? profile.hourlyRate : 120.0;
    final String currency = profile.currency.isNotEmpty ? profile.currency : 'K';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background ambient lights
          Positioned(
            top: -60,
            right: -60,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
          Positioned(
            top: 350,
            left: -80,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                ),
              ),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Custom Academic Hero AppBar
              _buildAcademicAppBar(isDark, hasImage),

              // Main Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Quick Action Buttons (Message, Call, Trial)
                      _buildQuickActionButtons(isDark),
                      const SizedBox(height: 24),

                      // Academic Overview / Teaching Philosophy
                      _buildPhilosophyCard(profile, isDark),
                      const SizedBox(height: 24),

                      // Degrees & Academic Credentials
                      _buildDegreesSection(profile, isDark),
                      const SizedBox(height: 24),

                      // Subjects & Grade Levels Taught
                      _buildSubjectsSection(profile, isDark),
                      const SizedBox(height: 24),

                      // Syllabus & Curriculum Breakdown
                      _buildSyllabusSection(isDark),
                      const SizedBox(height: 24),

                      // Tuition Packages & Rates
                      _buildTuitionRatesSection(hourlyRate, currency, isDark),
                      const SizedBox(height: 24),

                      // Active Courses / Study Materials Listings
                      _buildCoursesAndListings(listingsAsync, currency, isDark),
                      const SizedBox(height: 24),

                      // Student & Parent Testimonials
                      _buildTestimonialsSection(reviewsAsync, isDark),
                      const SizedBox(height: 100), // Spacing for sticky bottom CTA
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

  Widget _buildAcademicAppBar(bool isDark, bool hasImage) {
    final profile = widget.providerUser.providerProfile;
    final rating = profile.ratingAsProvider > 0 ? profile.ratingAsProvider : 4.9;
    final reviewsCount = profile.reviewCount > 0 ? profile.reviewCount : 38;
    final totalHours = profile.totalJobsCompleted > 0 ? profile.totalJobsCompleted * 15 : 450;

    return SliverAppBar(
      expandedHeight: 330,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
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
              const SnackBar(content: Text('Tutor profile link copied to clipboard')),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Dark elegant background with chalkboard / academic aura
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [const Color(0xFFE2E8F0), const Color(0xFFF8FAFC)],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  // Avatar with Verified Academic Badge
                  Stack(
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
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
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  child: Center(
                                    child: Text(
                                      widget.providerUser.displayName.isNotEmpty
                                          ? widget.providerUser.displayName[0].toUpperCase()
                                          : 'T',
                                      style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Name and Badge
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
                  // Profession / Academic Title
                  Text(
                    profile.professionTitle.isNotEmpty
                        ? profile.professionTitle
                        : 'Senior Academic Educator & STEM Specialist',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Metric Pills (Rating, Hours taught, Students)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMetricPill(Icons.star_rounded, '$rating ($reviewsCount)', Colors.amber, isDark),
                      const SizedBox(width: 8),
                      _buildMetricPill(Icons.timer_outlined, '$totalHours+ Hours', const Color(0xFF3B82F6), isDark),
                      const SizedBox(width: 8),
                      _buildMetricPill(Icons.people_alt_outlined, '${profile.totalJobsCompleted + 45} Students', AppColors.primary, isDark),
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

  Widget _buildMetricPill(IconData icon, String text, Color color, bool isDark) {
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
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
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
            onPressed: () => _bookTrialLesson(),
            icon: const Icon(Icons.calendar_month, color: Colors.white, size: 18),
            label: const Text('Book Trial Lesson', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
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
            icon: Icon(Icons.chat_bubble_outline_rounded, color: isDark ? Colors.white : AppColors.primary, size: 18),
            label: Text('Chat', style: TextStyle(color: isDark ? Colors.white : AppColors.primary, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: isDark ? Colors.white30 : AppColors.primary.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        if (phone.isNotEmpty) ...[
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
            ),
            child: IconButton(
              icon: const Icon(Icons.phone_in_talk, color: AppColors.success),
              onPressed: () => _makePhoneCall(phone),
              tooltip: 'Call Tutor',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhilosophyCard(ProviderProfile profile, bool isDark) {
    final bio = profile.bio.isNotEmpty
        ? profile.bio
        : 'Dedicated educator specializing in transforming complex academic concepts into intuitive, lifelong problem-solving skills. Focused on personalized student mastery, exam readiness, and building confidence.';

    return _buildGlassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.format_quote_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Teaching Philosophy & Bio',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            bio,
            style: TextStyle(
              color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black87,
              fontSize: 14,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.workspace_premium_outlined, color: AppColors.accent, size: 16),
              const SizedBox(width: 6),
              Text(
                'Cambridge / IGCSE / ECZ / AP / IB Aligned',
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

  Widget _buildDegreesSection(ProviderProfile profile, bool isDark) {
    final experienceList = profile.experience.isNotEmpty
        ? profile.experience
        : [
            'B.Sc. Pure & Applied Mathematics - University of Zambia (First Class Hons)',
            'Postgraduate Certificate in Education (PGCE) - STEM Pedagogy',
            'Lead High School Olympiad Coach (5+ Years Track Record)',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Degrees & Qualifications', Icons.school_outlined, isDark),
        _buildGlassCard(
          isDark: isDark,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: experienceList.length,
            separatorBuilder: (context, index) => Divider(
              color: isDark ? Colors.white12 : Colors.black12,
              height: 20,
            ),
            itemBuilder: (context, index) {
              final exp = experienceList[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_outlined, color: Color(0xFF3B82F6), size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exp,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Verified Credential',
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

  Widget _buildSubjectsSection(ProviderProfile profile, bool isDark) {
    final subjects = profile.skills.isNotEmpty
        ? profile.skills
        : [
            'Pure Mathematics',
            'Physics & Mechanics',
            'Calculus I & II',
            'SAT / ACT Prep',
            'Chemistry',
            'Coding (Python & Java)',
            'Statistics',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Subjects Taught & Expertise', Icons.menu_book_outlined, isDark),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: subjects.map((subject) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    subject,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 13,
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

  Widget _buildSyllabusSection(bool isDark) {
    final modules = [
      {
        'title': 'Module 1: Baseline Assessment & Foundations',
        'desc': 'Diagnostic test to identify knowledge gaps, review of fundamental formulas, and custom milestone roadmap.',
        'icon': Icons.insights_rounded,
        'badge': 'Week 1-2',
      },
      {
        'title': 'Module 2: Deep Concept Mastery & Guided Problem Sets',
        'desc': 'Interactive whiteboard step-by-step proofs, practical application drills, and weekly homework feedback.',
        'icon': Icons.psychology_outlined,
        'badge': 'Week 3-6',
      },
      {
        'title': 'Module 3: Past Papers, Time Management & Exam Mastery',
        'desc': 'Timed mock exams under real conditions, marking scheme analysis, and exam room stress strategies.',
        'icon': Icons.fact_check_outlined,
        'badge': 'Week 7-8',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Structured Syllabus Overview', Icons.view_timeline_outlined, isDark),
        _buildGlassCard(
          isDark: isDark,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: modules.map((m) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(m['icon'] as IconData, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  m['title'] as String,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  m['badge'] as String,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m['desc'] as String,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTuitionRatesSection(double hourlyRate, String currency, bool isDark) {
    final packages = [
      {
        'title': 'Single Session',
        'subtitle': '1-on-1 Hourly Tuition',
        'price': '$currency ${hourlyRate.toStringAsFixed(0)}',
        'unit': '/ hour',
        'perks': ['1 Hour 1-on-1 Zoom / In-Person', 'Whiteboard notes export', 'Digital worksheet included'],
      },
      {
        'title': 'Trial Assessment',
        'subtitle': '45-Min Evaluation',
        'price': '$currency ${(hourlyRate * 0.5).toStringAsFixed(0)}',
        'unit': 'intro special',
        'perks': ['Diagnostic test included', 'Customized study roadmap', 'No long-term commitment'],
      },
      {
        'title': 'Monthly Intensive',
        'subtitle': '8 Sessions / Month',
        'price': '$currency ${(hourlyRate * 7.2).toStringAsFixed(0)}',
        'unit': '/ month (10% off)',
        'perks': ['8 Hours 1-on-1 tutoring', 'Priority chat Q&A 24/7', 'Weekly progress report to parents'],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Tuition Rates & Packages', Icons.monetization_on_outlined, isDark),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: packages.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final pkg = packages[index];
              final isSelected = _selectedPackageIndex == index;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedPackageIndex = index);
                },
                child: Container(
                  width: 240,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : (isDark ? Colors.white12 : Colors.black12),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              pkg['title'] as String,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                          ],
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pkg['price'] as String,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          ),
                          Text(
                            pkg['unit'] as String,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: ((pkg['perks'] as List<String>).take(2)).map((perk) {
                          return Row(
                            children: [
                              const Icon(Icons.done, color: AppColors.primary, size: 12),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  perk,
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.black87,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCoursesAndListings(AsyncValue<List<ListingModel>> listingsAsync, String currency, bool isDark) {
    return listingsAsync.when(
      data: (listings) {
        if (listings.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Courses & Study Materials', Icons.library_books_outlined, isDark),
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
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isProduct ? Icons.book : Icons.video_call,
                            color: AppColors.primary,
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
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$currency ${listing.price.toStringAsFixed(0)} ${listing.billingType == BillingType.hourly ? '/hr' : ''}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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
                              icon: const Icon(Icons.add_shopping_cart, color: AppColors.primary, size: 20),
                              onPressed: () => _addToCart(listing),
                              tooltip: 'Add to Cart',
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
                              backgroundColor: AppColors.primary,
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

  Widget _buildTestimonialsSection(AsyncValue<List<ReviewModel>> reviewsAsync, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Student Testimonials & Reviews', Icons.rate_review_outlined, isDark),
        reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return _buildGlassCard(
                isDark: isDark,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No reviews posted yet. Be the first to book a trial lesson!',
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
                                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                child: Text(
                                  review.clientName.isNotEmpty ? review.clientName[0].toUpperCase() : 'S',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
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
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
              color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.9),
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
                        'Hourly Rate',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '$currency ${hourlyRate.toStringAsFixed(0)}/hr',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.textLightPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _bookTrialLesson(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Book Trial Lesson',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
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
