import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:rxdart/rxdart.dart';
import 'package:hubble/features/auth/domain/models/user_model.dart';
import 'package:hubble/features/auth/domain/repositories/base_auth_repository.dart';
import 'package:hubble/features/auth/presentation/providers/auth_provider.dart';

// Helper to create complete structured user models for testing
UserModel createMockUserModel({
  required String uid,
  required String email,
  required String displayName,
  required UserRole role,
  String phoneNumber = '+260971234567',
}) {
  final nameComponents = displayName.split(' ');
  final firstName = nameComponents.isNotEmpty ? nameComponents.first : '';
  final lastName = nameComponents.length > 1 ? nameComponents.skip(1).join(' ') : '';

  return UserModel(
    uid: uid,
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
      investmentPortfolio: InvestmentPortfolio(isActive: false, brokeragePartnerId: null, totalEstimatedValue: 0.0, assets: []),
    ),
  );
}

// 1. Fake Auth Repository for testing
class FakeAuthRepository implements BaseAuthRepository {
  final _authStateController = BehaviorSubject<UserModel?>.seeded(null);
  final _firebaseAuthStateController = BehaviorSubject<auth.User?>.seeded(null);
  UserModel? mockUser;
  bool shouldThrow = false;
  String exceptionMessage = 'Auth Error';

  @override
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  void emitUser(UserModel? user) {
    mockUser = user;
    _authStateController.add(user);
  }

  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (shouldThrow) throw Exception(exceptionMessage);
    final user = createMockUserModel(
      uid: 'fake_uid',
      email: email,
      displayName: 'Test User',
      role: UserRole.client,
    );
    emitUser(user);
    return user;
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    required String phoneNumber,
  }) async {
    if (shouldThrow) throw Exception(exceptionMessage);
    final user = createMockUserModel(
      uid: 'fake_uid',
      email: email,
      displayName: displayName,
      role: role,
      phoneNumber: phoneNumber,
    );
    emitUser(user);
    return user;
  }

  @override
  Stream<auth.User?> get firebaseAuthStateChanges => _firebaseAuthStateController.stream;

  @override
  Future<UserModel> completeGoogleSetup({
    required auth.User firebaseUser,
    required String displayName,
    required UserRole role,
    required String phoneNumber,
  }) async {
    final user = createMockUserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: displayName.isNotEmpty ? displayName : (firebaseUser.displayName ?? 'Google User'),
      role: role,
      phoneNumber: phoneNumber,
    );
    emitUser(user);
    return user;
  }

  @override
  Future<auth.UserCredential> signInWithGoogle() async {
    if (shouldThrow) throw Exception(exceptionMessage);
    // In a real test, you'd probably return a mock UserCredential, 
    // but here we just need to satisfy the signature. We'll throw an exception or return a mock.
    throw UnimplementedError('Mock UserCredential not implemented');
  }

  @override
  Future<void> signOut() async {
    if (shouldThrow) throw Exception(exceptionMessage);
    emitUser(null);
  }

  @override
  Future<UserModel?> getCurrentUserData() async {
    return mockUser;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (shouldThrow) throw Exception(exceptionMessage);
  }

  @override
  Future<void> uploadProfileImage(String uid, File imageFile) async {
    if (shouldThrow) throw Exception(exceptionMessage);
    if (mockUser != null) {
      final updatedPersonalInfo = PersonalInfo(
        firstName: mockUser!.personalInfo.firstName,
        lastName: mockUser!.personalInfo.lastName,
        phoneNumber: mockUser!.personalInfo.phoneNumber,
        email: mockUser!.personalInfo.email,
        isVerified: mockUser!.personalInfo.isVerified,
        profileImageURL: 'https://fake.url/image.jpg',
      );
      mockUser = mockUser!.copyWith(personalInfo: updatedPersonalInfo);
    }
  }

  @override
  Future<Map<String, String>?> getGoogleDriveAuthHeaders() async {
    return {'Authorization': 'Bearer fake_token'};
  }

  void dispose() {
    _authStateController.close();
    _firebaseAuthStateController.close();
  }
}

