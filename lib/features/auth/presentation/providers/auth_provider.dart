import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:rxdart/rxdart.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/base_auth_repository.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/errors/app_exception.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 1. Auth State Class
class AuthState {
  final UserModel? user;
  final auth.User? firebaseUser;
  final bool isLoading;
  final String? errorMessage;
  final bool isPasswordResetSent;

  AuthState({
    this.user,
    this.firebaseUser,
    this.isLoading = false,
    this.errorMessage,
    this.isPasswordResetSent = false,
  });

  bool get isAuthenticated => user != null;
  bool get isPartialAuth => firebaseUser != null && user == null;

  AuthState copyWith({
    UserModel? user,
    auth.User? firebaseUser,
    bool? isLoading,
    String? errorMessage,
    bool? isPasswordResetSent,
    bool clearError = false,
    bool clearPasswordReset = false,
    bool setFirebaseUser = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      firebaseUser: setFirebaseUser ? firebaseUser : (firebaseUser ?? this.firebaseUser),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isPasswordResetSent: clearPasswordReset ? false : (isPasswordResetSent ?? this.isPasswordResetSent),
    );
  }
}

// 2. Base Providers
final authRepositoryProvider = Provider<BaseAuthRepository>((ref) {
  return AuthRepository();
});

// 3. Auth Notifier using modern Riverpod 3.x Notifier
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _init();
    return AuthState(isLoading: true);
  }

  void _init() {
    final repository = ref.read(authRepositoryProvider);
    
    final subscription = CombineLatestStream.combine2(
      repository.firebaseAuthStateChanges,
      repository.authStateChanges,
      (auth.User? firebaseUser, UserModel? userModel) {
        return {'firebaseUser': firebaseUser, 'user': userModel};
      },
    ).listen(
      (data) {
        Future.microtask(() {
          final userModel = data['user'] as UserModel?;
          if (userModel != null) {
            pushNotificationService.updateToken(userModel.uid);
          }
          state = state.copyWith(
            firebaseUser: data['firebaseUser'] as auth.User?,
            setFirebaseUser: true,
            user: userModel,
            clearUser: userModel == null,
            isLoading: false,
          );
        });
      },
      onError: (err) {
        Future.microtask(() {
          state = AuthState(
            isLoading: false,
            errorMessage: err.toString(),
          );
        });
      },
    );
    ref.onDispose(() {
      subscription.cancel();
    });
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true, clearPasswordReset: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    required String phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearPasswordReset: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
        phoneNumber: phoneNumber,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true, clearPasswordReset: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signInWithGoogle();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      if (e is AppException && e.code == 'canceled') {
        state = state.copyWith(isLoading: false);
        return;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> completeGoogleSetup({
    required String displayName,
    required UserRole role,
    required String phoneNumber,
  }) async {
    final firebaseUser = state.firebaseUser;
    if (firebaseUser == null) return;
    
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.completeGoogleSetup(
        firebaseUser: firebaseUser,
        displayName: displayName,
        role: role,
        phoneNumber: phoneNumber,
      );
      await refreshUser();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> updatePresence(bool isOnline) async {
    final user = state.user;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'isOnline': isOnline,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true, clearPasswordReset: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signOut();
      state = AuthState(user: null, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true, clearPasswordReset: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.sendPasswordResetEmail(email);
      state = state.copyWith(isLoading: false, isPasswordResetSent: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> refreshUser() async {
    final repository = ref.read(authRepositoryProvider);
    final user = await repository.getCurrentUserData();
    if (user != null) {
      state = state.copyWith(user: user);
    }
  }

  Future<void> uploadProfileImage(File imageFile) async {
    final user = state.user;
    if (user == null) return;
    
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.uploadProfileImage(user.uid, imageFile);
      await refreshUser();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearPasswordReset() {
    state = state.copyWith(clearPasswordReset: true);
  }
}

// 4. Main Auth Provider
final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
