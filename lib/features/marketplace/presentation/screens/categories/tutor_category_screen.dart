import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/presentation/widgets/hubble_image.dart';
import '../../../../../core/presentation/widgets/shimmer_loading.dart';
import '../../../../../core/presentation/widgets/animated_empty_state.dart';
import '../../../domain/models/listing_model.dart';
import '../../providers/marketplace_provider.dart';
import '../listing_detail_screen.dart';

class TutorItem {
  final String id;
  final String name;
  final String avatarUrl;
  final String title;
  final String subject;
  final List<String> academicLevels; // Primary, Secondary, University, Professional
  final double hourlyRate;
  final double rating;
  final int reviewsCount;
  final bool isVerified;
  final String qualifications;
  final String bio;
  final bool offersOnline;
  final bool offersInPerson;
  final String location;

  const TutorItem({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.title,
    required this.subject,
    required this.academicLevels,
    required this.hourlyRate,
    required this.rating,
    required this.reviewsCount,
    required this.isVerified,
    required this.qualifications,
    required this.bio,
    this.offersOnline = true,
    this.offersInPerson = true,
    required this.location,
  });
}

class TutorCategoryScreen extends ConsumerStatefulWidget {
  const TutorCategoryScreen({super.key});

  @override
  ConsumerState<TutorCategoryScreen> createState() => _TutorCategoryScreenState();
}

