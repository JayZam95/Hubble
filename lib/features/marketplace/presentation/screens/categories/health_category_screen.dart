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

class MedicalPractitionerItem {
  final String id;
  final String name;
  final String avatarUrl;
  final String specialtyTitle;
  final String specialty; // General Practice, Pediatrics, Dentistry, Optometry, Mental Health, Physiotherapy
  final double teleConsultFee;
  final double clinicVisitFee;
  final double rating;
  final int patientReviews;
  final bool isHpczVerified;
  final String clinicName;
  final String location;
  final String nextAvailableSlot;
  final String qualifications;
  final String bio;

  const MedicalPractitionerItem({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.specialtyTitle,
    required this.specialty,
    required this.teleConsultFee,
    required this.clinicVisitFee,
    required this.rating,
    required this.patientReviews,
    required this.isHpczVerified,
    required this.clinicName,
    required this.location,
    required this.nextAvailableSlot,
    required this.qualifications,
    required this.bio,
  });
}

class HealthCategoryScreen extends ConsumerStatefulWidget {
  const HealthCategoryScreen({super.key});

  @override
  ConsumerState<HealthCategoryScreen> createState() => _HealthCategoryScreenState();
}

class _HealthCategoryScreenState extends ConsumerState<HealthCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSpecialty = 'All Specialties';
  String _selectedConsultMode = 'All Modes'; // All Modes, Tele-Consult Only, Clinic Visit Only

  final List<String> _specialties = [
    'All Specialties',
    'General Practice',
    'Pediatrics',
    'Dentistry',
    'Optometry',
    'Mental Health',
    'Physiotherapy',
    'Nutrition',
  ];

  final List<MedicalPractitionerItem> _mockPractitioners = const [
    MedicalPractitionerItem(
      id: 'doc_1',
      name: 'Dr. Joseph Tembo, MD',
      avatarUrl: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?fit=crop&w=300&q=80',
      specialtyTitle: 'Senior General Physician & Diagnostics',
      specialty: 'General Practice',
      teleConsultFee: 150.0,
      clinicVisitFee: 300.0,
      rating: 4.95,
      patientReviews: 124,
      isHpczVerified: true,
      clinicName: 'Woodlands Medical & Wellness Centre',
      location: 'Woodlands, Lusaka',
      nextAvailableSlot: '🟢 Today at 14:30',
      qualifications: 'MBChB (UNZA), MMed Internal Medicine',
      bio: 'Over 12 years diagnosing chronic illnesses, hypertension, malaria treatments, and holistic preventive medicine.',
    ),
    MedicalPractitionerItem(
      id: 'doc_2',
      name: 'Dr. Mwamba Chilufya',
      avatarUrl: 'https://images.unsplash.com/photo-1594824813629-a1b7e41cf7e9?fit=crop&w=300&q=80',
      specialtyTitle: 'Consultant Pediatrician & Child Health',
      specialty: 'Pediatrics',
      teleConsultFee: 180.0,
      clinicVisitFee: 350.0,
      rating: 5.0,
      patientReviews: 98,
      isHpczVerified: true,
      clinicName: 'Little Smiles Pediatric Clinic',
      location: 'Rhodespark, Lusaka',
      nextAvailableSlot: '🟢 Today at 16:00',
      qualifications: 'MBChB, DCH, Fellow College of Pediatrics',
      bio: 'Dedicated child health expert providing infant care, growth tracking, childhood immunizations, and asthma care.',
    ),
    MedicalPractitionerItem(
      id: 'doc_3',
      name: 'Dr. Natasha Banda, BDS',
      avatarUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?fit=crop&w=300&q=80',
      specialtyTitle: 'Dental Surgeon & Aesthetic Dentistry',
      specialty: 'Dentistry',
      teleConsultFee: 120.0,
      clinicVisitFee: 400.0,
      rating: 4.9,
      patientReviews: 87,
      isHpczVerified: true,
      clinicName: 'Pearl Dental Care Hub',
      location: 'Kabulonga, Lusaka',
      nextAvailableSlot: 'Tomorrow at 10:00 AM',
      qualifications: 'Bachelor of Dental Surgery (BDS), HPCZ Reg.',
      bio: 'Gentle dental fillings, root canals, professional teeth whitening, scaling, and pediatric dental hygiene.',
    ),
    MedicalPractitionerItem(
      id: 'doc_4',
      name: 'Dr. Kelvin Chanda, OD',
      avatarUrl: 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?fit=crop&w=300&q=80',
      specialtyTitle: 'Optometrist & Vision Care Specialist',
      specialty: 'Optometry',
      teleConsultFee: 100.0,
      clinicVisitFee: 250.0,
      rating: 4.85,
      patientReviews: 64,
      isHpczVerified: true,
      clinicName: 'VisionClear Eye & Optical Clinic',
      location: 'Roma Park, Lusaka',
      nextAvailableSlot: '🟢 Today at 15:00',
      qualifications: 'Doctor of Optometry (OD), WCO Member',
      bio: 'Comprehensive eye exams, glaucoma screening, prescription glasses fitting, and computer eye strain solutions.',
    ),
    MedicalPractitionerItem(
      id: 'doc_5',
      name: 'Chileshe Mwanza, MPsych',
      avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?fit=crop&w=300&q=80',
      specialtyTitle: 'Clinical Psychologist & Mental Health Coach',
      specialty: 'Mental Health',
      teleConsultFee: 200.0,
      clinicVisitFee: 320.0,
      rating: 5.0,
      patientReviews: 110,
      isHpczVerified: true,
      clinicName: 'MindCare Therapy & Counseling',
      location: 'Mass Media, Lusaka',
      nextAvailableSlot: '🟢 Today at 17:30',
      qualifications: 'MSc. Clinical Psychology, Cognitive Behavioral Therapy Certified',
      bio: 'Compassionate, confidential therapy for anxiety, depression, burnout, relationship counseling, and trauma recovery.',
    ),
    MedicalPractitionerItem(
      id: 'doc_6',
      name: 'Patrick Mwila, PT',
      avatarUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?fit=crop&w=300&q=80',
      specialtyTitle: 'Physiotherapist & Sports Injury Rehab',
      specialty: 'Physiotherapy',
      teleConsultFee: 140.0,
      clinicVisitFee: 280.0,
      rating: 4.85,
      patientReviews: 53,
      isHpczVerified: true,
      clinicName: 'ActiveLife Physical Therapy Centre',
      location: 'Lusaka CBD',
      nextAvailableSlot: 'Tomorrow at 09:00 AM',
      qualifications: 'BSc. Physiotherapy, Sports Medicine Diploma',
      bio: 'Post-surgery recovery, spinal disc therapy, back pain relief, and athletic conditioning.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openConsultBooking(BuildContext context, MedicalPractitionerItem doc, String defaultMode) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MedicalConsultBookingSheet(doctor: doc, defaultMode: defaultMode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    const tealTheme = Color(0xFF0D9488); // Teal 600

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
          'Health & Consultations',
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Hero Banner ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D9488), Color(0xFF059669), Color(0xFF0284C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.35),
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
                            child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'HPCZ Licensed Doctors & Specialists',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Instant Video Calls & In-Clinic Appointments',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Tele-consult Highlight
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.videocam_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tele-Consultation starts from only K 100 with e-Prescription',
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 2. Mode Selector (Tele vs Clinic vs All) ────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _buildModeTab('All Modes', '✨ All Modes', isDark),
                      _buildModeTab('Tele-Consult Only', '📹 Tele-Consult', isDark),
                      _buildModeTab('Clinic Visit Only', '🏥 Clinic Visit', isDark),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── 3. Search Bar ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Search doctors, pediatricians, dentists, symptoms...',
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: tealTheme),
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
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── 4. Specialties Filter Chips ────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: _specialties.map((spec) {
                    final isSel = _selectedSpecialty == spec;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedSpecialty = spec);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? tealTheme : cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSel ? tealTheme : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Text(
                          spec,
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

              const SizedBox(height: 20),

              // ── 5. Doctors & Medical Feed ──────────────────────────────────
              allListingsAsync.when(
                data: (listings) {
                  // Filter live marketplace listings
                  final healthListings = listings.where((l) {
                    final cat = l.category.toLowerCase();
                    return cat.contains('health') || cat.contains('medic') || cat.contains('doctor') || cat.contains('clinic');
                  }).toList();

                  // Filter mock doctors
                  final filteredDocs = _mockPractitioners.where((doc) {
                    if (_selectedSpecialty != 'All Specialties' && !doc.specialty.toLowerCase().contains(_selectedSpecialty.toLowerCase())) {
                      return false;
                    }
                    if (_searchQuery.isNotEmpty) {
                      final matchName = doc.name.toLowerCase().contains(_searchQuery);
                      final matchSpec = doc.specialtyTitle.toLowerCase().contains(_searchQuery);
                      final matchBio = doc.bio.toLowerCase().contains(_searchQuery);
                      final matchClinic = doc.clinicName.toLowerCase().contains(_searchQuery);
                      if (!matchName && !matchSpec && !matchBio && !matchClinic) return false;
                    }
                    return true;
                  }).toList();

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Verified Practitioners (${filteredDocs.length + healthListings.length})',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const Row(
                              children: [
                                Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
                                SizedBox(width: 4),
                                Text(
                                  'HPCZ Licensed',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Live marketplace listings
                        if (healthListings.isNotEmpty) ...[
                          ...healthListings.map((l) => _buildLiveListingCard(context, l, isDark, cardColor, tealTheme)),
                          const SizedBox(height: 8),
                        ],

                        if (filteredDocs.isEmpty && healthListings.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: AnimatedEmptyState(
                              icon: Icons.health_and_safety_outlined,
                              title: 'No Doctors Found for Specialty',
                              subtitle: 'Try switching to "All Specialties" or searching another symptom.',
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredDocs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final doc = filteredDocs[index];
                              return _buildDoctorCard(context, doc, isDark, cardColor, tealTheme);
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
                  child: Text('Error loading health practitioners: $e'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeTab(String type, String label, bool isDark) {
    final isSel = _selectedConsultMode == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedConsultMode = type);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFF0D9488) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSel ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(
    BuildContext context,
    MedicalPractitionerItem doc,
    bool isDark,
    Color cardColor,
    Color tealTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: tealTheme.withValues(alpha: 0.1),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: HubbleImage(
                        imagePath: doc.avatarUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (doc.isHpczVerified)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF10B981)),
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
                            doc.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doc.specialtyTitle,
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          '${doc.rating} (${doc.patientReviews} reviews)',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            doc.nextAvailableSlot,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Clinic & Qualifications Box
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
                    const Icon(Icons.local_hospital_outlined, size: 14, color: Color(0xFF0D9488)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${doc.clinicName} • ${doc.location}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  doc.bio,
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Consultation Fee Badges
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('📹 Tele-call', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                      Text(
                        'K ${doc.teleConsultFee.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0284C7)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('🏥 In-Clinic', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                      Text(
                        'K ${doc.clinicVisitFee.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Action Buttons: Tele-Consult vs Clinic Visit
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openConsultBooking(context, doc, 'Tele-consultation (Video)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.videocam_rounded, size: 16),
                  label: const Text('Start Video Call', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openConsultBooking(context, doc, 'In-Clinic Appointment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tealTheme,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.calendar_month_rounded, size: 16),
                  label: const Text('Book Clinic Visit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
    Color tealTheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tealTheme.withValues(alpha: 0.3)),
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
                          color: tealTheme.withValues(alpha: 0.15),
                          child: Icon(Icons.health_and_safety_rounded, color: tealTheme, size: 30),
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
                    Text('by ${listing.providerName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      'K ${listing.price.toStringAsFixed(0)} / ${listing.billingType.name}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
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
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: listing)));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tealTheme,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.calendar_month_rounded, size: 16),
                  label: const Text('Book Consultation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MedicalConsultBookingSheet extends StatefulWidget {
  final MedicalPractitionerItem doctor;
  final String defaultMode;

  const _MedicalConsultBookingSheet({
    required this.doctor,
    required this.defaultMode,
  });

  @override
  State<_MedicalConsultBookingSheet> createState() => _MedicalConsultBookingSheetState();
}

class _MedicalConsultBookingSheetState extends State<_MedicalConsultBookingSheet> {
  late String _mode;
  String _selectedSlot = 'Today 15:30 PM';
  final TextEditingController _symptomsController = TextEditingController();
  bool _isConfirming = false;

  final List<String> _slots = [
    'Today 15:30 PM',
    'Today 17:00 PM',
    'Tomorrow 09:30 AM',
    'Tomorrow 11:00 AM',
    'Tomorrow 14:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _mode = widget.defaultMode;
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTele = _mode.contains('Tele');
    final fee = isTele ? widget.doctor.teleConsultFee : widget.doctor.clinicVisitFee;

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
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.health_and_safety_rounded, color: Color(0xFF0D9488), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book ${widget.doctor.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        widget.doctor.specialtyTitle,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Consultation Mode Switcher
            const Text('Consultation Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _mode = 'Tele-consultation (Video)'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isTele ? const Color(0xFF0284C7) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF0284C7)),
                      ),
                      child: Center(
                        child: Text(
                          '📹 Tele-Video (K ${widget.doctor.teleConsultFee.toStringAsFixed(0)})',
                          style: TextStyle(
                            color: isTele ? Colors.white : const Color(0xFF0284C7),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _mode = 'In-Clinic Appointment'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !isTele ? const Color(0xFF0D9488) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF0D9488)),
                      ),
                      child: Center(
                        child: Text(
                          '🏥 Clinic Visit (K ${widget.doctor.clinicVisitFee.toStringAsFixed(0)})',
                          style: TextStyle(
                            color: !isTele ? Colors.white : const Color(0xFF0D9488),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
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
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF0D9488) : (isDark ? Colors.white10 : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        slot,
                        style: TextStyle(
                          color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),
            const Text('Symptoms / Reason for Consultation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _symptomsController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. Mild fever for 2 days, persistent toothache, prescription renewal...',
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
                onPressed: _isConfirming
                    ? null
                    : () async {
                        final nav = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        setState(() => _isConfirming = true);
                        await Future.delayed(const Duration(milliseconds: 600));
                        if (!mounted) return;
                        setState(() => _isConfirming = false);
                        nav.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF10B981),
                            content: Text('Consultation booked with ${widget.doctor.name} for $_selectedSlot!'),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isConfirming
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Confirm & Pay (K ${fee.toStringAsFixed(0)})',
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
