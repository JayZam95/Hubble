import 'dart:io';
import '../../domain/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

abstract class BaseAuthRepository {
  Stream<UserModel?> get authStateChanges;
  Stream<auth.User?> get firebaseAuthStateChanges;
  
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    required String phoneNumber,
  });

  Future<auth.UserCredential> signInWithGoogle();

  Future<UserModel> completeGoogleSetup({
    required auth.User firebaseUser,
    required String displayName,
    required UserRole role,
    required String phoneNumber,
  });

  Future<void> signOut();

  Future<UserModel?> getCurrentUserData();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> uploadProfileImage(String uid, File imageFile);

  Future<Map<String, String>?> getGoogleDriveAuthHeaders();
}
