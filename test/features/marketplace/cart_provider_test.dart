import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubble/features/marketplace/domain/models/cart_model.dart';
import 'package:hubble/features/marketplace/domain/models/listing_model.dart';
import 'package:hubble/features/marketplace/presentation/providers/cart_provider.dart';

void main() {
  late ListingModel item1;
  late ListingModel item2;
  late ListingModel item3;

  setUp(() {
    item1 = ListingModel(
      id: 'listing_1',
      providerId: 'provider_1',
      providerName: 'Solar Tech',
      providerImage: '',
      title: 'Solar Panel 200W',
      description: 'Monocrystalline panel',
      price: 1500.0,
      listingType: ListingType.product,
      billingType: BillingType.perItem,
      category: 'Electronics',
      images: ['https://example.com/solar.jpg'],
      stockCount: 10,
      createdAt: DateTime.now(),
    );

    item2 = ListingModel(
      id: 'listing_2',
      providerId: 'provider_2',
      providerName: 'Lusaka Plumbing',
      providerImage: '',
      title: 'Pipe Leak Repair',
      description: 'Fixing water leak in kitchen/bath',
      price: 250.0,
      listingType: ListingType.service,
      billingType: BillingType.fixed,
      category: 'Plumbing',
      images: [],
      stockCount: 1,
      createdAt: DateTime.now(),
    );

    item3 = ListingModel(
      id: 'listing_3',
      providerId: 'provider_1',
      providerName: 'Solar Tech',
      providerImage: '',
      title: 'Solar Inverter 3KW',
      description: 'Pure sine wave inverter',
      price: 3500.0,
      listingType: ListingType.product,
      billingType: BillingType.perItem,
      category: 'Electronics',
      images: [],
      stockCount: 5,
      createdAt: DateTime.now(),
    );
  });

  group('Cart Model Unit Tests', () {
    test('Cart initial state is empty with 0.0 total price', () {
      final cart = Cart();
      expect(cart.items, isEmpty);
      expect(cart.totalPrice, 0.0);
    });

    test('CartItem copyWith correctly updates quantity and listing', () {
      final cartItem = CartItem(listing: item1, quantity: 2);
      final updated = cartItem.copyWith(quantity: 5);

      expect(updated.listing.id, 'listing_1');
      expect(updated.quantity, 5);
    });

    test('Cart totalPrice calculates sum of (price * quantity)', () {
      final cart = Cart(items: [
        CartItem(listing: item1, quantity: 2), // 1500 * 2 = 3000
        CartItem(listing: item2, quantity: 3), // 250 * 3 = 750
      ]);

      expect(cart.totalPrice, 3750.0);
    });
  });

  group('CartNotifier Riverpod Tests (Add, Remove, Total Cost)', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial cart state in Riverpod provider is empty', () {
      final cart = container.read(cartProvider);
      expect(cart.items, isEmpty);
      expect(cart.totalPrice, 0.0);
    });

    test('addItem adds new item to cart with quantity 1', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(item1);

      final cart = container.read(cartProvider);
      expect(cart.items.length, 1);
      expect(cart.items.first.listing.id, 'listing_1');
      expect(cart.items.first.quantity, 1);
      expect(cart.totalPrice, 1500.0);
    });

    test('addItem increments quantity if item is already in cart', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(item1);
      notifier.addItem(item1);

      final cart = container.read(cartProvider);
      expect(cart.items.length, 1);
      expect(cart.items.first.quantity, 2);
      expect(cart.totalPrice, 3000.0);
    });

    test('addItem handles multiple distinct items and calculates total cost correctly', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(item1); // 1500 * 1 = 1500
      notifier.addItem(item2); // 250 * 1 = 250
      notifier.addItem(item3); // 3500 * 1 = 3500

      final cart = container.read(cartProvider);
      expect(cart.items.length, 3);
      expect(cart.totalPrice, 5250.0);
    });

    test('removeItem removes specified item from cart and recalculates total cost', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(item1); // 1500
      notifier.addItem(item2); // 250
      expect(container.read(cartProvider).totalPrice, 1750.0);

      notifier.removeItem('listing_1');

      final cart = container.read(cartProvider);
      expect(cart.items.length, 1);
      expect(cart.items.first.listing.id, 'listing_2');
      expect(cart.totalPrice, 250.0);
    });

    test('updateQuantity modifies item quantity and recalculates total cost', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(item1);
      notifier.updateQuantity('listing_1', 4);

      final cart = container.read(cartProvider);
      expect(cart.items.first.quantity, 4);
      expect(cart.totalPrice, 6000.0);
    });

    test('updateQuantity to 0 or negative removes the item from cart', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(item1);
      notifier.addItem(item2);

      notifier.updateQuantity('listing_1', 0);

      final cart = container.read(cartProvider);
      expect(cart.items.length, 1);
      expect(cart.items.first.listing.id, 'listing_2');
      expect(cart.totalPrice, 250.0);
    });

    test('clearCart empties all items and resets total cost to 0.0', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(item1);
      notifier.addItem(item2);
      expect(container.read(cartProvider).items, isNotEmpty);

      notifier.clearCart();

      final cart = container.read(cartProvider);
      expect(cart.items, isEmpty);
      expect(cart.totalPrice, 0.0);
    });
  });
}
