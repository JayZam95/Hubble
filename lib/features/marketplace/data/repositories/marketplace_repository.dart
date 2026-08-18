import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../../../auth/domain/models/user_model.dart';
import '../../domain/models/listing_model.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/errors/app_exception.dart';

class MarketplaceRepository {
  final FirebaseFirestore _firestore;

  MarketplaceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<ListingModel>> getListingsStream({int limit = 20}) {
    return _firestore
        .collection('listings')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ListingModel.fromMap(doc.data(), doc.id)).toList();
    }).handleError((error) {
      throw AppException.fromFirebaseException(error);
    });
  }

  Future<Map<String, dynamic>?> fetchProviderProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return data['providerProfile'] as Map<String, dynamic>?;
      }
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
    return null;
  }

  Future<void> saveProviderProfile({
    required String uid,
    required String professionTitle,
    required String category,
    required String businessType,
    required double hourlyRate,
    required String bio,
    required List<String> portfolioImages,
  }) async {
    try {
      final updatedData = {
        'providerProfile.professionTitle': professionTitle,
        'providerProfile.category': category,
        'providerProfile.businessType': businessType,
        'providerProfile.hourlyRate': hourlyRate,
        'providerProfile.bio': bio,
        'providerProfile.portfolioImages': portfolioImages,
        'providerProfile.isActive': true,
      };

      await _firestore.collection('users').doc(uid).update(updatedData);
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  Future<List<String>> uploadPortfolioImages(String uid, List<File> imageFiles) async {
    try {
      List<String> base64Images = [];
      for (var file in imageFiles) {
        final base64String = await ImageUtils.fileToBase64(file);
        if (base64String != null) {
          base64Images.add(base64String);
        }
      }
      return base64Images;
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  Future<List<String>> uploadListingImages(String listingId, List<File> imageFiles) async {
    try {
      List<String> base64Images = [];
      for (var file in imageFiles) {
        final base64String = await ImageUtils.fileToBase64(file);
        if (base64String != null) {
          base64Images.add(base64String);
        }
      }
      return base64Images;
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  List<String> _getSearchTokens(String query) {
    final lowerQuery = query.toLowerCase();
    final tokens = lowerQuery.split(RegExp(r'\s+')).where((t) => t.isNotEmpty && t != '&').toSet();
    
    final synonyms = {
      'legal': ['lawyer', 'attorney', 'advocate', 'law', 'court'],
      'medical': ['doctor', 'nurse', 'health', 'clinic', 'hospital', 'dentist', 'pharmacy'],
      'healthcare': ['doctor', 'nurse', 'health', 'clinic', 'hospital', 'dentist', 'pharmacy'],
      'technology': ['tech', 'software', 'developer', 'programmer', 'it', 'computer', 'app', 'web', 'engineer'],
      'software': ['tech', 'software', 'developer', 'programmer', 'it', 'computer', 'app', 'web', 'engineer'],
      'trades': ['plumber', 'electrician', 'carpenter', 'mechanic', 'repair', 'construction', 'builder', 'welder'],
      'repair': ['plumber', 'electrician', 'carpenter', 'mechanic', 'repair', 'construction', 'builder', 'welder'],
      'retail': ['shop', 'store', 'grocery', 'clothes', 'supermarket', 'vendor', 'seller', 'boutique', 'merchant'],
      'shopping': ['shop', 'store', 'grocery', 'clothes', 'supermarket', 'vendor', 'seller', 'boutique', 'merchant'],
      'education': ['teacher', 'tutor', 'school', 'lessons', 'instructor', 'coach', 'learning', 'mentor'],
      'tutoring': ['teacher', 'tutor', 'school', 'lessons', 'instructor', 'coach', 'learning', 'mentor'],
      'creative': ['design', 'art', 'artist', 'graphics', 'logo', 'writer', 'video', 'photo', 'creator'],
      'design': ['design', 'art', 'artist', 'graphics', 'logo', 'writer', 'video', 'photo', 'creator'],
      'business': ['consultant', 'finance', 'accounting', 'marketing', 'startup', 'management', 'agent'],
      'consulting': ['consultant', 'finance', 'accounting', 'marketing', 'startup', 'management', 'agent'],
      'beauty': ['salon', 'hair', 'nails', 'makeup', 'spa', 'massage', 'wellness', 'barber', 'stylist'],
      'wellness': ['salon', 'hair', 'nails', 'makeup', 'spa', 'massage', 'wellness', 'barber', 'stylist'],
      'transport': ['driver', 'taxi', 'delivery', 'truck', 'moving', 'logistics', 'shipping', 'freight', 'transportation'],
      'delivery': ['driver', 'taxi', 'delivery', 'truck', 'moving', 'logistics', 'shipping', 'freight', 'transportation'],
      'events': ['dj', 'catering', 'party', 'wedding', 'planner', 'entertainment', 'music', 'band', 'mc'],
      'entertainment': ['dj', 'catering', 'party', 'wedding', 'planner', 'entertainment', 'music', 'band', 'mc'],
      'home': ['cleaning', 'maid', 'housekeeper', 'garden', 'landscaping', 'pest', 'laundry', 'cleaner'],
      'services': ['cleaning', 'maid', 'housekeeper', 'garden', 'landscaping', 'pest', 'laundry', 'cleaner'],
    };

    final expandedTokens = <String>{...tokens};
    for (var token in tokens) {
      if (synonyms.containsKey(token)) {
        expandedTokens.addAll(synonyms[token]!);
      }
    }
    return expandedTokens.toList();
  }

  Future<List<UserModel>> searchProviders(String query) async {
    try {
      final snapshot = await _firestore.collection('users').get();

      final allUsers = snapshot.docs.map((doc) {
        final data = doc.data();
        data['userId'] = doc.id;
        return UserModel.fromMap(data);
      }).toList();

      if (query.trim().isEmpty) {
        return allUsers;
      }

      final searchTokens = _getSearchTokens(query);
      
      return allUsers.where((user) {
        final profile = user.providerProfile;
        final info = user.personalInfo;
        final searchableText = [
          user.displayName,
          user.email,
          info.firstName,
          info.lastName,
          info.phoneNumber,
          profile.professionTitle,
          profile.category,
          profile.bio,
          ...profile.skills
        ].join(' ').toLowerCase();

        final lowerQuery = query.toLowerCase();
        if (searchableText.contains(lowerQuery)) return true;
        return searchTokens.any((token) => searchableText.contains(token));
      }).toList();
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  Future<List<UserModel>> searchAllUsers(String query) async {
    try {
      final snapshot = await _firestore.collection('users').get();

      final allUsers = snapshot.docs.map((doc) {
        final data = doc.data();
        data['userId'] = doc.id;
        return UserModel.fromMap(data);
      }).toList();

      if (query.trim().isEmpty) return allUsers;

      final lowerQuery = query.toLowerCase();
      return allUsers.where((user) {
        final info = user.personalInfo;
        final searchableText = [
          user.displayName,
          user.email,
          info.firstName,
          info.lastName,
          info.phoneNumber,
          user.providerProfile.professionTitle,
          user.providerProfile.category,
        ].join(' ').toLowerCase();
        return searchableText.contains(lowerQuery);
      }).toList();
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  Future<List<String>> getLiveCategories() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('providerProfile.isActive', isEqualTo: true)
          .get();

      final categories = <String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('providerProfile')) {
          final profile = data['providerProfile'] as Map<String, dynamic>;
          final category = profile['category'] as String?;
          if (category != null && category.trim().isNotEmpty) {
            categories.add(category.trim());
          }
        }
      }
      return categories.toList()..sort();
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  Future<void> createListing(ListingModel listing) async {
    try {
      final docRef = _firestore.collection('listings').doc();
      final finalListing = ListingModel(
        id: docRef.id,
        providerId: listing.providerId,
        providerName: listing.providerName,
        providerImage: listing.providerImage,
        title: listing.title,
        description: listing.description,
        price: listing.price,
        listingType: listing.listingType,
        billingType: listing.billingType,
        category: listing.category,
        images: listing.images,
        stockCount: listing.stockCount,
        createdAt: DateTime.now(),
      );

      await _firestore.runTransaction((transaction) async {
        final map = finalListing.toMap();
        map['createdAt'] = FieldValue.serverTimestamp();
        transaction.set(docRef, map);
        if (listing.providerId.trim().isNotEmpty) {
          final providerRef = _firestore.collection('users').doc(listing.providerId);
          transaction.set(providerRef, {
            'providerProfile': {
              'listingsCount': FieldValue.increment(1),
            }
          }, SetOptions(merge: true));
        }
      });
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  Future<void> updateListing(ListingModel listing) async {
    try {
      await _firestore.collection('listings').doc(listing.id).set(listing.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  Future<void> deleteListing(String listingId, String providerId) async {
    try {
      final docRef = _firestore.collection('listings').doc(listingId);
      await _firestore.runTransaction((transaction) async {
        transaction.delete(docRef);
        if (providerId.trim().isNotEmpty) {
          final providerRef = _firestore.collection('users').doc(providerId);
          transaction.set(providerRef, {
            'providerProfile': {
              'listingsCount': FieldValue.increment(-1),
            }
          }, SetOptions(merge: true));
        }
      });
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  Future<List<ListingModel>> fetchListingsByProvider(String providerId) async {
    try {
      final snapshot = await _firestore
          .collection('listings')
          .where('providerId', isEqualTo: providerId)
          .get();
      return snapshot.docs.map((doc) => ListingModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  Future<List<ListingModel>> fetchAllListings({int limit = 20}) async {
    try {
      final snapshot = await _firestore.collection('listings').orderBy('createdAt', descending: true).limit(limit).get();
      return snapshot.docs.map((doc) => ListingModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  Future<List<ListingModel>> searchListings(String query) async {
    try {
      final all = await fetchAllListings(limit: 100);
      if (query.trim().isEmpty) return all;
      
      final searchTokens = _getSearchTokens(query);
      
      return all.where((l) {
        final searchableText = [
          l.title,
          l.description,
          l.category,
          l.providerName,
        ].join(' ').toLowerCase();

        if (searchableText.contains(query.toLowerCase())) return true;
        return searchTokens.any((token) => searchableText.contains(token));
      }).toList();
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  Future<List<UserModel>> fetchTopProviders({int limit = 10, String? businessType}) async {
    try {
      Query query = _firestore.collection('users');
      
      if (businessType != null) {
        query = query.where('providerProfile.businessType', isEqualTo: businessType);
      } else {
        query = query.where('providerProfile.isActive', isEqualTo: true);
      }

      final snapshot = await query.limit(50).get();

      final users = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['userId'] = doc.id;
        return UserModel.fromMap(data);
      }).where((u) => u.providerProfile.professionTitle.isNotEmpty || u.providerProfile.category.isNotEmpty).toList();

      users.sort((a, b) {
        final scoreA = (a.providerProfile.ratingAsProvider * 4.0) + (a.providerProfile.totalJobsCompleted * 0.6);
        final scoreB = (b.providerProfile.ratingAsProvider * 4.0) + (b.providerProfile.totalJobsCompleted * 0.6);
        return scoreB.compareTo(scoreA);
      });

      return users.take(limit).toList();
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }
}

