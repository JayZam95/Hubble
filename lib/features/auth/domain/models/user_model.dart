import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  client,
  provider;

  String toJson() => name;

  static UserRole fromJson(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => UserRole.client,
    );
  }
}

class PersonalInfo {
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String email;
  final bool isVerified;
  final String profileImageURL;

  PersonalInfo({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
    required this.isVerified,
    required this.profileImageURL,
  });

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'email': email,
      'isVerified': isVerified,
      'profileImageURL': profileImageURL,
    };
  }

  factory PersonalInfo.fromMap(Map<String, dynamic> map) {
    return PersonalInfo(
      firstName: map['firstName'] as String? ?? '',
      lastName: map['lastName'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      email: map['email'] as String? ?? '',
      isVerified: map['isVerified'] as bool? ?? false,
      profileImageURL: map['profileImageURL'] as String? ?? '',
    );
  }
}

class CurrentLocation {
  final double latitude;
  final double longitude;
  final String geohash;

  CurrentLocation({
    required this.latitude,
    required this.longitude,
    required this.geohash,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'geohash': geohash,
    };
  }

  factory CurrentLocation.fromMap(Map<String, dynamic> map) {
    return CurrentLocation(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      geohash: map['geohash'] as String? ?? '',
    );
  }
}

class ClientProfile {
  final double ratingAsClient;
  final int totalBookingsMade;
  final bool allowsReferenceInquiries;

  ClientProfile({
    required this.ratingAsClient,
    required this.totalBookingsMade,
    this.allowsReferenceInquiries = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'ratingAsClient': ratingAsClient,
      'totalBookingsMade': totalBookingsMade,
      'allowsReferenceInquiries': allowsReferenceInquiries,
    };
  }

  factory ClientProfile.fromMap(Map<String, dynamic> map) {
    return ClientProfile(
      ratingAsClient: (map['ratingAsClient'] as num?)?.toDouble() ?? 0.0,
      totalBookingsMade: map['totalBookingsMade'] as int? ?? 0,
      allowsReferenceInquiries: map['allowsReferenceInquiries'] as bool? ?? true,
    );
  }
}

class ProviderProfile {
  final bool isActive;
  final String professionTitle;
  final String category;
  final double hourlyRate;
  final String currency;
  final String bio;
  final double ratingAsProvider;
  final int reviewCount;
  final int totalJobsCompleted;
  final List<String> portfolioImages;
  final String businessType; // 'individual' or 'shop'
  final int listingsCount; // Number of active listings published
  final List<String> skills;
  final List<String> experience;
  final bool isLocationShared;

  ProviderProfile({
    required this.isActive,
    required this.professionTitle,
    required this.category,
    required this.hourlyRate,
    required this.currency,
    required this.bio,
    required this.ratingAsProvider,
    this.reviewCount = 0,
    required this.totalJobsCompleted,
    required this.portfolioImages,
    required this.businessType,
    required this.listingsCount,
    this.skills = const [],
    this.experience = const [],
    this.isLocationShared = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'isActive': isActive,
      'professionTitle': professionTitle,
      'category': category,
      'hourlyRate': hourlyRate,
      'currency': currency,
      'bio': bio,
      'ratingAsProvider': ratingAsProvider,
      'reviewCount': reviewCount,
      'totalJobsCompleted': totalJobsCompleted,
      'portfolioImages': portfolioImages,
      'businessType': businessType,
      'listingsCount': listingsCount,
      'skills': skills,
      'experience': experience,
      'isLocationShared': isLocationShared,
    };
  }

