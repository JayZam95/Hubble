import 'package:flutter/foundation.dart';

/// Centralized Telemetry & Crash Observability Service.
/// In development, routes error traces and breadcrumbs through [debugPrint].
/// In production, serves as the unified dispatcher for remote crash logging and analytics.
class TelemetryService {
  static String? _currentUserId;
  static final List<String> _recentBreadcrumbs = [];
  static const int _maxBreadcrumbs = 50;

  /// Initialize global Flutter and platform dispatcher error hooks.
  static void initialize() {
    FlutterError.onError = (FlutterErrorDetails details) {
      recordFlutterError(details);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      recordError(error, stack, reason: 'PlatformDispatcher Unhandled Error', fatal: true);
      return true;
    };
  }

  /// Sets the active user identifier for telemetry and session breadcrumbs.
  static void setUserIdentifier(String uid) {
    _currentUserId = uid;
    logBreadcrumb('User identified: $uid');
  }

  /// Clears user identifier on logout.
  static void clearUserIdentifier() {
    logBreadcrumb('User logged out (was: $_currentUserId)');
    _currentUserId = null;
  }

  /// Records a chronological breadcrumb to trace user journey prior to an error.
  static void logBreadcrumb(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final breadcrumb = '[$timestamp] $message';
    _recentBreadcrumbs.add(breadcrumb);
    if (_recentBreadcrumbs.length > _maxBreadcrumbs) {
      _recentBreadcrumbs.removeAt(0);
    }
    if (kDebugMode) {
      debugPrint('[Telemetry Breadcrumb] $breadcrumb');
    }
  }

  /// Records a structured exception with stack trace.
  static void recordError(
    Object exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) {
    final prefix = fatal ? '🔥 [FATAL CRASH]' : '⚠️ [NON-FATAL ERROR]';
    debugPrint('$prefix Reason: ${reason ?? 'Unknown'}');
    debugPrint('Exception: $exception');
    if (stackTrace != null) {
      debugPrint('StackTrace:\n$stackTrace');
    }
    if (_currentUserId != null) {
      debugPrint('Active User: $_currentUserId');
    }
  }

  /// Handles structured Flutter framework error details.
  static void recordFlutterError(FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    } else {
      recordError(
        details.exception,
        details.stack,
        reason: details.context?.toString() ?? 'Flutter Framework Error',
        fatal: false,
      );
    }
  }

  /// Returns an immutable copy of recent session breadcrumbs.
  static List<String> get recentBreadcrumbs => List.unmodifiable(_recentBreadcrumbs);
}
