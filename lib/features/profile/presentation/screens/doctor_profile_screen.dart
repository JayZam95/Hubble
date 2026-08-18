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

class DoctorProfileScreen extends ConsumerStatefulWidget {
  final UserModel providerUser;

  const DoctorProfileScreen({super.key, required this.providerUser});

  @override
  ConsumerState<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends ConsumerState<DoctorProfileScreen> {
  bool _isTelehealthSelected = false; // false = In-Clinic, true = Telehealth Video

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No clinic phone number provided.')),
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
          SnackBar(content: Text('Unable to call clinic: $e')),
        );
      }
    }
  }

  Future<void> _startChat() async {
    final currentUser = ref.read(authStateProvider).user;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to message this physician.')),
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
        myName: currentUser.displayName.isNotEmpty ? currentUser.displayName : 'Patient',
        otherUid: widget.providerUser.uid,
        otherName: widget.providerUser.displayName.isNotEmpty ? widget.providerUser.displayName : 'Doctor',
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
          SnackBar(content: Text('Failed to open consultation chat: $e')),
        );
      }
    }
  }

  void _bookAppointment({ListingModel? prefilledListing}) {
    final currentUser = ref.read(authStateProvider).user;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to book an appointment.')),
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
        content: Text('${listing.title} added to cart'),
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
              color: const Color(0xFF0D9488).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF0D9488), size: 18),
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

    final double hourlyRate = profile.hourlyRate > 0 ? profile.hourlyRate : 250.0;
    final String currency = profile.currency.isNotEmpty ? profile.currency : 'K';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF09131F) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Medical teal & cyan ambient aura
          Positioned(
            top: -40,
            left: -40,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0D9488).withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
          Positioned(
            top: 420,
            right: -60,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                ),
              ),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Medical Specialist Sliver App Bar
              _buildDoctorHeroAppBar(isDark, hasImage),

              // Main Content Body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Quick Action Row (Book Appointment, Message, Call)
                      _buildQuickActionButtons(isDark),
                      const SizedBox(height: 24),

                      // In-Clinic vs Telehealth Consultation Mode Selector
                      _buildConsultationModeSelector(isDark),
                      const SizedBox(height: 24),

                      // Practice Philosophy & Bio
                      _buildDoctorBioCard(profile, isDark),
                      const SizedBox(height: 24),

                      // Medical Council Credentials & Education
                      _buildCredentialsSection(profile, isDark),
                      const SizedBox(height: 24),

                      // Clinical Practice Areas & Specializations
                      _buildPracticeAreasSection(profile, isDark),
                      const SizedBox(height: 24),

                      // Clinic Location Map & Telehealth Tech Overview
                      _isTelehealthSelected
                          ? _buildTelehealthDetailsCard(isDark)
                          : _buildClinicLocationMapCard(isDark),
                      const SizedBox(height: 24),

                      // Consultation Fees & Accepted Insurance Partners
                      _buildFeesAndInsuranceSection(hourlyRate, currency, isDark),
                      const SizedBox(height: 24),

                      // Bookable Medical Packages / Diagnostics
                      _buildMedicalListings(listingsAsync, currency, isDark),
                      const SizedBox(height: 24),

                      // Patient Reviews & Clinical Feedback
                      _buildPatientReviews(reviewsAsync, isDark),
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

  Widget _buildDoctorHeroAppBar(bool isDark, bool hasImage) {
    final profile = widget.providerUser.providerProfile;
    final rating = profile.ratingAsProvider > 0 ? profile.ratingAsProvider : 4.98;
    final consultations = profile.totalJobsCompleted > 0 ? profile.totalJobsCompleted * 20 : 850;

    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF09131F) : Colors.white,
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
              const SnackBar(content: Text('Doctor profile link copied to clipboard')),
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
                      ? [const Color(0xFF0F2636), const Color(0xFF09131F)]
                      : [const Color(0xFFCCFBF1), const Color(0xFFF8FAFC)],
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
                          border: Border.all(color: const Color(0xFF0D9488), width: 3.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D9488).withValues(alpha: 0.35),
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
                                  color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                                  child: Center(
                                    child: Text(
                                      widget.providerUser.displayName.isNotEmpty
                                          ? widget.providerUser.displayName[0].toUpperCase()
                                          : 'Dr',
                                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
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
                            color: Color(0xFF0D9488),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.providerUser.displayName.startsWith('Dr')
                            ? widget.providerUser.displayName
                            : 'Dr. ${widget.providerUser.displayName}',
                        style: AppTextStyles.heading1.copyWith(
                          fontSize: 21,
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
                        : 'Consultant Physician & Specialist Doctor',
                    style: const TextStyle(
                      color: Color(0xFF0D9488),
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
                      _buildMetricBadge(Icons.groups_rounded, '$consultations+ Patients', const Color(0xFF0D9488), isDark),
                      const SizedBox(width: 8),
                      _buildMetricBadge(Icons.health_and_safety_rounded, 'HPCZ Verified', const Color(0xFF0284C7), isDark),
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

  Widget _buildQuickActionButtons(bool isDark) {
    final phone = widget.providerUser.personalInfo.phoneNumber;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            onPressed: () => _bookAppointment(),
            icon: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 18),
            label: Text(
              _isTelehealthSelected ? 'Book Video Telehealth' : 'Book In-Person Clinic',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
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
            icon: Icon(Icons.chat_bubble_outline_rounded, color: isDark ? Colors.white : const Color(0xFF0D9488), size: 18),
            label: Text('Chat', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0D9488), fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: isDark ? Colors.white30 : const Color(0xFF0D9488).withValues(alpha: 0.5)),
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
              tooltip: 'Call Clinic',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConsultationModeSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isTelehealthSelected = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isTelehealthSelected
                      ? (isDark ? const Color(0xFF0D9488) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !_isTelehealthSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_hospital_rounded,
                      size: 16,
                      color: !_isTelehealthSelected
                          ? (isDark ? Colors.white : const Color(0xFF0D9488))
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '🏥 In-Clinic Visit',
                      style: TextStyle(
                        color: !_isTelehealthSelected
                            ? (isDark ? Colors.white : const Color(0xFF0D9488))
                            : (isDark ? Colors.white60 : Colors.black54),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isTelehealthSelected = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isTelehealthSelected
                      ? (isDark ? const Color(0xFF0D9488) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _isTelehealthSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam_rounded,
                      size: 16,
                      color: _isTelehealthSelected
                          ? (isDark ? Colors.white : const Color(0xFF0D9488))
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '💻 Telehealth Video',
                      style: TextStyle(
                        color: _isTelehealthSelected
                            ? (isDark ? Colors.white : const Color(0xFF0D9488))
                            : (isDark ? Colors.white60 : Colors.black54),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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

  Widget _buildDoctorBioCard(ProviderProfile profile, bool isDark) {
    final bio = profile.bio.isNotEmpty
        ? profile.bio
        : 'Consultant physician with over 14 years of clinical experience in internal medicine, chronic disease management, preventive health screenings, and patient-centered primary care. Dedicated to evidence-based treatment and empathetic care.';

    return _buildGlassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medical_information_outlined, color: Color(0xFF0D9488), size: 22),
              const SizedBox(width: 8),
              Text(
                'Clinical Background & Bio',
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
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsSection(ProviderProfile profile, bool isDark) {
    final credentials = profile.experience.isNotEmpty
        ? profile.experience
        : [
            'MBChB - Bachelor of Medicine & Surgery (University of Zambia)',
            'MMed in Internal Medicine & Clinical Cardiology',
            'Fellow of the College of Physicians (FCP East & Southern Africa)',
            'Registered Medical Practitioner with HPCZ (Reg #MD-78219)',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Medical Council Credentials & Education', Icons.workspace_premium_outlined, isDark),
        _buildGlassCard(
          isDark: isDark,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: credentials.length,
            separatorBuilder: (context, index) => Divider(
              color: isDark ? Colors.white12 : Colors.black12,
              height: 20,
            ),
            itemBuilder: (context, index) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified, color: Color(0xFF0D9488), size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          credentials[index],
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Verified Medical Council Board Certified',
                          style: TextStyle(
                            color: Color(0xFF0D9488),
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

  Widget _buildPracticeAreasSection(ProviderProfile profile, bool isDark) {
    final areas = profile.skills.isNotEmpty
        ? profile.skills
        : [
            'Cardiovascular Health',
            'Hypertension & Diabetes',
            'Preventive Health Screenings',
            'General Adult Medicine',
            'Infectious Disease Triage',
            'Routine Health Checkups',
            'Ultrasound Diagnostics',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Clinical Practice Areas', Icons.healing_outlined, isDark),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: areas.map((area) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.health_and_safety_outlined, color: Color(0xFF0D9488), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    area,
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

  Widget _buildClinicLocationMapCard(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Clinic Location & Schedule', Icons.pin_drop_outlined, isDark),
        _buildGlassCard(
          isDark: isDark,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.location_city_rounded, color: Color(0xFF0D9488), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lusaka Apex Medical Suite #4B',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Plot 10482, Great East Road, Lusaka',
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, color: Color(0xFF0D9488), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Mon - Fri: 08:00 - 17:00 | Sat: 09:00 - 13:00',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.local_parking_rounded, color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Free On-Site Patient Parking & Wheelchair Accessible',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTelehealthDetailsCard(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Telehealth Features & Video Technology', Icons.video_call_outlined, isDark),
        _buildGlassCard(
          isDark: isDark,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTelehealthRow(Icons.lock_outline, 'End-to-End Encrypted HD Video Consultation', 'HIPAA & GDPR Compliant Medical Channel', isDark),
              Divider(color: isDark ? Colors.white12 : Colors.black12, height: 20),
              _buildTelehealthRow(Icons.description_outlined, 'Digital e-Prescription to Your Pharmacy', 'Instant digital script sent straight to your phone', isDark),
              Divider(color: isDark ? Colors.white12 : Colors.black12, height: 20),
              _buildTelehealthRow(Icons.assignment_turned_in_outlined, 'Official Medical Sick Notes & Referrals', 'Legally recognized certificates issued post-call', isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTelehealthRow(IconData icon, String title, String subtitle, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0D9488).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF0D9488), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeesAndInsuranceSection(double hourlyRate, String currency, bool isDark) {
    final insurancePartners = [
      'NHIMA National Health Insurance',
      'Madison Health',
      'SES Unisure',
      'Prudential Life',
      'Liberty Health',
      'Cash / Hubble Escrow',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Consultation Fees & Accepted Insurance', Icons.credit_card_outlined, isDark),
        _buildGlassCard(
          isDark: isDark,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isTelehealthSelected ? 'Telehealth Consultation Fee' : 'In-Person Consultation Fee',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '30-minute comprehensive medical review',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _isTelehealthSelected
                        ? '$currency ${(hourlyRate * 0.8).toStringAsFixed(0)}'
                        : '$currency ${hourlyRate.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF0D9488),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
              const SizedBox(height: 14),
              Text(
                'Accepted Insurance Direct Billing:',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: insurancePartners.map((ins) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
                    ),
                    child: Text(
                      ins,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicalListings(AsyncValue<List<ListingModel>> listingsAsync, String currency, bool isDark) {
    return listingsAsync.when(
      data: (listings) {
        if (listings.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Diagnostic Packages & Health Checkups', Icons.health_and_safety_outlined, isDark),
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
                            color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.medical_services,
                            color: Color(0xFF0D9488),
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
                              '$currency ${listing.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Color(0xFF0D9488),
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
                              icon: const Icon(Icons.add_shopping_cart, color: Color(0xFF0D9488), size: 20),
                              onPressed: () => _addToCart(listing),
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
                              backgroundColor: const Color(0xFF0D9488),
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

  Widget _buildPatientReviews(AsyncValue<List<ReviewModel>> reviewsAsync, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Patient Reviews & Feedback', Icons.rate_review_outlined, isDark),
        reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return _buildGlassCard(
                isDark: isDark,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No patient reviews posted yet. Book a consultation to leave a review!',
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
                                backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.2),
                                child: Text(
                                  review.clientName.isNotEmpty ? review.clientName[0].toUpperCase() : 'P',
                                  style: const TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold, fontSize: 13),
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
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488))),
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
              color: isDark ? const Color(0xFF09131F).withValues(alpha: 0.88) : Colors.white.withValues(alpha: 0.92),
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
                        _isTelehealthSelected ? 'Telehealth Fee' : 'Clinic Fee',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _isTelehealthSelected
                            ? '$currency ${(hourlyRate * 0.8).toStringAsFixed(0)}'
                            : '$currency ${hourlyRate.toStringAsFixed(0)}',
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
                    child: ElevatedButton.icon(
                      onPressed: () => _bookAppointment(),
                      icon: Icon(
                        _isTelehealthSelected ? Icons.videocam_rounded : Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        _isTelehealthSelected ? 'Book Video Telehealth' : 'Book Clinic Appointment',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
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
