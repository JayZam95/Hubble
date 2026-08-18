import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Smooth multi-ring pulsing radar / beacon animation.
/// Ideal for live tracking markers, available drivers, GPS pings, and active badges.
class PulsingBeacon extends StatefulWidget {
  final double size;
  final Color color;
  final int ringCount;
  final Duration duration;
  final Widget? centerChild;
  final double coreSize;
  final bool showGlow;

  const PulsingBeacon({
    super.key,
    this.size = 80.0,
    this.color = AppColors.primary,
    this.ringCount = 2,
    this.duration = const Duration(milliseconds: 2000),
    this.centerChild,
    this.coreSize = 16.0,
    this.showGlow = true,
  });

  @override
  State<PulsingBeacon> createState() => _PulsingBeaconState();
}

class _PulsingBeaconState extends State<PulsingBeacon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Expanding pulse waves
          for (int i = 0; i < widget.ringCount; i++)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final delay = i / widget.ringCount;
                final progress = (_controller.value + delay) % 1.0;
                final waveScale = Curves.easeOutQuad.transform(progress);
                final waveOpacity = (1.0 - progress).clamp(0.0, 1.0) * 0.6;

                return Transform.scale(
                  scale: 0.2 + (0.8 * waveScale),
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color.withValues(alpha: waveOpacity * 0.3),
                      border: Border.all(
                        color: widget.color.withValues(alpha: waveOpacity),
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),

          // Central core indicator / child
          if (widget.centerChild != null)
            widget.centerChild!
          else
            Container(
              width: widget.coreSize,
              height: widget.coreSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: widget.showGlow
                    ? [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.6),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact pulsing online / live status indicator dot
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;

  const PulsingDot({
    super.key,
    this.color = AppColors.primary,
    this.size = 10.0,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.size * 1.8,
                height: widget.size * 1.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: _opacityAnimation.value * 0.35),
                ),
              ),
            ),
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
