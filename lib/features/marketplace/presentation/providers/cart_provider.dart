import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/cart_model.dart';
import '../../domain/models/listing_model.dart';

class CartNotifier extends Notifier<Cart> {
  @override
  Cart build() {
    return Cart();
  }

  void addItem(ListingModel listing) {
    final existingIndex = state.items.indexWhere((item) => item.listing.id == listing.id);
    if (existingIndex >= 0) {
      final currentItem = state.items[existingIndex];
      final updatedItem = currentItem.copyWith(quantity: currentItem.quantity + 1);
      final newItems = List<CartItem>.from(state.items);
      newItems[existingIndex] = updatedItem;
      state = Cart(items: newItems);
    } else {
      state = Cart(items: [...state.items, CartItem(listing: listing)]);
    }
  }

  void removeItem(String listingId) {
    final newItems = state.items.where((item) => item.listing.id != listingId).toList();
    state = Cart(items: newItems);
  }

  void updateQuantity(String listingId, int quantity) {
    if (quantity <= 0) {
      removeItem(listingId);
      return;
    }
    final existingIndex = state.items.indexWhere((item) => item.listing.id == listingId);
    if (existingIndex >= 0) {
      final updatedItem = state.items[existingIndex].copyWith(quantity: quantity);
      final newItems = List<CartItem>.from(state.items);
      newItems[existingIndex] = updatedItem;
      state = Cart(items: newItems);
    }
  }

  void clearCart() {
    state = Cart();
  }
}

final cartProvider = NotifierProvider<CartNotifier, Cart>(() {
  return CartNotifier();
});