void main() {
  late FakeAuthRepository fakeRepository;
  late ProviderContainer container;

  setUp(() {
    fakeRepository = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    fakeRepository.dispose();
  });

  test('Initial state is loading', () {
    final state = container.read(authStateProvider);
    expect(state.isLoading, true);
    expect(state.user, null);
    expect(state.errorMessage, null);
  });

  test('Emitting auth changes updates user state', () async {
    container.listen(authStateProvider, (prev, next) {});
    
    // Initial state is loading
    expect(container.read(authStateProvider).isLoading, true);

    // Emit authenticated user
    final user = createMockUserModel(
      uid: 'fake_uid',
      email: 'test@hubble.com',
      displayName: 'Test User',
      role: UserRole.client,
    );
    fakeRepository.emitUser(user);

    // Allow stream to emit
    await Future.delayed(Duration.zero);

    final state = container.read(authStateProvider);
    expect(state.isLoading, false);
    expect(state.user, user);
    expect(state.isAuthenticated, true);
  });

  test('signInWithEmailAndPassword success updates state with user', () async {
    fakeRepository.emitUser(null);
    await Future.delayed(Duration.zero);

    await container.read(authStateProvider.notifier).signInWithEmailAndPassword(
      'test@hubble.com',
      'password123',
    );
    await Future.delayed(Duration.zero);

    final state = container.read(authStateProvider);
    expect(state.isLoading, false);
    expect(state.user?.email, 'test@hubble.com');
    expect(state.isAuthenticated, true);
    expect(state.errorMessage, null);
  });

  test('signInWithEmailAndPassword failure updates state with error message', () async {
    fakeRepository.emitUser(null);
    await Future.delayed(Duration.zero);
    fakeRepository.shouldThrow = true;
    fakeRepository.exceptionMessage = 'Invalid Credentials';

    await container.read(authStateProvider.notifier).signInWithEmailAndPassword(
      'test@hubble.com',
      'wrong_password',
    );

    final state = container.read(authStateProvider);
    expect(state.isLoading, false);
    expect(state.user, null);
    expect(state.isAuthenticated, false);
    expect(state.errorMessage, 'Invalid Credentials');
  });

  test('signUpWithEmailAndPassword success registers and profiles user', () async {
    fakeRepository.emitUser(null);
    await Future.delayed(Duration.zero);

    await container.read(authStateProvider.notifier).signUpWithEmailAndPassword(
      email: 'register@hubble.com',
      password: 'secure_password',
      displayName: 'New Expert',
      role: UserRole.provider,
      phoneNumber: '+260979876543',
    );
    await Future.delayed(Duration.zero);

    final state = container.read(authStateProvider);
    expect(state.isLoading, false);
    expect(state.user?.displayName, 'New Expert');
    expect(state.user?.role, UserRole.provider);
    expect(state.user?.personalInfo.phoneNumber, '+260979876543');
    expect(state.errorMessage, null);
  });

  test('signOut clears authenticated user state', () async {
    await container.read(authStateProvider.notifier).signInWithEmailAndPassword(
      'test@hubble.com',
      'password123',
    );
    await Future.delayed(Duration.zero);
    expect(container.read(authStateProvider).isAuthenticated, true);

    await container.read(authStateProvider.notifier).signOut();
    await Future.delayed(Duration.zero);

    final state = container.read(authStateProvider);
    expect(state.isLoading, false);
    expect(state.user, null);
    expect(state.isAuthenticated, false);
  });

  test('sendPasswordResetEmail success updates state', () async {
    fakeRepository.emitUser(null);
    await Future.delayed(Duration.zero);

    await container.read(authStateProvider.notifier).sendPasswordResetEmail('test@hubble.com');

    final state = container.read(authStateProvider);
    expect(state.isLoading, false);
    expect(state.isPasswordResetSent, true);
    expect(state.errorMessage, null);
  });

  test('uploadProfileImage success updates state user', () async {
    // Initialize provider to start listening to the stream
    container.read(authStateProvider);

    final user = createMockUserModel(
      uid: 'fake_uid',
      email: 'test@hubble.com',
      displayName: 'Test User',
      role: UserRole.client,
    );
    fakeRepository.emitUser(user);
    await Future.delayed(Duration.zero);

    final file = File('test.jpg');
    await container.read(authStateProvider.notifier).uploadProfileImage(file);

    final state = container.read(authStateProvider);
    expect(state.isLoading, false);
    expect(state.user?.personalInfo.profileImageURL, 'https://fake.url/image.jpg');
    expect(state.errorMessage, null);
  });
}
