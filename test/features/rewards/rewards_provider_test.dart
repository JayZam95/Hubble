import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubble/features/rewards/domain/models/reward_model.dart';
import 'package:hubble/features/rewards/presentation/providers/rewards_provider.dart';

void main() {
  group('TierLevel Enum Tests', () {
    test('TierLevel displayName returns correct tier text', () {
      expect(TierLevel.silver.displayName, 'Silver Member');
      expect(TierLevel.gold.displayName, 'Gold VIP Member');
      expect(TierLevel.platinum.displayName, 'Platinum Elite');
    });
  });

  group('RewardsNotifier Point Calculations & Voucher Redemption Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial rewards state has 1250 starting points and Gold VIP tier', () {
      final state = container.read(rewardsProvider);

      expect(state.currentPoints, 1250);
      expect(state.currentTier, TierLevel.gold);
      expect(state.pointsToNextTier, 1250); // 2500 - 1250
      expect(state.tierProgress, closeTo(0.166, 0.01)); // (1250-1000)/1500
      expect(state.availableVouchers, isNotEmpty);
      expect(state.transactions, isNotEmpty);
    });

    test('addPoints increases points, records earned transaction, and updates tier progress', () {
      final notifier = container.read(rewardsProvider.notifier);

      notifier.addPoints(500, 'Bonus Survey', 'Completed customer feedback survey');

      final state = container.read(rewardsProvider);
      expect(state.currentPoints, 1750); // 1250 + 500
      expect(state.currentTier, TierLevel.gold);
      expect(state.pointsToNextTier, 750); // 2500 - 1750

      final latestTx = state.transactions.first;
      expect(latestTx.title, 'Bonus Survey');
      expect(latestTx.points, 500);
      expect(latestTx.isEarned, isTrue);
    });

    test('addPoints upgrades tier from Gold to Platinum when points reach 2500+', () {
      final notifier = container.read(rewardsProvider.notifier);

      notifier.addPoints(1500, 'Major Booking Milestone', 'Completed 10 service transactions');

      final state = container.read(rewardsProvider);
      expect(state.currentPoints, 2750); // 1250 + 1500
      expect(state.currentTier, TierLevel.platinum);
      expect(state.pointsToNextTier, 2250); // 5000 - 2750
    });

    test('redeemVoucher successfully deducts points, marks voucher redeemed, and logs transaction', () {
      final notifier = container.read(rewardsProvider.notifier);
      final initialState = container.read(rewardsProvider);

      // 'v_escrow_10' costs 350 points
      final voucherId = 'v_escrow_10';
      final voucher = initialState.availableVouchers.firstWhere((v) => v.id == voucherId);
      expect(voucher.pointsCost, 350);

      final success = notifier.redeemVoucher(voucherId);
      expect(success, isTrue);

      final updatedState = container.read(rewardsProvider);
      expect(updatedState.currentPoints, 900); // 1250 - 350
      expect(updatedState.currentTier, TierLevel.silver); // < 1000 points drops tier to Silver

      final redeemedVoucher = updatedState.availableVouchers.firstWhere((v) => v.id == voucherId);
      expect(redeemedVoucher.isRedeemed, isTrue);
      expect(redeemedVoucher.redeemedAt, isNotNull);

      final latestTx = updatedState.transactions.first;
      expect(latestTx.isEarned, isFalse);
      expect(latestTx.points, 350);
      expect(latestTx.title, contains(voucher.title));
    });

    test('redeemVoucher returns false when trying to redeem an already redeemed voucher', () {
      final notifier = container.read(rewardsProvider.notifier);
      final voucherId = 'v_escrow_10';

      // First redemption succeeds
      expect(notifier.redeemVoucher(voucherId), isTrue);

      // Second redemption fails
      expect(notifier.redeemVoucher(voucherId), isFalse);
    });

    test('redeemVoucher returns false when points are insufficient', () {
      final notifier = container.read(rewardsProvider.notifier);

      // 'v_vip_pass' costs 1500 points (initial balance is 1250)
      final voucherId = 'v_vip_pass';

      final success = notifier.redeemVoucher(voucherId);
      expect(success, isFalse);

      final state = container.read(rewardsProvider);
      expect(state.currentPoints, 1250); // Points unchanged
    });

    test('redeemVoucher returns false for non-existent voucher ID', () {
      final notifier = container.read(rewardsProvider.notifier);

      final success = notifier.redeemVoucher('invalid_voucher_id');
      expect(success, isFalse);

      final state = container.read(rewardsProvider);
      expect(state.currentPoints, 1250);
    });
  });
}
