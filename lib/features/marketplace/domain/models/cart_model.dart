import 'listing_model.dart';

class CartItem {
  final ListingModel listing;
  final int quantity;

  CartItem({required this.listing, this.quantity = 1});

  CartItem copyWith({
    ListingModel? listing,
    int? quantity,
  }) {
    return CartItem(
      listing: listing ?? this.listing,
      quantity: quantity ?? this.quantity,
    );
  }
}

class Cart {
  final List<CartItem> items;

  Cart({this.items = const []});

  double get totalPrice {
    return items.fold(0.0, (total, item) => total + (item.listing.price * item.quantity));
  }
}
