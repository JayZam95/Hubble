
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppCategories {
  final List<String> serviceCategories;
  final List<String> retailCategories;

  const AppCategories({
    required this.serviceCategories,
    required this.retailCategories,
  });

  factory AppCategories.fromMap(Map<String, dynamic> map) {
    return AppCategories(
      serviceCategories: List<String>.from(map['serviceCategories'] ?? []),
      retailCategories: List<String>.from(map['retailCategories'] ?? []),
    );
  }
}

// Hardcoded defaults in case database connection fails or document doesn't exist yet
final defaultAppCategories = AppCategories(
  serviceCategories: [
    'Plumbing & Home Repair',
    'Education & Tutoring',
    'Business Consulting',
    'Technology Support',
    'Medical & Healthcare',
    'Creative & Design',
    'Beauty & Wellness',
    'Transport & Delivery',
    'Events & Entertainment',
    'Other Service'
  ],
  retailCategories: [
    'Clothing & Apparel',
    'Electronics & Gadgets',
    'Groceries & Food',
    'Home & Furniture',
    'Health & Beauty Products',
    'Sports & Outdoors',
    'Hardware & Tools',
    'Other Retail'
  ],
);

final appCategoriesProvider = StreamProvider<AppCategories>((ref) {
  return FirebaseFirestore.instance
      .collection('metadata')
      .doc('app_categories')
      .snapshots()
      .map((snapshot) {
    if (snapshot.exists && snapshot.data() != null) {
      return AppCategories.fromMap(snapshot.data()!);
    }
    return defaultAppCategories;
  });
});

final categoryAdminProvider = Provider<CategoryAdminRepository>((ref) {
  return CategoryAdminRepository(FirebaseFirestore.instance);
});

class CategoryAdminRepository {
  final FirebaseFirestore _firestore;

  CategoryAdminRepository(this._firestore);

  Future<void> addCategory(String type, String newCategory) async {
    final docRef = _firestore.collection('metadata').doc('app_categories');
    final doc = await docRef.get();
    
    if (!doc.exists) {
      // Create it with defaults first
      await docRef.set({
        'serviceCategories': defaultAppCategories.serviceCategories,
        'retailCategories': defaultAppCategories.retailCategories,
      });
    }

    if (type == 'service') {
      await docRef.update({
        'serviceCategories': FieldValue.arrayUnion([newCategory])
      });
    } else {
      await docRef.update({
        'retailCategories': FieldValue.arrayUnion([newCategory])
      });
    }
  }

  Future<void> removeCategory(String type, String category) async {
    final docRef = _firestore.collection('metadata').doc('app_categories');
    
    if (type == 'service') {
      await docRef.update({
        'serviceCategories': FieldValue.arrayRemove([category])
      });
    } else {
      await docRef.update({
        'retailCategories': FieldValue.arrayRemove([category])
      });
    }
  }
}

