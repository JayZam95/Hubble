import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/listing_model.dart';
import '../../../../core/errors/app_exception.dart';
import 'marketplace_repository.dart';

class ListingRepository {
  final FirebaseFirestore _firestore;
  final MarketplaceRepository _marketplaceRepository;

  ListingRepository({
    FirebaseFirestore? firestore,
    MarketplaceRepository? marketplaceRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _marketplaceRepository = marketplaceRepository ?? MarketplaceRepository(firestore: firestore);

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

  Stream<ListingModel?> getListingStream(String listingId) {
    return _firestore
        .collection('listings')
        .doc(listingId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return ListingModel.fromMap(snapshot.data()!, snapshot.id);
    }).handleError((error) {
      throw AppException.fromFirebaseException(error);
    });
  }

  Future<void> createListing(ListingModel listing) async {
    try {
      await _marketplaceRepository.createListing(listing);
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  Future<void> updateListing(ListingModel listing) async {
    try {
      await _marketplaceRepository.updateListing(listing);
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  Future<void> deleteListing(String listingId, String providerId) async {
    try {
      await _marketplaceRepository.deleteListing(listingId, providerId);
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  Future<List<ListingModel>> fetchListingsByProvider(String providerId) async {
    try {
      return await _marketplaceRepository.fetchListingsByProvider(providerId);
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  Future<List<ListingModel>> fetchAllListings({int limit = 20}) async {
    try {
      return await _marketplaceRepository.fetchAllListings(limit: limit);
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  Future<List<String>> uploadListingImages(String listingId, List<File> imageFiles) async {
    try {
      return await _marketplaceRepository.uploadListingImages(listingId, imageFiles);
    } catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }
}
