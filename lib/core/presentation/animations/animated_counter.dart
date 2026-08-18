import 'package:flutter/material.dart';

/// Smooth numeric counting animation for financial balances, ratings, and stats.
class AnimatedCounter extends StatelessWidget {
  final num value;
  final Duration duration;
  final Curve curve;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final int decimalPlaces;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.decimalPlaces = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, val, child) {
        final formattedValue = decimalPlaces > 0
            ? val.toStringAsFixed(decimalPlaces)
            : val.round().toString();
        return Text(
          '$prefix$formattedValue$suffix',
          style: style,
        );
      },
    );
  }
}

/// Animated notification / count badge that pops in smoothly when value changes
class AnimatedBadgeCount extends StatelessWidget {
  final int count;
  final Color backgroundColor;
  final Color textColor;
  final double size;
  final TextStyle? textStyle;

  const AnimatedBadgeCount({
    super.key,
    required this.count,
    this.backgroundColor = const Color(0xFFEF4444),
    this.textColor = Colors.white,
    this.size = 20.0,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final displayText = count > 99 ? '99+' : count.toString();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            constraints: BoxConstraints(
              minWidth: size,
              minHeight: size,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(size / 2),
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                displayText,
                style: textStyle ??
                    TextStyle(
                      color: textColor,
                      fontSize: size * 0.55,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
              ),
            ),
          ),
        );
      },
    );
  }
}
