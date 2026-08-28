import 'package:firebase_auth/firebase_auth.dart';

/// Custom application exception for user-friendly error formatting across Hubble.
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;

  /// Creates a user-friendly AppException from Firebase/Firestore or generic errors.
  factory AppException.fromFirebaseException(dynamic error) {
    if (error is AppException) return error;

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return AppException('No account found with this email address.', code: error.code, originalError: error);
        case 'wrong-password':
          return AppException('Incorrect password. Please try again.', code: error.code, originalError: error);
        case 'email-already-in-use':
          return AppException('An account already exists with this email address.', code: error.code, originalError: error);
        case 'invalid-email':
          return AppException('Please enter a valid email address.', code: error.code, originalError: error);
        case 'weak-password':
          return AppException('Password is too weak. Please choose a stronger password.', code: error.code, originalError: error);
        case 'network-request-failed':
          return AppException('Network error. Please check your internet connection.', code: error.code, originalError: error);
        case 'user-disabled':
          return AppException('This account has been disabled. Please contact support.', code: error.code, originalError: error);
        case 'too-many-requests':
          return AppException('Too many requests. Please wait a moment and try again.', code: error.code, originalError: error);
        default:
          return AppException(error.message ?? 'Authentication error occurred (${error.code}).', code: error.code, originalError: error);
      }
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return AppException('Access denied: You do not have permission to perform this action.', code: error.code, originalError: error);
        case 'unavailable':
          return AppException('Service temporarily unavailable. Please check your network connection.', code: error.code, originalError: error);
        case 'not-found':
          return AppException('The requested document or resource was not found.', code: error.code, originalError: error);
        case 'already-exists':
          return AppException('This document already exists.', code: error.code, originalError: error);
        case 'unauthenticated':
          return AppException('Session expired. Please sign in again.', code: error.code, originalError: error);
        case 'resource-exhausted':
          return AppException('Quota exceeded. Please try again later.', code: error.code, originalError: error);
        case 'cancelled':
          return AppException('The operation was cancelled.', code: error.code, originalError: error);
        case 'deadline-exceeded':
          return AppException('Request timed out. Please try again.', code: error.code, originalError: error);
        default:
          return AppException(error.message ?? 'Database operation failed (${error.code}).', code: error.code, originalError: error);
      }
    }

    final rawStr = error?.toString() ?? '';
    if (rawStr.contains('GoogleSignInExceptionCode.canceled') || rawStr.contains('canceled')) {
      return AppException('Google Sign-In was canceled.', code: 'canceled', originalError: error);
    }
    if (rawStr.contains('Account reauth failed') || rawStr.contains('[16]')) {
      return AppException('Google Sign-In was canceled or re-authentication failed.', code: 'canceled', originalError: error);
    }

    final cleaned = rawStr.replaceAll(RegExp(r'^(Exception|StateError):\s*'), '');
    return AppException(cleaned.isNotEmpty ? cleaned : 'An unexpected error occurred.', originalError: error);
  }
}
