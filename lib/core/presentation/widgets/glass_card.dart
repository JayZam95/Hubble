import 'dart:ui';
import 'package:flutter/material.dart';
import '../animations/bouncing_button.dart';

/// Reusable glassmorphic card widget for Hubble UI.
/// Provides customizable backdrop blur, border gradient, background opacity, padding,
/// and smooth bouncy micro-interactions on tap.
class GlassCard extends StatelessWidget {
  final Widget? child;
  final double blur;
  final double? opacity;
  final Color? backgroundColor;
  final Gradient? borderGradient;
  final double borderWidth;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final List<BoxShadow>? boxShadow;
  final bool bounceOnTap;

  const GlassCard({
    super.key,
    this.child,
    this.blur = 12.0,
    this.opacity,
    this.backgroundColor,
    this.borderGradient,
    this.borderWidth = 1.0,
    this.borderRadius,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.onLongPress,
    this.boxShadow,
    this.bounceOnTap = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveRadius = borderRadius ?? BorderRadius.circular(20);
    final effectiveOpacity = opacity ?? (isDark ? 0.15 : 0.65);
    final baseBgColor = backgroundColor ?? (isDark ? const Color(0xFF1E293B) : Colors.white);
    final effectiveBgColor = baseBgColor.withValues(alpha: effectiveOpacity);

    final defaultBorderGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              Colors.white.withValues(alpha: 0.2),
              Colors.white.withValues(alpha: 0.03),
            ]
          : [
              Colors.white.withValues(alpha: 0.8),
              Colors.white.withValues(alpha: 0.3),
            ],
    );

    Widget content = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      color: effectiveBgColor,
      child: child,
    );

    Widget glassBody = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: CustomPaint(
            foregroundPainter: _GradientBorderPainter(
              borderGradient: borderGradient ?? defaultBorderGradient,
              borderWidth: borderWidth,
              borderRadius: effectiveRadius,
            ),
            child: content,
          ),
        ),
      ),
    );

    if (onTap != null) {
      if (bounceOnTap) {
        return BouncingButton(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: effectiveRadius,
          child: glassBody,
        );
      }

      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: effectiveRadius,
          onTap: onTap,
          onLongPress: onLongPress,
          child: glassBody,
        ),
      );
    }

    return glassBody;
  }
}

class _GradientBorderPainter extends CustomPainter {
  final Gradient borderGradient;
  final double borderWidth;
  final BorderRadius borderRadius;

  _GradientBorderPainter({
    required this.borderGradient,
    required this.borderWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (borderWidth <= 0) return;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = borderRadius.toRRect(rect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = borderGradient.createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) {
    return oldDelegate.borderGradient != borderGradient ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderRadius != borderRadius;
  }
}
