import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';

/// Reusable Shimmer loading placeholders for Hubble UI.
/// Supports dark and light themes automatically.

class ShimmerCard extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerCard({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 16.0,
    this.margin,
    this.padding,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBase = isDark ? const Color(0xFF1E293B) : Colors.grey[300]!;
    final defaultHighlight = isDark ? const Color(0xFF334155) : Colors.grey[100]!;

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      child: Shimmer.fromColors(
        baseColor: baseColor ?? defaultBase,
        highlightColor: highlightColor ?? defaultHighlight,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgDarkCard : Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}

class ShimmerListTile extends StatelessWidget {
  final bool hasLeading;
  final double leadingSize;
  final bool leadingIsCircle;
  final double titleHeight;
  final double subtitleHeight;
  final bool hasTrailing;
  final EdgeInsetsGeometry? padding;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerListTile({
    super.key,
    this.hasLeading = true,
    this.leadingSize = 48.0,
    this.leadingIsCircle = true,
    this.titleHeight = 16.0,
    this.subtitleHeight = 12.0,
    this.hasTrailing = false,
    this.padding,
    this.baseColor,
    this.highlightColor,
  });

  /// Convenience factory for a vertical list of shimmer tiles.
  static Widget list({
    int itemCount = 5,
    EdgeInsetsGeometry? padding,
  }) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding ?? const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ShimmerListTile(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBase = isDark ? const Color(0xFF1E293B) : Colors.grey[300]!;
    final defaultHighlight = isDark ? const Color(0xFF334155) : Colors.grey[100]!;

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 8.0),
      child: Shimmer.fromColors(
        baseColor: baseColor ?? defaultBase,
        highlightColor: highlightColor ?? defaultHighlight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (hasLeading) ...[
              Container(
                width: leadingSize,
                height: leadingSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: leadingIsCircle ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: leadingIsCircle ? null : BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: titleHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 140,
                    height: subtitleHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            if (hasTrailing) ...[
              const SizedBox(width: 16),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ShimmerGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Color? baseColor;
  final Color? highlightColor;
  final double cardBorderRadius;

  const ShimmerGrid({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.8,
    this.crossAxisSpacing = 16.0,
    this.mainAxisSpacing = 16.0,
    this.padding,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
    this.baseColor,
    this.highlightColor,
    this.cardBorderRadius = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBase = isDark ? const Color(0xFF1E293B) : Colors.grey[300]!;
    final defaultHighlight = isDark ? const Color(0xFF334155) : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor ?? defaultBase,
      highlightColor: highlightColor ?? defaultHighlight,
      child: GridView.builder(
        shrinkWrap: shrinkWrap,
        physics: physics,
        padding: padding ?? const EdgeInsets.all(16.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgDarkCard : Colors.white,
              borderRadius: BorderRadius.circular(cardBorderRadius),
            ),
          );
        },
      ),
    );
  }
}

/// Legacy compatibility classes for existing screens
class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerGrid(
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.0,
      itemCount: 6,
      cardBorderRadius: 16,
    );
  }
}

class ShimmerListLoading extends StatelessWidget {
  const ShimmerListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerListTile.list(itemCount: 5);
  }
}
