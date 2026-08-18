import 'package:flutter/material.dart';

enum TierLevel {
  silver,
  gold,
  platinum;

  String get displayName {
    switch (this) {
      case TierLevel.silver:
        return 'Silver Member';
      case TierLevel.gold:
        return 'Gold VIP Member';
      case TierLevel.platinum:
        return 'Platinum Elite';
    }
  }

  Color get color {
    switch (this) {
      case TierLevel.silver:
        return const Color(0xFF94A3B8);
      case TierLevel.gold:
        return const Color(0xFFF59E0B);
      case TierLevel.platinum:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData get icon {
    switch (this) {
      case TierLevel.silver:
        return Icons.workspace_premium;
      case TierLevel.gold:
        return Icons.military_tech;
      case TierLevel.platinum:
        return Icons.stars;
    }
  }
}

class RewardVoucher {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final String couponCode;
  final String category; // 'Escrow', 'Bus', 'Marketplace', 'Service'
  final bool isRedeemed;
  final DateTime? redeemedAt;

  RewardVoucher({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.couponCode,
    required this.category,
    this.isRedeemed = false,
    this.redeemedAt,
  });

  RewardVoucher copyWith({
    String? id,
    String? title,
    String? description,
    int? pointsCost,
    String? couponCode,
    String? category,
    bool? isRedeemed,
    DateTime? redeemedAt,
  }) {
    return RewardVoucher(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      pointsCost: pointsCost ?? this.pointsCost,
      couponCode: couponCode ?? this.couponCode,
      category: category ?? this.category,
      isRedeemed: isRedeemed ?? this.isRedeemed,
      redeemedAt: redeemedAt ?? this.redeemedAt,
    );
  }
}

class RewardTransaction {
  final String id;
  final String title;
  final int points;
  final bool isEarned; // true = earned, false = redeemed
  final DateTime date;
  final String description;

  RewardTransaction({
    required this.id,
    required this.title,
    required this.points,
    required this.isEarned,
    required this.date,
    required this.description,
  });
}
