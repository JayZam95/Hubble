import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rxdart/rxdart.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/base_auth_repository.dart';
import '../../../../core/config/auth_config.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/errors/app_exception.dart';
import 'package:flutter/foundation.dart';

class AuthRepository implements BaseAuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<UserModel> _createAndPersistUserDoc(User firebaseUser) async {
    final email = firebaseUser.email ?? '';
    final name = firebaseUser.displayName ?? (email.isNotEmpty ? email.split('@')[0] : 'Hubble User');
    final nameComponents = name.split(' ');
    final firstName = nameComponents.isNotEmpty ? nameComponents.first : '';
    final lastName = nameComponents.length > 1 ? nameComponents.sublist(1).join(' ') : '';
    final photoURL = firebaseUser.photoURL ?? '';

    final newUserModel = UserModel(
      uid: firebaseUser.uid,
      email: email,
      displayName: name,
      role: UserRole.client,
      createdAt: DateTime.now(),
      personalInfo: PersonalInfo(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: firebaseUser.phoneNumber ?? '',
        email: email,
        isVerified: false,
        profileImageURL: photoURL,
      ),
      currentLocation: CurrentLocation(latitude: 0.0, longitude: 0.0, geohash: ''),
      clientProfile: ClientProfile(ratingAsClient: 0.0, totalBookingsMade: 0),
      providerProfile: ProviderProfile(
        isActive: false,
        professionTitle: '',
        category: '',
        hourlyRate: 0.0,
        currency: 'ZMW',
        bio: '',
        ratingAsProvider: 0.0,
        totalJobsCompleted: 0,
        portfolioImages: [],
        businessType: 'individual',
        listingsCount: 0,
      ),
      financialLedger: FinancialLedger(
        currency: 'ZMW',
        availableBalance: 0.0,
        vaultSettings: VaultSettings(isAutoSaveEnabled: false, autoSavePercentage: 0.0, vaultBalance: 0.0),
        investmentPortfolio: InvestmentPortfolio(isActive: false, totalEstimatedValue: 0.0, assets: []),
      ),
    );

    try {
      await _firestore.collection('users').doc(firebaseUser.uid).set(
        newUserModel.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Error auto-creating Firestore user document: $e');
    }

    return newUserModel;
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().switchMap((firebaseUser) {
      if (firebaseUser == null) {
        return Stream.value(null);
      }
      return _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .snapshots()
          .asyncMap<UserModel?>((doc) async {
        if (doc.exists && doc.data() != null) {
          try {
            return UserModel.fromMap(doc.data()!);
          } catch (e) {
            debugPrint('Error parsing user data: $e');
          }
        }
        return await _createAndPersistUserDoc(firebaseUser);
      }).onErrorReturnWith((error, stackTrace) => null);
    }).onErrorReturnWith((error, stackTrace) => null);
  }