  factory ProviderProfile.fromMap(Map<String, dynamic> map) {
    return ProviderProfile(
      isActive: map['isActive'] as bool? ?? false,
      professionTitle: map['professionTitle'] as String? ?? '',
      category: map['category'] as String? ?? '',
      hourlyRate: (map['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'ZMW',
      bio: map['bio'] as String? ?? '',
      ratingAsProvider: (map['ratingAsProvider'] as num?)?.toDouble() ?? 0.0,
      reviewCount: map['reviewCount'] as int? ?? 0,
      totalJobsCompleted: map['totalJobsCompleted'] as int? ?? 0,
      portfolioImages: (map['portfolioImages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      businessType: map['businessType'] as String? ?? 'individual',
      listingsCount: map['listingsCount'] as int? ?? 0,
      skills: (map['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      experience: (map['experience'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isLocationShared: map['isLocationShared'] as bool? ?? false,
    );
  }
}

class VaultSettings {
  final bool isAutoSaveEnabled;
  final double autoSavePercentage;
  final double vaultBalance;

  VaultSettings({
    required this.isAutoSaveEnabled,
    required this.autoSavePercentage,
    required this.vaultBalance,
  });

  Map<String, dynamic> toMap() {
    return {
      'isAutoSaveEnabled': isAutoSaveEnabled,
      'autoSavePercentage': autoSavePercentage,
      'vaultBalance': vaultBalance,
    };
  }

  factory VaultSettings.fromMap(Map<String, dynamic> map) {
    return VaultSettings(
      isAutoSaveEnabled: map['isAutoSaveEnabled'] as bool? ?? false,
      autoSavePercentage: (map['autoSavePercentage'] as num?)?.toDouble() ?? 0.0,
      vaultBalance: (map['vaultBalance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class InvestmentPortfolio {
  final bool isActive;
  final String? brokeragePartnerId;
  final double totalEstimatedValue;
  final List<dynamic> assets;

  InvestmentPortfolio({
    required this.isActive,
    this.brokeragePartnerId,
    required this.totalEstimatedValue,
    required this.assets,
  });

  Map<String, dynamic> toMap() {
    return {
      'isActive': isActive,
      'brokeragePartnerId': brokeragePartnerId,
      'totalEstimatedValue': totalEstimatedValue,
      'assets': assets,
    };
  }

  factory InvestmentPortfolio.fromMap(Map<String, dynamic> map) {
    return InvestmentPortfolio(
      isActive: map['isActive'] as bool? ?? false,
      brokeragePartnerId: map['brokeragePartnerId'] as String?,
      totalEstimatedValue: (map['totalEstimatedValue'] as num?)?.toDouble() ?? 0.0,
      assets: List<dynamic>.from(map['assets'] as List? ?? []),
    );
  }
}

class FinancialLedger {
  final String currency;
  final double availableBalance;
  final VaultSettings vaultSettings;
  final InvestmentPortfolio investmentPortfolio;

  FinancialLedger({
    required this.currency,
    required this.availableBalance,
    required this.vaultSettings,
    required this.investmentPortfolio,
  });

  Map<String, dynamic> toMap() {
    return {
      'currency': currency,
      'availableBalance': availableBalance,
      'vaultSettings': vaultSettings.toMap(),
      'investmentPortfolio': investmentPortfolio.toMap(),
    };
  }

  factory FinancialLedger.fromMap(Map<String, dynamic> map) {
    return FinancialLedger(
      currency: map['currency'] as String? ?? 'ZMW',
      availableBalance: (map['availableBalance'] as num?)?.toDouble() ?? 0.0,
      vaultSettings: VaultSettings.fromMap(map['vaultSettings'] as Map<String, dynamic>? ?? {}),
      investmentPortfolio: InvestmentPortfolio.fromMap(map['investmentPortfolio'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final DateTime createdAt;
  final PersonalInfo personalInfo;
  final CurrentLocation currentLocation;
  final ClientProfile clientProfile;
  final ProviderProfile providerProfile;
  final FinancialLedger financialLedger;
  final String kycStatus;
  final bool isOnline;
  final DateTime? lastSeen;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
    required this.personalInfo,
    required this.currentLocation,
    required this.clientProfile,
    required this.providerProfile,
    required this.financialLedger,
    this.kycStatus = 'unverified',
    this.isOnline = false,
    this.lastSeen,
  });

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    DateTime? createdAt,
    PersonalInfo? personalInfo,
    CurrentLocation? currentLocation,
    ClientProfile? clientProfile,
    ProviderProfile? providerProfile,
    FinancialLedger? financialLedger,
    String? kycStatus,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      personalInfo: personalInfo ?? this.personalInfo,
      currentLocation: currentLocation ?? this.currentLocation,
      clientProfile: clientProfile ?? this.clientProfile,
      providerProfile: providerProfile ?? this.providerProfile,
      financialLedger: financialLedger ?? this.financialLedger,
      kycStatus: kycStatus ?? this.kycStatus,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': uid,
      'personalInfo': personalInfo.toMap(),
      'currentLocation': currentLocation.toMap(),
      'clientProfile': clientProfile.toMap(),
      'providerProfile': providerProfile.toMap(),
      'financialLedger': financialLedger.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'kycStatus': kycStatus,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final personalInfoMap = map['personalInfo'] as Map<String, dynamic>? ?? {};
    final firstName = personalInfoMap['firstName'] as String? ?? '';
    final lastName = personalInfoMap['lastName'] as String? ?? '';
    final displayName = '$firstName $lastName'.trim();
    
    final providerProfileMap = map['providerProfile'] as Map<String, dynamic>? ?? {};
    final isActiveProvider = providerProfileMap['isActive'] as bool? ?? false;
    final role = isActiveProvider ? UserRole.provider : UserRole.client;

    return UserModel(
      uid: map['userId'] as String? ?? map['uid'] as String? ?? '',
      email: personalInfoMap['email'] as String? ?? map['email'] as String? ?? '',
      displayName: displayName.isNotEmpty ? displayName : (map['displayName'] as String? ?? ''),
      role: role,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      personalInfo: PersonalInfo.fromMap(personalInfoMap),
      currentLocation: CurrentLocation.fromMap(map['currentLocation'] as Map<String, dynamic>? ?? {}),
      clientProfile: ClientProfile.fromMap(map['clientProfile'] as Map<String, dynamic>? ?? {}),
      providerProfile: ProviderProfile.fromMap(providerProfileMap),
      financialLedger: FinancialLedger.fromMap(map['financialLedger'] as Map<String, dynamic>? ?? {}),
      kycStatus: map['kycStatus'] as String? ?? 'unverified',
      isOnline: map['isOnline'] as bool? ?? false,
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate(),
    );
  }
}
