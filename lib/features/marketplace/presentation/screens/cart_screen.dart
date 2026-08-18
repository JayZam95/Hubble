import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/presentation/widgets/animated_empty_state.dart';
import '../providers/cart_provider.dart';
import '../../../wallet/presentation/providers/payment_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/presentation/widgets/hubble_image.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  Future<void> _handleCheckout(BuildContext context, WidgetRef ref, double total, {required bool useEscrow}) async {
    final checkoutId = 'checkout-${DateTime.now().millisecondsSinceEpoch}';
    final user = ref.read(authStateProvider).user;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to checkout')),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (useEscrow) {
        await ref.read(paymentControllerProvider.notifier).holdInEscrow(total, checkoutId);
      }

      final cart = ref.read(cartProvider);
      final itemsBySeller = <String, List<dynamic>>{};
      for (final item in cart.items) {
        final sellerId = item.listing.providerId;
        itemsBySeller.putIfAbsent(sellerId, () => []).add(item);
      }

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (final entry in itemsBySeller.entries) {
        final sellerId = entry.key;
        final items = entry.value;
        final orderId = firestore.collection('orders').doc().id;
        
        final orderTotal = items.fold(0.0, (totalAcc, item) => totalAcc + (item.listing.price * item.quantity));
        
        final orderItems = items.map((item) => {
          'listingId': item.listing.id,
          'title': item.listing.title,
          'price': item.listing.price,
          'quantity': item.quantity,
          'imageUrl': item.listing.images.isNotEmpty ? item.listing.images.first : '',
        }).toList();

        final orderData = {
          'buyerId': user.uid,
          'sellerId': sellerId,
          'items': orderItems,
          'totalAmount': orderTotal,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'checkoutId': checkoutId,
          'paymentMethod': useEscrow ? 'escrow' : 'cash',
        };

        batch.set(firestore.collection('orders').doc(orderId), orderData);
      }

      await batch.commit();

      if (context.mounted) {
        Navigator.pop(context); // hide loading
        ref.read(cartProvider.notifier).clearCart();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checkout successful!')),
        );
        Navigator.pop(context); // return to previous screen
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // hide loading
        String errorMsg = e.toString();
        if (errorMsg.contains('Insufficient funds') || errorMsg.contains('insufficient-funds')) {
          errorMsg = 'Insufficient funds in wallet. Please top up your wallet or choose Cash on Delivery.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    }
  }

  void _showPaymentSelector(BuildContext context, WidgetRef ref, double total) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Payment Method',
                  style: AppTextStyles.heading2,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet, color: AppColors.primary),
                  title: const Text('Pay with Escrow (Wallet)'),
                  subtitle: const Text('Funds will be held securely until delivery.'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _handleCheckout(context, ref, total, useEscrow: true);
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.money, color: Colors.green),
                  title: const Text('Cash on Delivery'),
                  subtitle: const Text('Pay directly when your items arrive.'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _handleCheckout(context, ref, total, useEscrow: false);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : Colors.white,
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        backgroundColor: isDark ? AppColors.bgDark : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: isDark ? AppColors.bgDarkCard : Colors.white,
        onRefresh: () async {
          ref.invalidate(cartProvider);
          await Future.delayed(const Duration(milliseconds: 400));
        },
        child: cart.items.isEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.75,
                  alignment: Alignment.center,
                  child: AnimatedEmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Your Cart is Empty',
                    subtitle: 'Looks like you haven\'t added anything to your cart yet.',
                    actionLabel: 'Explore Services',
                    onAction: () => Navigator.pop(context),
                  ),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      final listing = item.listing;
                      
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.bgDarkCard : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                        ),
                        child: Row(
                          children: [
                            listing.images.isNotEmpty && listing.images.first.isNotEmpty
                                ? HubbleImage(
                                    imagePath: listing.images.first,
                                    width: 80,
                                    height: 80,
                                    borderRadius: BorderRadius.circular(12),
                                  )
                                : Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.shopping_bag, color: isDark ? Colors.white54 : Colors.black54),
                                  ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    listing.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'K ${listing.price.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _QuantityButton(
                                        icon: Icons.remove,
                                        onTap: () {
                                          ref.read(cartProvider.notifier).updateQuantity(listing.id, item.quantity - 1);
                                        },
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          '${item.quantity}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.black,
                                          ),
                                        ),
                                      ),
                                      _QuantityButton(
                                        icon: Icons.add,
                                        onTap: () {
                                          ref.read(cartProvider.notifier).updateQuantity(listing.id, item.quantity + 1);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                ref.read(cartProvider.notifier).removeItem(listing.id);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // Checkout Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.bgDarkCard : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            Text(
                              'K ${cart.totalPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => _showPaymentSelector(context, ref, cart.totalPrice),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Checkout',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.black12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
