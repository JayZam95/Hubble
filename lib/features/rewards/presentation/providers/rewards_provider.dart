import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/reward_model.dart';

class RewardsState {
  final int currentPoints;
  final TierLevel currentTier;
  final int pointsToNextTier;
  final double tierProgress;
  final List<RewardVoucher> availableVouchers;
  final List<RewardTransaction> transactions;

  RewardsState({
    required this.currentPoints,
    required this.currentTier,
    required this.pointsToNextTier,
    required this.tierProgress,
    required this.availableVouchers,
    required this.transactions,
  });

  RewardsState copyWith({
    int? currentPoints,
    TierLevel? currentTier,
    int? pointsToNextTier,
    double? tierProgress,
    List<RewardVoucher>? availableVouchers,
    List<RewardTransaction>? transactions,
  }) {
    return RewardsState(
      currentPoints: currentPoints ?? this.currentPoints,
      currentTier: currentTier ?? this.currentTier,
      pointsToNextTier: pointsToNextTier ?? this.pointsToNextTier,
      tierProgress: tierProgress ?? this.tierProgress,
      availableVouchers: availableVouchers ?? this.availableVouchers,
      transactions: transactions ?? this.transactions,
    );
  }
}

class RewardsNotifier extends Notifier<RewardsState> {
  @override
  RewardsState build() {
    return _initialState();
  }

  static RewardsState _initialState() {
    const points = 1250; // Requested starting points
    final tier = _calculateTier(points);
    final nextTarget = _nextTierTarget(tier);
    final progress = _calculateProgress(points, tier);

    return RewardsState(
      currentPoints: points,
      currentTier: tier,
      pointsToNextTier: nextTarget - points,
      tierProgress: progress,
      availableVouchers: [
        RewardVoucher(
          id: 'v_escrow_10',
          title: r'$10 Off Escrow Fee',
          description: 'Waive up to K200 in escrow platform protection fees on any service booking.',
          pointsCost: 350,
          couponCode: 'HUBBLE10ESCROW',
          category: 'Escrow',
        ),
        RewardVoucher(
          id: 'v_bus_15',
          title: '15% Off Bus Ticket',
          description: 'Get 15% discount on inter-city bus bookings (Power Tools & Mazhandu).',
          pointsCost: 500,
          couponCode: 'HUBBLEBUS15',
          category: 'Bus',
        ),
        RewardVoucher(
          id: 'v_delivery_free',
          title: 'Free Express Delivery',
          description: 'Free courier delivery on all marketplace products bought in Lusaka & Kitwe.',
          pointsCost: 400,
          couponCode: 'FREESHIPHUBBLE',
          category: 'Marketplace',
        ),
        RewardVoucher(
          id: 'v_service_50',
          title: 'K50 Discount on Home Repairs',
          description: 'Save K50 when hiring any verified electrician or plumber.',
          pointsCost: 600,
          couponCode: 'HOMEK50SAVE',
          category: 'Service',
        ),
        RewardVoucher(
          id: 'v_vip_pass',
          title: 'Platinum VIP Priority Badge',
          description: 'Boost your provider listing to top search results for 7 days.',
          pointsCost: 1500,
          couponCode: 'PLATINUMBOOST',
          category: 'Service',
        ),
      ],
      transactions: [
        RewardTransaction(
          id: 'tx_1',
          title: 'Verified Gov National ID',
          points: 300,
          isEarned: true,
          date: DateTime.now().subtract(const Duration(days: 2)),
          description: 'Bonus points for completing KYC identity verification.',
        ),
        RewardTransaction(
          id: 'tx_2',
          title: 'Completed Plumbing Booking',
          points: 450,
          isEarned: true,
          date: DateTime.now().subtract(const Duration(days: 5)),
          description: 'Earned 10% back on completed booking escrow payout.',
        ),
        RewardTransaction(
          id: 'tx_3',
          title: 'Welcome Loyalty Bonus',
          points: 500,
          isEarned: true,
          date: DateTime.now().subtract(const Duration(days: 10)),
          description: 'New account setup bonus reward.',
        ),
      ],
    );
  }

  static TierLevel _calculateTier(int points) {
    if (points >= 2500) return TierLevel.platinum;
    if (points >= 1000) return TierLevel.gold;
    return TierLevel.silver;
  }

  static int _nextTierTarget(TierLevel tier) {
    switch (tier) {
      case TierLevel.silver:
        return 1000;
      case TierLevel.gold:
        return 2500;
      case TierLevel.platinum:
        return 5000;
    }
  }

  static double _calculateProgress(int points, TierLevel tier) {
    if (tier == TierLevel.silver) {
      return (points / 1000).clamp(0.0, 1.0);
    } else if (tier == TierLevel.gold) {
      return ((points - 1000) / 1500).clamp(0.0, 1.0);
    } else {
      return ((points - 2500) / 2500).clamp(0.0, 1.0);
    }
  }

  bool redeemVoucher(String voucherId) {
    final index = state.availableVouchers.indexWhere((v) => v.id == voucherId);
    if (index == -1) return false;

    final voucher = state.availableVouchers[index];
    if (voucher.isRedeemed) return false;
    if (state.currentPoints < voucher.pointsCost) return false;

    final newPoints = state.currentPoints - voucher.pointsCost;
    final updatedVouchers = List<RewardVoucher>.from(state.availableVouchers);
    updatedVouchers[index] = voucher.copyWith(
      isRedeemed: true,
      redeemedAt: DateTime.now(),
    );

    final newTx = RewardTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Redeemed: ${voucher.title}',
      points: voucher.pointsCost,
      isEarned: false,
      date: DateTime.now(),
      description: 'Claimed coupon code: ${voucher.couponCode}',
    );

    final newTier = _calculateTier(newPoints);
    final nextTarget = _nextTierTarget(newTier);
    final progress = _calculateProgress(newPoints, newTier);

    state = state.copyWith(
      currentPoints: newPoints,
      currentTier: newTier,
      pointsToNextTier: nextTarget - newPoints,
      tierProgress: progress,
      availableVouchers: updatedVouchers,
      transactions: [newTx, ...state.transactions],
    );

    return true;
  }

  void addPoints(int points, String title, String description) {
    final newPoints = state.currentPoints + points;
    final newTier = _calculateTier(newPoints);
    final nextTarget = _nextTierTarget(newTier);
    final progress = _calculateProgress(newPoints, newTier);

    final newTx = RewardTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      points: points,
      isEarned: true,
      date: DateTime.now(),
      description: description,
    );

    state = state.copyWith(
      currentPoints: newPoints,
      currentTier: newTier,
      pointsToNextTier: nextTarget - newPoints,
      tierProgress: progress,
      transactions: [newTx, ...state.transactions],
    );
  }
}

final rewardsProvider =
    NotifierProvider<RewardsNotifier, RewardsState>(RewardsNotifier.new);
