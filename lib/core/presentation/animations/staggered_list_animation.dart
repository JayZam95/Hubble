import 'package:flutter/material.dart';
import 'fade_slide_transition.dart';

/// Staggered cascading entrance animation for lists, columns, or feeds.
/// Children smoothly cascade into view with progressive delays.
class StaggeredListAnimation extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration baseDuration;
  final Duration delayStep;
  final Duration initialDelay;
  final SlideDirection direction;
  final double distance;
  final Curve curve;

  const StaggeredListAnimation({
    super.key,
    required this.index,
    required this.child,
    this.baseDuration = const Duration(milliseconds: 380),
    this.delayStep = const Duration(milliseconds: 40),
    this.initialDelay = Duration.zero,
    this.direction = SlideDirection.fromBottom,
    this.distance = 20.0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    // Cap stagger index delay to prevent long delays on deep scroll items
    final effectiveIndex = index.clamp(0, 12);
    final delay = initialDelay + (delayStep * effectiveIndex);

    return FadeSlideTransition(
      delay: delay,
      duration: baseDuration,
      direction: direction,
      distance: distance,
      curve: curve,
      child: child,
    );
  }
}

/// Convenience Column that automatically animates its children in a staggered sequence
class StaggeredColumn extends StatelessWidget {
  final List<Widget> children;
  final Duration delayStep;
  final Duration initialDelay;
  final Duration itemDuration;
  final SlideDirection direction;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;

  const StaggeredColumn({
    super.key,
    required this.children,
    this.delayStep = const Duration(milliseconds: 45),
    this.initialDelay = Duration.zero,
    this.itemDuration = const Duration(milliseconds: 360),
    this.direction = SlideDirection.fromBottom,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: List.generate(children.length, (index) {
        return StaggeredListAnimation(
          index: index,
          delayStep: delayStep,
          initialDelay: initialDelay,
          baseDuration: itemDuration,
          direction: direction,
          child: children[index],
        );
      }),
    );
  }
}

/// Convenience Row that automatically animates its children horizontally in a staggered sequence
class StaggeredRow extends StatelessWidget {
  final List<Widget> children;
  final Duration delayStep;
  final Duration initialDelay;
  final Duration itemDuration;
  final SlideDirection direction;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;

  const StaggeredRow({
    super.key,
    required this.children,
    this.delayStep = const Duration(milliseconds: 40),
    this.initialDelay = Duration.zero,
    this.itemDuration = const Duration(milliseconds: 340),
    this.direction = SlideDirection.fromRight,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: List.generate(children.length, (index) {
        return StaggeredListAnimation(
          index: index,
          delayStep: delayStep,
          initialDelay: initialDelay,
          baseDuration: itemDuration,
          direction: direction,
          child: children[index],
        );
      }),
    );
  }
}
