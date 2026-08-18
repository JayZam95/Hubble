import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/reward_model.dart';
import '../providers/rewards_provider.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> with SingleTickerProviderStateMixin {
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

  void _redeemVoucher(RewardVoucher voucher) {
    final success = ref.read(rewardsProvider.notifier).redeemVoucher(voucher.id);

    if (success) {
      HapticFeedback.heavyImpact();
      _showRedeemedDialog(voucher);
    } else {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient points to redeem this voucher!'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showRedeemedDialog(RewardVoucher voucher) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 50),
              SizedBox(height: 10),
              Text('Voucher Redeemed!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You unlocked ${voucher.title}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      voucher.couponCode,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.5,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20, color: AppColors.primary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: voucher.couponCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Coupon code copied to clipboard!'), duration: Duration(seconds: 1)),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Apply this promo code at checkout for bookings or marketplace purchases.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Awesome'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rewardsState = ref.watch(rewardsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        title: Text(
          'Loyalty & Rewards',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Points Banner Header
            _buildPointsHeaderCard(rewardsState, isDark),

            // Tab Bar
            Container(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'REDEEM VOUCHERS'),
                  Tab(text: 'REWARD TIERS'),
                  Tab(text: 'HISTORY'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRedeemTab(rewardsState, isDark),
                  _buildTiersTab(rewardsState, isDark),
                  _buildHistoryTab(rewardsState, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsHeaderCard(RewardsState state, bool isDark) {
    final tier = state.currentTier;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tier.color,
            tier.color.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: tier.color.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(tier.icon, color: Colors.white, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    tier.displayName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.stars_rounded, color: Colors.amber, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Hubble Perks',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${NumberFormat('#,###').format(state.currentPoints)} PTS',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            state.pointsToNextTier > 0
                ? '${state.pointsToNextTier} PTS until next VIP Tier'
                : 'Highest Tier Unlocked! Platinum Elite Status',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
          ),
          const SizedBox(height: 12),
          // Tier Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: state.tierProgress,
              minHeight: 8,
              backgroundColor: Colors.black.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedeemTab(RewardsState state, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.availableVouchers.length,
      itemBuilder: (context, index) {
        final voucher = state.availableVouchers[index];
        final canRedeem = state.currentPoints >= voucher.pointsCost && !voucher.isRedeemed;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgDarkCard : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        voucher.category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${voucher.pointsCost} PTS',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  voucher.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  voucher.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (voucher.isRedeemed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Code: ${voucher.couponCode}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      Text(
                        'Promo: ${voucher.couponCode}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: voucher.isRedeemed
                            ? Colors.grey
                            : (canRedeem ? AppColors.primary : Colors.grey.shade400),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                      onPressed: canRedeem ? () => _redeemVoucher(voucher) : null,
                      child: Text(
                        voucher.isRedeemed ? 'Redeemed' : 'Redeem Now',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTiersTab(RewardsState state, bool isDark) {
    final tiers = [
      {
        'tier': TierLevel.silver,
        'points': '0 - 999 PTS',
        'perks': [
          'Earn 5% points on all booking escrows',
          'Standard customer service support',
          'Access to basic promo vouchers',
        ],
      },
      {
        'tier': TierLevel.gold,
        'points': '1,000 - 2,499 PTS',
        'perks': [
          'Earn 10% points on all booking escrows',
          '0% Mobile money withdrawal fee',
          'Priority escrow dispute support',
          'Exclusive bus travel discounts',
        ],
      },
      {
        'tier': TierLevel.platinum,
        'points': '2,500+ PTS',
        'perks': [
          'Earn 15% points on all booking escrows',
          'Free listing boost for storefront sellers',
          'Dedicated VIP account manager',
          '100% platform fee waivers on select services',
        ],
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tiers.length,
      itemBuilder: (context, index) {
        final item = tiers[index];
        final tierLevel = item['tier'] as TierLevel;
        final isCurrent = state.currentTier == tierLevel;
        final perks = item['perks'] as List<String>;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgDarkCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isCurrent ? Border.all(color: tierLevel.color, width: 2) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(tierLevel.icon, color: tierLevel.color, size: 26),
                        const SizedBox(width: 10),
                        Text(
                          tierLevel.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: tierLevel.color,
                          ),
                        ),
                      ],
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: tierLevel.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'YOUR TIER',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item['points'] as String,
                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Divider(color: isDark ? Colors.white10 : Colors.black12),
                const SizedBox(height: 8),
                ...perks.map((perk) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: tierLevel.color, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            perk,
                            style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab(RewardsState state, bool isDark) {
    if (state.transactions.isEmpty) {
      return const Center(
        child: Text('No reward transactions yet.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.transactions.length,
      separatorBuilder: (_, _) => Divider(color: isDark ? Colors.white10 : Colors.black12),
      itemBuilder: (context, index) {
        final tx = state.transactions[index];
        final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(tx.date);

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (tx.isEarned ? AppColors.success : AppColors.error).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              tx.isEarned ? Icons.add_circle_outline : Icons.remove_circle_outline,
              color: tx.isEarned ? AppColors.success : AppColors.error,
              size: 20,
            ),
          ),
          title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(
            '${tx.description}\n$dateStr',
            style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.3),
          ),
          trailing: Text(
            '${tx.isEarned ? '+' : '-'}${tx.points} PTS',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: tx.isEarned ? AppColors.success : AppColors.error,
            ),
          ),
        );
      },
    );
  }
}
