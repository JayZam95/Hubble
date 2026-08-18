import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Interactive tactile bouncing micro-interaction widget.
/// Gently scales down when pressed and rebounds smoothly on release with optional haptics.
class BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double lowerBound;
  final Duration duration;
  final Duration reverseDuration;
  final Curve curve;
  final Curve reverseCurve;
  final bool enableHaptic;
  final bool enabled;
  final BorderRadius? borderRadius;

  const BouncingButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.lowerBound = 0.95,
    this.duration = const Duration(milliseconds: 120),
    this.reverseDuration = const Duration(milliseconds: 160),
    this.curve = Curves.easeInOutCubic,
    this.reverseCurve = Curves.easeOutBack,
    this.enableHaptic = true,
    this.enabled = true,
    this.borderRadius,
  });

  @override
  State<BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<BouncingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.reverseDuration,
      value: 1.0,
      lowerBound: widget.lowerBound,
      upperBound: 1.0,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
      reverseCurve: widget.reverseCurve,
    );
  }

  @override
  void didUpdateWidget(BouncingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lowerBound != widget.lowerBound ||
        oldWidget.duration != widget.duration ||
        oldWidget.reverseDuration != widget.reverseDuration) {
      _controller.dispose();
      _controller = AnimationController(
        vsync: this,
        duration: widget.duration,
        reverseDuration: widget.reverseDuration,
        value: 1.0,
        lowerBound: widget.lowerBound,
        upperBound: 1.0,
      );
      _scaleAnimation = CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
        reverseCurve: widget.reverseCurve,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled || widget.onTap == null) return;
    _controller.animateTo(widget.lowerBound);
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled || widget.onTap == null) return;
    _controller.animateTo(1.0);
  }

  void _handleTapCancel() {
    if (!widget.enabled || widget.onTap == null) return;
    _controller.animateTo(1.0);
  }

  void _handleTap() {
    if (!widget.enabled || widget.onTap == null) return;
    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveChild = widget.borderRadius != null
        ? ClipRRect(
            borderRadius: widget.borderRadius!,
            child: widget.child,
          )
        : widget.child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      onLongPress: widget.onLongPress != null
          ? () {
              if (widget.enableHaptic) {
                HapticFeedback.mediumImpact();
              }
              widget.onLongPress!();
            }
          : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _controller.value,
            child: child,
          );
        },
        child: effectiveChild,
      ),
    );
  }
}

/// Lightweight shorthand for bouncing tap wrapper
class ScaleTap extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final bool enableHaptic;

  const ScaleTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.96,
    this.enableHaptic = true,
  });

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      onTap: onTap,
      lowerBound: scaleDown,
      enableHaptic: enableHaptic,
      child: child,
    );
  }
}