class _TutorCategoryScreenState extends ConsumerState<TutorCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSubject = 'All Subjects';
  String _selectedAcademicLevel = 'All Levels';
  String _selectedRateFilter = 'All Rates';
  String _selectedFormat = 'All Formats'; // All Formats, Online Only, In-Person
  bool _verifiedOnly = false;

  final List<String> _subjects = [
    'All Subjects',
    'Math',
    'Sciences',
    'Languages',
    'Programming',
    'Business',
    'Music',
    'Humanities',
  ];

  final List<String> _academicLevels = [
    'All Levels',
    'Primary (G1-7)',
    'Secondary (G8-12)',
    'University',
    'Professional',
  ];

  final List<String> _rateFilters = [
    'All Rates',
    'Under K100/hr',
    'K100 - K200/hr',
    'K200 - K350/hr',
    'K350+/hr',
  ];

  final List<TutorItem> _mockTutors = const [
    TutorItem(
      id: 'tutor_1',
      name: 'Kondwani Banda',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fit=crop&w=300&q=80',
      title: 'Senior Mathematics & Physics Specialist',
      subject: 'Math',
      academicLevels: ['Secondary (G8-12)', 'University'],
      hourlyRate: 180.0,
      rating: 4.9,
      reviewsCount: 42,
      isVerified: true,
      qualifications: 'BSc. Mathematics (UNZA), 8+ Yrs Exp',
      bio: 'Specialist in ECZ G12 Exam Prep, IGCSE & Cambridge A-Levels. High pass-rate guarantee with interactive problem solving.',
      offersOnline: true,
      offersInPerson: true,
      location: 'Woodlands, Lusaka',
    ),
    TutorItem(
      id: 'tutor_2',
      name: 'Chileshe Mulenga',
      avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?fit=crop&w=300&q=80',
      title: 'Full-Stack Software Engineer & Python Tutor',
      subject: 'Programming',
      academicLevels: ['University', 'Professional'],
      hourlyRate: 250.0,
      rating: 5.0,
      reviewsCount: 29,
      isVerified: true,
      qualifications: 'MSc. Computer Science, Google Certified',
      bio: 'Learn Python, Flutter, JavaScript, and Data Structures. Practical project-based lessons tailored for career starters.',
      offersOnline: true,
      offersInPerson: false,
      location: 'Kabulonga, Lusaka',
    ),
    TutorItem(
      id: 'tutor_3',
      name: 'Mwamba Phiri',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?fit=crop&w=300&q=80',
      title: 'French & English Linguistics Instructor',
      subject: 'Languages',
      academicLevels: ['Primary (G1-7)', 'Secondary (G8-12)', 'Professional'],
      hourlyRate: 140.0,
      rating: 4.8,
      reviewsCount: 38,
      isVerified: true,
      qualifications: 'DELF B2 / Alliance Française Diploma',
      bio: 'Bilingual tutor focusing on spoken French, conversational fluency, and professional business English writing.',
      offersOnline: true,
      offersInPerson: true,
      location: 'Rhodespark, Lusaka',
    ),
    TutorItem(
      id: 'tutor_4',
      name: 'Dr. Joseph Tembo',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?fit=crop&w=300&q=80',
      title: 'Chemistry & Biology Medical Pre-med Tutor',
      subject: 'Sciences',
      academicLevels: ['Secondary (G8-12)', 'University'],
      hourlyRate: 220.0,
      rating: 4.95,
      reviewsCount: 56,
      isVerified: true,
      qualifications: 'MBChB Medicine & Surgery, UNZA',
      bio: 'Simplifying complex organic chemistry, biochemistry, and human anatomy for pre-med students and high schoolers.',
      offersOnline: true,
      offersInPerson: true,
      location: 'Roma, Lusaka',
    ),
    TutorItem(
      id: 'tutor_5',
      name: 'Mutinta Mweene',
      avatarUrl: 'https://images.unsplash.com/photo-1589156280159-27698a70f29e?fit=crop&w=300&q=80',
      title: 'Accounting, Finance & ACCA Coach',
      subject: 'Business',
      academicLevels: ['University', 'Professional'],
      hourlyRate: 280.0,
      rating: 4.85,
      reviewsCount: 31,
      isVerified: true,
      qualifications: 'ACCA Fellow, BBA Finance',
      bio: 'Expert tutoring for ACCA, ZICA, and University financial accounting modules with exam technique masterclasses.',
      offersOnline: true,
      offersInPerson: false,
      location: 'Lusaka CBD',
    ),
    TutorItem(
      id: 'tutor_6',
      name: 'Bupe Chilengwe',
      avatarUrl: 'https://images.unsplash.com/photo-1567532939604-b6b5b0db2604?fit=crop&w=300&q=80',
      title: 'Primary School Foundational Tutor (Grade 1-7)',
      subject: 'Math',
      academicLevels: ['Primary (G1-7)'],
      hourlyRate: 95.0,
      rating: 4.9,
      reviewsCount: 47,
      isVerified: true,
      qualifications: 'B.Ed Primary Education (NKRUMAH)',
      bio: 'Patient, fun, and engaging reading, numeracy, and phonics coach for early childhood and primary students.',
      offersOnline: false,
      offersInPerson: true,
      location: 'Chelstone, Lusaka',
    ),
    TutorItem(
      id: 'tutor_7',
      name: 'Gabriel Zimba',
      avatarUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?fit=crop&w=300&q=80',
      title: 'Piano, Guitar & Music Theory Instructor',
      subject: 'Music',
      academicLevels: ['Primary (G1-7)', 'Secondary (G8-12)', 'Professional'],
      hourlyRate: 160.0,
      rating: 5.0,
      reviewsCount: 19,
      isVerified: false,
      qualifications: 'ABRSM Grade 8 Certified',
      bio: 'Learn classical piano, acoustic guitar, ear training, and vocal techniques at your own comfortable pace.',
      offersOnline: true,
      offersInPerson: true,
      location: 'Mass Media, Lusaka',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openTrialLessonBooking(BuildContext context, TutorItem tutor) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TrialLessonBookingSheet(tutor: tutor),
    );
  }

  void _openListingTrialBooking(BuildContext context, ListingModel listing) {
    HapticFeedback.mediumImpact();
    final tutor = TutorItem(
      id: listing.providerId.isNotEmpty ? listing.providerId : listing.id,
      name: listing.providerName.isNotEmpty ? listing.providerName : 'Verified Educator',
      avatarUrl: listing.images.isNotEmpty ? listing.images.first : '',
      title: listing.title,
      subject: listing.category,
      academicLevels: ['Secondary (G8-12)', 'University'],
      hourlyRate: listing.price,
      rating: 4.9,
      reviewsCount: 20,
      isVerified: true,
      qualifications: 'Certified Tutor',
      bio: listing.description,
      offersOnline: true,
      offersInPerson: listing.travelsToClient,
      location: 'Lusaka',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TrialLessonBookingSheet(tutor: tutor, prefilledListing: listing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    const primaryPurple = Color(0xFF7C3AED); // Violet 600

    final allListingsAsync = ref.watch(allListingsProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tutoring & Education Hub',
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.tune_rounded, color: isDark ? Colors.white70 : Colors.black87),
            onPressed: () => _showFilterSheet(context, isDark),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Hero Hub Banner ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF9333EA), Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Find Your Perfect Mentor',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '1-on-1 Academic, STEM & Skill Coaching',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Trial Lesson Promotion Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.bolt_rounded, color: Color(0xFFFBBF24), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'First 30-min Trial Lesson 50% Off with Verified Tutors!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 2. Search Field ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Search subjects, exams, or tutor names...',
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF7C3AED)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: cardColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── 3. Subject Filter Chips (Horizontal) ───────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subjects',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (_selectedSubject != 'All Subjects' || _selectedAcademicLevel != 'All Levels' || _verifiedOnly)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _selectedSubject = 'All Subjects';
                            _selectedAcademicLevel = 'All Levels';
                            _selectedRateFilter = 'All Rates';
                            _selectedFormat = 'All Formats';
                            _verifiedOnly = false;
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                        child: const Text(
                          'Reset Filters',
                          style: TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: _subjects.map((subj) {
                    final isSel = _selectedSubject == subj;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedSubject = subj);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? primaryPurple : cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSel ? primaryPurple : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Text(
                          subj,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 14),

              // ── 4. Academic Level Pills ────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: _academicLevels.map((lvl) {
                    final isSel = _selectedAcademicLevel == lvl;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedAcademicLevel = lvl);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? primaryPurple.withValues(alpha: 0.15) : cardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSel ? primaryPurple : (isDark ? Colors.white10 : Colors.black12),
                            width: isSel ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSel) ...[
                              Icon(Icons.check_rounded, size: 14, color: primaryPurple),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              lvl,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel ? primaryPurple : (isDark ? Colors.white60 : Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 14),

              // ── 5. Quick Format & Verified Toggles Bar ─────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Verified Only toggle
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _verifiedOnly = !_verifiedOnly);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _verifiedOnly ? const Color(0xFF10B981).withValues(alpha: 0.15) : cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _verifiedOnly ? const Color(0xFF10B981) : (isDark ? Colors.white12 : Colors.black12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: _verifiedOnly ? const Color(0xFF10B981) : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Verified Only',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _verifiedOnly ? const Color(0xFF10B981) : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Format dropdown / toggle
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (_selectedFormat == 'All Formats') {
                            _selectedFormat = 'Online Only';
                          } else if (_selectedFormat == 'Online Only') {
                            _selectedFormat = 'In-Person';
                          } else {
                            _selectedFormat = 'All Formats';
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _selectedFormat != 'All Formats' ? primaryPurple : (isDark ? Colors.white12 : Colors.black12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _selectedFormat == 'Online Only'
                                  ? Icons.videocam_rounded
                                  : _selectedFormat == 'In-Person'
                                      ? Icons.home_work_rounded
                                      : Icons.laptop_chromebook_rounded,
                              size: 14,
                              color: _selectedFormat != 'All Formats' ? primaryPurple : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _selectedFormat,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _selectedFormat != 'All Formats' ? primaryPurple : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── 6. Live Listings & Tutors Feed ─────────────────────────────
              allListingsAsync.when(
                data: (listings) {
                  // Filter live listings matching education/tutor
                  final educationListings = listings.where((l) {
                    final cat = l.category.toLowerCase();
                    return cat.contains('educat') || cat.contains('tutor') || cat.contains('teach') || cat.contains('school');
                  }).toList();

                  // Filter mock tutors
                  final filteredMockTutors = _mockTutors.where((t) {
                    // Subject filter
                    if (_selectedSubject != 'All Subjects' && !t.subject.toLowerCase().contains(_selectedSubject.toLowerCase())) {
                      return false;
                    }
                    // Academic level filter
                    if (_selectedAcademicLevel != 'All Levels' && !t.academicLevels.contains(_selectedAcademicLevel)) {
                      return false;
                    }
                    // Verified filter
                    if (_verifiedOnly && !t.isVerified) return false;
                    // Format filter
                    if (_selectedFormat == 'Online Only' && !t.offersOnline) return false;
                    if (_selectedFormat == 'In-Person' && !t.offersInPerson) return false;
                    // Rate filter
                    if (_selectedRateFilter == 'Under K100/hr' && t.hourlyRate >= 100) return false;
                    if (_selectedRateFilter == 'K100 - K200/hr' && (t.hourlyRate < 100 || t.hourlyRate > 200)) return false;
                    if (_selectedRateFilter == 'K200 - K350/hr' && (t.hourlyRate < 200 || t.hourlyRate > 350)) return false;
                    if (_selectedRateFilter == 'K350+/hr' && t.hourlyRate < 350) return false;
                    // Search Query
                    if (_searchQuery.isNotEmpty) {
                      final matchName = t.name.toLowerCase().contains(_searchQuery);
                      final matchTitle = t.title.toLowerCase().contains(_searchQuery);
                      final matchSubj = t.subject.toLowerCase().contains(_searchQuery);
                      final matchBio = t.bio.toLowerCase().contains(_searchQuery);
                      if (!matchName && !matchTitle && !matchSubj && !matchBio) return false;
                    }
                    return true;
                  }).toList();

                  // Combine or display
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Available Tutors & Courses (${filteredMockTutors.length + educationListings.length})',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const Text(
                              'Verified Mentors',
                              style: TextStyle(
                                fontSize: 12,
                                color: primaryPurple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Live marketplace listings
                        if (educationListings.isNotEmpty) ...[
                          ...educationListings.map((l) => _buildLiveListingCard(context, l, isDark, cardColor, primaryPurple)),
                          const SizedBox(height: 8),
                        ],

                        // Mock specialized tutors
                        if (filteredMockTutors.isEmpty && educationListings.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: AnimatedEmptyState(
                              icon: Icons.school_outlined,
                              title: 'No Tutors Match Your Filters',
                              subtitle: 'Try adjusting your subject, level, or rate filters to find more educators.',
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredMockTutors.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final tutor = filteredMockTutors[index];
                              return _buildTutorCard(context, tutor, isDark, cardColor, primaryPurple);
                            },
                          ),
                      ],
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: ShimmerListTile(),
                ),
                error: (e, st) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Error loading tutors: $e'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTutorCard(
    BuildContext context,
    TutorItem tutor,
    bool isDark,
    Color cardColor,
    Color primaryPurple,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Avatar, Name, Rating, Rate
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: primaryPurple.withValues(alpha: 0.1),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: HubbleImage(
                        imagePath: tutor.avatarUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (tutor.isVerified)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            tutor.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryPurple.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tutor.subject,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: primaryPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tutor.title,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          '${tutor.rating} (${tutor.reviewsCount})',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            tutor.location,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'K ${tutor.hourlyRate.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const Text(
                    '/ hour',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Qualifications & Bio
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded, size: 14, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        tutor.qualifications,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  tutor.bio,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Academic Level Chips & Format Badges
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              ...tutor.academicLevels.map((lvl) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      lvl,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )),
              if (tutor.offersOnline)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam_rounded, size: 10, color: Colors.blue),
                      SizedBox(width: 3),
                      Text(
                        'Online',
                        style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              if (tutor.offersInPerson)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.home_rounded, size: 10, color: Colors.teal),
                      SizedBox(width: 3),
                      Text(
                        'Home Visit',
                        style: TextStyle(fontSize: 10, color: Colors.teal, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Action Buttons: Book Trial Lesson CTA (Prominent) + View Profile
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => _openTrialLessonBooking(context, tutor),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.calendar_month_rounded, size: 16),
                  label: const Text(
                    'Book Trial Lesson',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showTutorDetailsSheet(context, tutor);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryPurple,
                    side: BorderSide(color: primaryPurple.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveListingCard(
    BuildContext context,
    ListingModel listing,
    bool isDark,
    Color cardColor,
    Color primaryPurple,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryPurple.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 65,
                  height: 65,
                  child: listing.images.isNotEmpty && listing.images.first.isNotEmpty
                      ? HubbleImage(imagePath: listing.images.first, fit: BoxFit.cover)
                      : Container(
                          color: primaryPurple.withValues(alpha: 0.15),
                          child: Icon(Icons.school_rounded, color: primaryPurple, size: 30),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'by ${listing.providerName}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'K ${listing.price.toStringAsFixed(0)} / ${listing.billingType.name}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openListingTrialBooking(context, listing),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.calendar_month_rounded, size: 16),
                  label: const Text('Book Trial / Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: listing)),
                  );
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                ),
                child: const Text('View', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Tutors',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Hourly Rate Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _rateFilters.map((rate) {
                      final isSel = _selectedRateFilter == rate;
                      return ChoiceChip(
                        label: Text(rate),
                        selected: isSel,
                        onSelected: (val) {
                          setModalState(() => _selectedRateFilter = rate);
                          setState(() => _selectedRateFilter = rate);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: const Text('Verified Tutors Only', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Background-checked and certified mentors', style: TextStyle(fontSize: 12)),
                    value: _verifiedOnly,
                    activeTrackColor: const Color(0xFF7C3AED),
                    onChanged: (v) {
                      setModalState(() => _verifiedOnly = v);
                      setState(() => _verifiedOnly = v);
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTutorDetailsSheet(BuildContext context, TutorItem tutor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: HubbleImage(imagePath: tutor.avatarUrl, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tutor.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(tutor.title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        Text('K ${tutor.hourlyRate.toStringAsFixed(0)} / hour',
                            style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('About & Teaching Approach', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              Text(tutor.bio, style: const TextStyle(fontSize: 13, height: 1.4)),
              const SizedBox(height: 14),
              const Text('Qualifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(tutor.qualifications, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openTrialLessonBooking(context, tutor);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: const Text('Book 30-min Trial Lesson', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrialLessonBookingSheet extends StatefulWidget {
  final TutorItem tutor;
  final ListingModel? prefilledListing;

  const _TrialLessonBookingSheet({
    required this.tutor,
    this.prefilledListing,
  });

  @override
  State<_TrialLessonBookingSheet> createState() => _TrialLessonBookingSheetState();
}

class _TrialLessonBookingSheetState extends State<_TrialLessonBookingSheet> {
  String _selectedSlot = '10:00 AM';
  String _lessonFormat = 'Online (Google Meet/Zoom)';
  final TextEditingController _topicController = TextEditingController();
  bool _isBooking = false;

  final List<String> _slots = [
    '09:00 AM',
    '10:30 AM',
    '02:00 PM',
    '03:30 PM',
    '05:00 PM',
  ];

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trialFee = (widget.tutor.hourlyRate * 0.5).roundToDouble();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school_rounded, color: Color(0xFF7C3AED), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Book 30-min Trial Lesson',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      Text(
                        'with ${widget.tutor.name}',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Promo Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Trial Rate (50% Off):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(
                    'K ${trialFee.toStringAsFixed(0)} (Normal K ${widget.tutor.hourlyRate.toStringAsFixed(0)})',
                    style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Text('Lesson Format', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _lessonFormat = 'Online (Google Meet/Zoom)'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _lessonFormat.contains('Online') ? const Color(0xFF7C3AED) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF7C3AED)),
                      ),
                      child: Center(
                        child: Text(
                          '💻 Online Video',
                          style: TextStyle(
                            color: _lessonFormat.contains('Online') ? Colors.white : const Color(0xFF7C3AED),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _lessonFormat = 'In-Person Home Visit'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _lessonFormat.contains('In-Person') ? const Color(0xFF7C3AED) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF7C3AED)),
                      ),
                      child: Center(
                        child: Text(
                          '🏠 In-Person',
                          style: TextStyle(
                            color: _lessonFormat.contains('In-Person') ? Colors.white : const Color(0xFF7C3AED),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Text('Select Time Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _slots.map((slot) {
                  final isSel = _selectedSlot == slot;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSlot = slot),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF7C3AED) : (isDark ? Colors.white10 : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        slot,
                        style: TextStyle(
                          color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),
            const Text('Topic / Goal for Trial Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _topicController,
              decoration: InputDecoration(
                hintText: 'e.g. ECZ G12 Calculus, Past Exam Papers, Speaking French...',
                hintStyle: const TextStyle(fontSize: 12),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isBooking
                    ? null
                    : () async {
                        final nav = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        setState(() => _isBooking = true);
                        await Future.delayed(const Duration(milliseconds: 600));
                        if (!mounted) return;
                        setState(() => _isBooking = false);
                        nav.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF10B981),
                            content: Text('Trial lesson requested with ${widget.tutor.name} for $_selectedSlot!'),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isBooking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Confirm Trial Session (K ${trialFee.toStringAsFixed(0)})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
