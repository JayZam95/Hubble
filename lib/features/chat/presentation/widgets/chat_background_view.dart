import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';

class ChatBackgroundView extends StatefulWidget {
  final String bgMode; /* 'dynamic_gradient', 'dynamic_image', 'custom_image' */
  final String? customImageUri;
  const ChatBackgroundView({
    super.key,
    required this.bgMode,
    this.customImageUri,
  });
  @override
  State<ChatBackgroundView> createState() => _ChatBackgroundViewState();
}

class _ChatBackgroundViewState extends State<ChatBackgroundView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double>
  _animation; /* Curated Unsplash HD URLs matching times of day for "Dynamic Wallpapers"*/
  static const String morningUrl =
      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1000&q=80'; /* Beach sunrise */
  static const String afternoonUrl =
      'https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?auto=format&fit=crop&w=1000&q=80'; /* Sunny forest */
  static const String eveningUrl =
      'https://images.unsplash.com/photo-1509114397022-ed747cca3f65?auto=format&fit=crop&w=1000&q=80'; /* Twilight sunset */
  static const String nightUrl =
      'https://images.unsplash.com/photo-1506318137071-a8e063b4bec0?auto=format&fit=crop&w=1000&q=80'; /* Starry night sky */
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );
    if (!(!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'))) {
      _animationController.repeat(reverse: true);
    }
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getHourBasedWallpaper() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) {
      return morningUrl;
    } else if (hour >= 12 && hour < 18) {
      return afternoonUrl;
    } else if (hour >= 18 && hour < 22) {
      return eveningUrl;
    } else {
      return nightUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (widget.bgMode == 'dynamic_image') {
      final url = _getHourBasedWallpaper();
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        ),
      );
    } else if (widget.bgMode == 'custom_image' &&
        widget.customImageUri != null) {
      final file = File(widget.customImageUri!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      }
    } /* Default: 'dynamic_gradient' (Smoothly shifting linear canvas)*/
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        /* Shift linear gradient endpoints based on animations*/
        final shift = _animation.value;
        final begin = Alignment(-1.0 + (shift * 0.5), -1.0 + (shift * 0.2));
        final end = Alignment(1.0 - (shift * 0.5), 1.0 - (shift * 0.2));
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: begin,
              end: end,
              colors: isDark
                  ? const [
                      Color(0xFF0F172A),
                      /* Slate Dark */ Color(0xFF1E1E38),
                      /* Midnight Blue */ Color(
                        0xFF111827,
                      ) /* Neutral Black-Gray */,
                    ]
                  : const [
                      Color(0xFFEEF2F6),
                      /* Bright Soft Slate */ Color(0xFFE0E7FF),
                      /* Indigo tint */ Color(0xFFF1F5F9) /* Pure Soft Gray */,
                    ],
            ),
          ),
        );
      },
    );
  }
}
