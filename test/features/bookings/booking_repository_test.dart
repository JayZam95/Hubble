import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hubble/features/bookings/domain/models/booking_model.dart';
import 'package:hubble/features/bookings/data/repositories/booking_repository.dart';

// Safe manual mock setup to avoid codegen dependency warnings
class MockFirebaseFirestore extends Fake implements FirebaseFirestore {}

// ignore: subtype_of_sealed_class
class FakeDocumentSnapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic>? _data;
  final bool _exists;

  FakeDocumentSnapshot(this._data, this._exists);

  @override
  bool get exists => _exists;

  @override
  Map<String, dynamic>? data() => _data;
}

// ignore: subtype_of_sealed_class, must_be_immutable
class FakeDocumentReference extends Fake implements DocumentReference<Map<String, dynamic>> {
  final FakeDocumentSnapshot snapshot;
  Map<String, dynamic>? updatedData;

  FakeDocumentReference(this.snapshot);

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    return snapshot;
  }

  @override
  Future<void> update(Map<Object?, Object?> data) async {
    updatedData = data.cast<String, dynamic>();
  }
}

// ignore: subtype_of_sealed_class
class FakeCollectionReference extends Fake implements CollectionReference<Map<String, dynamic>> {
  final FakeDocumentReference docRef;

  FakeCollectionReference(this.docRef);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return docRef;
  }
}

class FakeFirestore extends Fake implements FirebaseFirestore {
  final FakeCollectionReference collectionRef;

  FakeFirestore(this.collectionRef);

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return collectionRef;
  }
}

void main() {
  group('BookingRepository Unit Tests', () {
    test('updateBookingStatus rejects client when trying to accept booking', () async {
      final snapshot = FakeDocumentSnapshot({
        'clientId': 'client_111',
        'providerId': 'provider_222',
        'status': 'PENDING',
      }, true);
      final docRef = FakeDocumentReference(snapshot);
      final collection = FakeCollectionReference(docRef);
      final firestore = FakeFirestore(collection);
      final repository = BookingRepository(firestore: firestore);

      expect(
        () => repository.updateBookingStatus(
          bookingId: 'booking_123',
          userId: 'client_111',
          newStatus: BookingStatus.ACCEPTED,
        ),
        throwsA(predicate((e) => e.toString().contains('Client can only transition status to CANCELLED'))),
      );
    });

    test('updateBookingStatus rejects provider when trying to transition back to PENDING', () async {
      final snapshot = FakeDocumentSnapshot({
        'clientId': 'client_111',
        'providerId': 'provider_222',
        'status': 'ACCEPTED',
      }, true);
      final docRef = FakeDocumentReference(snapshot);
      final collection = FakeCollectionReference(docRef);
      final firestore = FakeFirestore(collection);
      final repository = BookingRepository(firestore: firestore);

      expect(
        () => repository.updateBookingStatus(
          bookingId: 'booking_123',
          userId: 'provider_222',
          newStatus: BookingStatus.PENDING,
        ),
        throwsA(predicate((e) => e.toString().contains('Provider cannot transition status back to PENDING'))),
      );
    });

    test('updateBookingStatus rejects unauthorized user completely', () async {
      final snapshot = FakeDocumentSnapshot({
        'clientId': 'client_111',
        'providerId': 'provider_222',
        'status': 'PENDING',
      }, true);
      final docRef = FakeDocumentReference(snapshot);
      final collection = FakeCollectionReference(docRef);
      final firestore = FakeFirestore(collection);
      final repository = BookingRepository(firestore: firestore);

      expect(
        () => repository.updateBookingStatus(
          bookingId: 'booking_123',
          userId: 'unauthorized_333',
          newStatus: BookingStatus.ACCEPTED,
        ),
        throwsA(predicate((e) => e.toString().contains('User not authorized to modify this booking'))),
      );
    });
  });
}
