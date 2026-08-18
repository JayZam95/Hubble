
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/providers/category_provider.dart';

final trendingCategoriesProvider = StreamProvider<List<String>>((ref) {
  final firestore = FirebaseFirestore.instance;
  
  // We listen to the dynamic categories as the base
  final baseCategoriesAsync = ref.watch(appCategoriesProvider);
  
  return firestore.collection('metadata').doc('trending_categories').snapshots().map((snapshot) {
    final baseCategories = baseCategoriesAsync.value?.serviceCategories ?? [];
    if (!snapshot.exists || snapshot.data() == null) {
      return baseCategories;
    }
    
    final counts = snapshot.data() as Map<String, dynamic>;
    
    final sortedCategories = List<String>.from(baseCategories);
    sortedCategories.sort((a, b) {
      final countA = (counts[a] as num?)?.toInt() ?? 0;
      final countB = (counts[b] as num?)?.toInt() ?? 0;
      
      if (countA == countB) {
        return a.compareTo(b);
      }
      return countB.compareTo(countA);
    });
    
    return sortedCategories;
  });
});