  Future<UserModel?> _fetchUserModel(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        try {
          return UserModel.fromMap(doc.data()!);
        } catch (e) {
          debugPrint('Error parsing user model: $e');
        }
      }
    } catch (e) {
      debugPrint('Error fetching user model: $e');
    }

    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null && currentUser.uid == uid) {
      return await _createAndPersistUserDoc(currentUser);
    }
    return null;
  }

  Future<void> _setupFirebaseMessaging(String uid) async {
    try {
      final messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized || 
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        String? token = await messaging.getToken();
        if (token != null) {
          await _firestore.collection('users').doc(uid).set(
            {'fcmToken': token},
            SetOptions(merge: true),
          );
        }
      }
    } catch (e) {
      debugPrint('FCM Setup error: $e');
    }
  }

  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw AppException('User authenticated but user profile is null.');

      final userModel = await _fetchUserModel(user.uid);
      if (userModel != null) {
        await _setupFirebaseMessaging(user.uid);
        return userModel;
      } else {
        // Fallback profile creation
        final emailSplit = email.split('@');
        final firstName = emailSplit[0];
        final lastName = emailSplit.length > 1 ? emailSplit[1] : '';

        final newUserModel = UserModel(
          uid: user.uid,
          email: user.email ?? email,
          displayName: user.displayName ?? email.split('@')[0],
          role: UserRole.client,
          createdAt: DateTime.now(),
          personalInfo: PersonalInfo(
            firstName: firstName,
            lastName: lastName,
            phoneNumber: '',
            email: user.email ?? email,
            isVerified: false,
            profileImageURL: '',
          ),
          currentLocation: CurrentLocation(latitude: 0.0, longitude: 0.0, geohash: ''),
          clientProfile: ClientProfile(ratingAsClient: 0.0, totalBookingsMade: 0),
          providerProfile: ProviderProfile(
            isActive: false,
            professionTitle: '',
            category: '',
            hourlyRate: 0.0,
            currency: 'ZMW',
            bio: '',
            ratingAsProvider: 0.0,
            totalJobsCompleted: 0,
            portfolioImages: [],
            businessType: 'individual',
            listingsCount: 0,
          ),
          financialLedger: FinancialLedger(
            currency: 'ZMW',
            availableBalance: 0.0,
            vaultSettings: VaultSettings(isAutoSaveEnabled: false, autoSavePercentage: 0.0, vaultBalance: 0.0),
            investmentPortfolio: InvestmentPortfolio(isActive: false, totalEstimatedValue: 0.0, assets: []),
          ),
        );
        await _firestore.collection('users').doc(user.uid).set(newUserModel.toMap());
        await _setupFirebaseMessaging(user.uid);
        return newUserModel;
      }
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    required String phoneNumber,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw AppException('User creation failed.');

      // Split full name by space
      final nameComponents = displayName.split(' ');
      final firstName = nameComponents.isNotEmpty ? nameComponents.first : '';
      final lastName = nameComponents.length > 1 ? nameComponents.sublist(1).join(' ') : '';

      final userModel = UserModel(
        uid: user.uid,
        email: email,
        displayName: displayName,
        role: role,
        createdAt: DateTime.now(),
        personalInfo: PersonalInfo(
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
          email: email,
          isVerified: false,
          profileImageURL: '',
        ),
        currentLocation: CurrentLocation(latitude: 0.0, longitude: 0.0, geohash: ''),
        clientProfile: ClientProfile(ratingAsClient: 0.0, totalBookingsMade: 0),
        providerProfile: ProviderProfile(
          isActive: role == UserRole.provider,
          professionTitle: '',
          category: '',
          hourlyRate: 0.0,
          currency: 'ZMW',
          bio: '',
          ratingAsProvider: 0.0,
          totalJobsCompleted: 0,
          portfolioImages: [],
          businessType: 'individual',
          listingsCount: 0,
        ),
        financialLedger: FinancialLedger(
          currency: 'ZMW',
          availableBalance: 0.0,
          vaultSettings: VaultSettings(isAutoSaveEnabled: false, autoSavePercentage: 0.0, vaultBalance: 0.0),
          investmentPortfolio: InvestmentPortfolio(isActive: false, totalEstimatedValue: 0.0, assets: []),
        ),
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
      await user.updateDisplayName(displayName);
      await _setupFirebaseMessaging(user.uid);

      return userModel;
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  @override
  Stream<User?> get firebaseAuthStateChanges => _firebaseAuth.authStateChanges().handleError((e) {
    throw AppException.fromFirebaseException(e);
  });

  bool _isGoogleSignInInitialized = false;

  @override
  Future<UserCredential> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        final UserCredential userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
        if (userCredential.user == null) throw AppException('Google Sign-In failed.');
        return userCredential;
      } else {
        if (!_isGoogleSignInInitialized) {
          try {
            await _googleSignIn.initialize(
              serverClientId: AuthConfig.googleServerClientId,
            );
            _isGoogleSignInInitialized = true;
          } catch (e) {
            _isGoogleSignInInitialized = true;
          }
        }

        GoogleSignInAccount? googleUser;
        try {
          googleUser = await _googleSignIn.authenticate();
        } on GoogleSignInException catch (e) {
          if (e.code == GoogleSignInExceptionCode.canceled) {
            throw AppException('Google Sign-In was canceled.', code: 'canceled', originalError: e);
          }
          if (e.description?.contains('No credentials available') == true || e.code == GoogleSignInExceptionCode.unknownError) {
            throw AppException('No Google Account found on this device. Please add a Google Account in your device settings.', code: 'no-account', originalError: e);
          }
          throw AppException('Google Sign-In was canceled or re-authentication failed.', code: 'canceled', originalError: e);
        } catch (e) {
          throw AppException.fromFirebaseException(e);
        }

        if (googleUser == null) {
          throw AppException('Google Sign-In was canceled.', code: 'canceled');
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
        final User? user = userCredential.user;
        if (user == null) throw AppException('Google Sign-In failed.');

        try {
          final doc = await _firestore.collection('users').doc(user.uid).get();
          if (!doc.exists) {
            await _createAndPersistUserDoc(user);
          }
        } catch (e) {
          debugPrint('Error verifying Google user doc: $e');
        }

        return userCredential;
      }
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  @override
  Future<UserModel> completeGoogleSetup({
    required User firebaseUser,
    required String displayName,
    required UserRole role,
    required String phoneNumber,
  }) async {
    try {
      final existingUser = await _fetchUserModel(firebaseUser.uid);
      if (existingUser != null) {
        await _setupFirebaseMessaging(firebaseUser.uid);
        return existingUser;
      }

      final fullName = displayName;
      final nameComponents = fullName.split(' ');
      final firstName = nameComponents.isNotEmpty ? nameComponents.first : '';
      final lastName = nameComponents.length > 1 ? nameComponents.sublist(1).join(' ') : '';
      final photoURL = firebaseUser.photoURL ?? '';

      final newUserModel = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: fullName,
        role: role,
        createdAt: DateTime.now(),
        personalInfo: PersonalInfo(
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
          email: firebaseUser.email ?? '',
          isVerified: false,
          profileImageURL: photoURL,
        ),
        currentLocation: CurrentLocation(latitude: 0.0, longitude: 0.0, geohash: ''),
        clientProfile: ClientProfile(ratingAsClient: 0.0, totalBookingsMade: 0),
        providerProfile: ProviderProfile(
          isActive: role == UserRole.provider,
          professionTitle: '',
          category: '',
          hourlyRate: 0.0,
          currency: 'ZMW',
          bio: '',
          ratingAsProvider: 0.0,
          totalJobsCompleted: 0,
          portfolioImages: [],
          businessType: 'individual',
          listingsCount: 0,
        ),
        financialLedger: FinancialLedger(
          currency: 'ZMW',
          availableBalance: 0.0,
          vaultSettings: VaultSettings(isAutoSaveEnabled: false, autoSavePercentage: 0.0, vaultBalance: 0.0),
          investmentPortfolio: InvestmentPortfolio(isActive: false, totalEstimatedValue: 0.0, assets: []),
        ),
      );

      try {
        await _firestore.collection('users').doc(firebaseUser.uid).set(
          newUserModel.toMap(),
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('Firestore set user model error during setup: $e');
      }
      await _setupFirebaseMessaging(firebaseUser.uid);
      return newUserModel;
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
    } catch (_) {}
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  @override
  Future<UserModel?> getCurrentUserData() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) return null;
      return await _fetchUserModel(currentUser.uid);
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  @override
  Future<void> uploadProfileImage(String uid, File imageFile) async {
    try {
      final base64String = await ImageUtils.fileToBase64(imageFile);
      if (base64String == null) throw AppException('Image compression failed.');

      await _firestore.collection('users').doc(uid).update({
        'personalInfo.profileImageURL': base64String,
      });
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  @override
  Future<Map<String, String>?> getGoogleDriveAuthHeaders() async {
    try {
      if (!_isGoogleSignInInitialized) {
        await _googleSignIn.initialize(
          serverClientId: AuthConfig.googleServerClientId,
        );
        _isGoogleSignInInitialized = true;
      }

      final googleUser = await _googleSignIn.authenticate();
      final clientAuth = await googleUser.authorizationClient.authorizeScopes([
        'https://www.googleapis.com/auth/drive.appdata',
      ]);

      return {
        'Authorization': 'Bearer ${clientAuth.accessToken}',
      };
    } catch (e) {
      debugPrint('Failed to get Google Drive auth headers: $e');
      throw AppException.fromFirebaseException(e);
    }
  }
}

