import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/presentation/widgets/hubble_image.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../settings/presentation/screens/manage_listings_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  void _goToSettingsTab() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _showDigitalResumeModal(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
        final prov = user.providerProfile;

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    child: HubbleImage(
                      imagePath: user.personalInfo.profileImageURL,
                      width: 64,
                      height: 64,
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(user.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(
                          prov.professionTitle.isNotEmpty ? prov.professionTitle : 'Hubble Verified Professional',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lusaka, Zambia · Member since ${DateFormat("yyyy").format(user.createdAt)}',
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),
              const Text('EXECUTIVE SUMMARY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.grey)),
              const SizedBox(height: 8),
              Text(
                prov.bio.isNotEmpty ? prov.bio : 'Experienced Zambian professional with verified trade certifications and escrow record.',
                style: const TextStyle(fontSize: 14, height: 1.45),
              ),
              const SizedBox(height: 20),
              const Text('VERIFIED CREDENTIALS & LICENSES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.grey)),
              const SizedBox(height: 10),
              _buildResumeCredentialRow(Icons.verified_user_rounded, 'National KYC Level 2 Verified', 'Government Issued ID Verified'),
              _buildResumeCredentialRow(Icons.workspace_premium_rounded, 'Zambian Engineering & Trade Guild Member', 'Active License 2026'),
              _buildResumeCredentialRow(Icons.shield_outlined, 'Hubble Escrow Protection Verified', '100% Payout Security'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Digital Resume link copied to clipboard! 📋')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  label: const Text('Share Digital CV Card', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResumeCredentialRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.success, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    if (user == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Please log in to view profile.', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    final prov = user.providerProfile;
    final isProviderMode = user.role == UserRole.provider;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 380.0,
              floating: false,
              pinned: true,
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.badge_outlined, color: AppColors.primary),
                  tooltip: 'Digital CV Resume',
                  onPressed: () => _showDigitalResumeModal(user),
                ),
                IconButton(
                  icon: Icon(Icons.settings, color: isDark ? Colors.white : Colors.black87),
                  onPressed: _goToSettingsTab,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Premium Ambient Backdrop Gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF1E293B), AppColors.backgroundDark]
                              : [AppColors.primary.withValues(alpha: 0.12), Colors.white],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),

                    SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          // Avatar Container with verified ring
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 104,
                                height: 104,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: user.personalInfo.isVerified
                                      ? const LinearGradient(colors: [Colors.blue, Colors.cyan])
                                      : AppColors.primaryGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (user.personalInfo.isVerified ? Colors.blue : AppColors.primary).withValues(alpha: 0.35),
                                      blurRadius: 18,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                              ),
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                child: HubbleImage(
                                  imagePath: user.personalInfo.profileImageURL,
                                  width: 92,
                                  height: 92,
                                  borderRadius: BorderRadius.circular(46),
                                ),
                              ),
                              if (user.personalInfo.isVerified)
                                Positioned(
                                  bottom: 0,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check, color: Colors.white, size: 16),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Name & Tagline & Email
                          Text(
                            user.displayName,
                            style: AppTextStyles.heading2.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isProviderMode
                                  ? (prov.professionTitle.isNotEmpty ? prov.professionTitle : 'Hubble Verified Provider')
                                  : 'Client Account',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Performance Metrics Counter Strip
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildHeaderMetric(
                                value: isProviderMode ? prov.ratingAsProvider.toStringAsFixed(1) : user.clientProfile.ratingAsClient.toStringAsFixed(1),
                                label: 'Rating ★',
                                isDark: isDark,
                              ),
                              _buildMetricDivider(isDark),
                              _buildHeaderMetric(
                                value: isProviderMode ? '${prov.totalJobsCompleted}' : '${user.clientProfile.totalBookingsMade}',
                                label: isProviderMode ? 'Jobs Done' : 'Bookings',
                                isDark: isDark,
                              ),
                              _buildMetricDivider(isDark),
                              _buildHeaderMetric(
                                value: '${user.financialLedger.vaultSettings.vaultBalance.toStringAsFixed(0)} ZMW',
                                label: 'Locked Vault',
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: isDark ? Colors.white54 : Colors.grey.shade600,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: 'OVERVIEW'),
                  Tab(text: 'Storefront Catalog'),
                  Tab(text: 'Trust & Badges'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildExecutiveCvTab(user, isDark),
            _buildStorefrontCatalogTab(user, isDark),
            _buildTrustBadgesTab(user, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderMetric({required String value, required String label, required bool isDark}) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMetricDivider(bool isDark) {
    return Container(
      height: 24,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: isDark ? Colors.white24 : Colors.black12,
    );
  }

  // ================= TAB 1: EXECUTIVE RESUME & CV =================
  Widget _buildExecutiveCvTab(UserModel user, bool isDark) {
    final prov = user.providerProfile;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;

    final defaultSkills = prov.skills.isNotEmpty
        ? prov.skills
        : ['Solar Installation', 'Electrical Wiring', '3-Phase Audit', 'Fault Diagnosis', 'Safety Compliance'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Professional Summary Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Executive Bio & Mission', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Icon(Icons.assignment_ind_rounded, color: AppColors.primary, size: 20),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  prov.bio.isNotEmpty
                      ? prov.bio
                      : 'Dedicated professional offering high quality service, transparent escrow pricing, and on-time job delivery across Lusaka and copperbelt region.',
                  style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? Colors.white70 : Colors.black87),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Verified Skills & Endorsements
          const Text('COMPETENCIES & ENDORSED SKILLS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: defaultSkills.map((skill) {
                return Chip(
                  avatar: const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.check, size: 12, color: Colors.white)),
                  label: Text(skill, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Work History Timeline
          const Text('CAREER HISTORY & COMPLETED PROJECTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                _buildTimelineTile(
                  title: 'Lead Contractor / Senior Specialist',
                  organization: 'Hubble Escrow Marketplace',
                  period: '2024 - Present',
                  description: 'Completed 48+ verified client orders with 99% satisfaction rate.',
                  isDark: isDark,
                  isLast: false,
                ),
                _buildTimelineTile(
                  title: 'Certified Apprentice & Trade Master',
                  organization: 'Lusaka Trade & Vocational Guild',
                  period: '2020 - 2024',
                  description: 'Supervised industrial installations, residential maintenance, and safety audits.',
                  isDark: isDark,
                  isLast: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildTimelineTile({
    required String title,
    required String organization,
    required String period,
    required String description,
    required bool isDark,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text('$organization · $period', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(description, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87, height: 1.35)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  // ================= TAB 2: STOREFRONT CATALOG =================
  Widget _buildStorefrontCatalogTab(UserModel user, bool isDark) {
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ACTIVE STOREFRONT ITEMS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.grey)),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManageListingsScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.edit_note_rounded, size: 16),
                label: const Text('Manage Catalog', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                const Icon(Icons.storefront_rounded, size: 48, color: AppColors.primary),
                const SizedBox(height: 12),
                Text(
                  'Manage products & services published under ${user.displayName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 6),
                const Text(
                  'All published items receive Escrow payment protection & mobile money checkout.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.35),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ManageListingsScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Open Catalog Manager', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAB 3: TRUST & BADGES =================
  Widget _buildTrustBadgesTab(UserModel user, bool isDark) {
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: user.personalInfo.isVerified ? Colors.blue.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    user.personalInfo.isVerified ? Icons.verified_rounded : Icons.pending_rounded,
                    color: user.personalInfo.isVerified ? Colors.blue : Colors.orange,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.personalInfo.isVerified ? 'Government Verified Identity' : 'KYC Verification Pending',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.personalInfo.isVerified ? 'National ID verified. Access to direct payouts enabled.' : 'Submit ID card to earn verified checkmark badge.',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('MARKETPLACE TRUST BADGES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.grey)),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _buildBadgeItem(Icons.verified_rounded, 'National ID', 'Government ID verified', true, Colors.blue, cardColor),
              _buildBadgeItem(Icons.lock_rounded, 'Escrow Safe', '100% Payment Guarantee', true, AppColors.success, cardColor),
              _buildBadgeItem(Icons.star_rounded, 'Top Rated', '4.8+ Client rating', true, Colors.amber, cardColor),
              _buildBadgeItem(Icons.handyman_rounded, 'Certified Trade', 'Zambian Guild Member', true, Colors.purple, cardColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(IconData icon, String title, String subtitle, bool isActive, Color color, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
