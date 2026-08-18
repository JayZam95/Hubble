import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/presentation/widgets/hubble_image.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../marketplace/domain/models/listing_model.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../../marketplace/presentation/screens/storefront_setup_screen.dart';

class ManageListingsScreen extends ConsumerStatefulWidget {
  const ManageListingsScreen({super.key});

  @override
  ConsumerState<ManageListingsScreen> createState() => _ManageListingsScreenState();
}

class _ManageListingsScreenState extends ConsumerState<ManageListingsScreen> {
  bool _isLoading = false;
  int _selectedFilterIndex = 0; // 0 = All, 1 = Products, 2 = Services
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateStock(ListingModel listing, int delta) async {
    final newStock = (listing.stockCount + delta).clamp(0, 9999);
    if (newStock == listing.stockCount) return;

    HapticFeedback.selectionClick();
    setState(() => _isLoading = true);

    try {
      final updatedListing = ListingModel(
        id: listing.id,
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
        stockCount: newStock,
        createdAt: listing.createdAt,
      );

      final repo = ref.read(marketplaceRepositoryProvider);
      await repo.updateListing(updatedListing);

      ref.invalidate(providerListingsProvider(listing.providerId));
      ref.invalidate(allListingsProvider);

      _showToast('Stock updated to $newStock units', isError: false);
    } catch (e) {
      _showToast('Failed to update stock: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddEditListingDialog({ListingModel? existingListing}) {
    final user = ref.read(authStateProvider).user;
    if (user == null) return;

    final isEdit = existingListing != null;

    final titleController = TextEditingController(text: existingListing?.title ?? '');
    final descController = TextEditingController(text: existingListing?.description ?? '');
    final priceController = TextEditingController(text: existingListing?.price.toString() ?? '');
    final stockController = TextEditingController(text: existingListing?.stockCount.toString() ?? '1');
    final categoryController = TextEditingController(text: existingListing?.category ?? user.providerProfile.category);

    ListingType selectedType = existingListing?.listingType ?? ListingType.product;
    BillingType selectedBilling = existingListing?.billingType ?? BillingType.fixed;
    final List<File> newImageFiles = [];

    final mockImages = [
      'https://images.unsplash.com/photo-1581092921461-eab62e97a780?w=500',
      'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=500',
      'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=500',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final isProduct = selectedType == ListingType.product;

            return AlertDialog(
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Icon(isEdit ? Icons.edit_note_rounded : Icons.add_business_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? 'Edit Catalog Listing' : 'Create Catalog Listing',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Listing Type Selector
                      DropdownButtonFormField<ListingType>(
                        initialValue: selectedType,
                        decoration: InputDecoration(
                          labelText: 'Catalog Category Type',
                          filled: true,
                          fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                        items: ListingType.values
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t == ListingType.product ? '📦 Physical Product' : '🛠️ Structured Service'),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedType = val;
                              selectedBilling = val == ListingType.product ? BillingType.perItem : BillingType.fixed;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Billing Model
                      DropdownButtonFormField<BillingType>(
                        initialValue: selectedBilling,
                        decoration: InputDecoration(
                          labelText: 'Pricing Model',
                          filled: true,
                          fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                        items: (isProduct
                                ? [BillingType.perItem]
                                : [BillingType.hourly, BillingType.fixed, BillingType.monthly])
                            .map((b) => DropdownMenuItem(
                                  value: b,
                                  child: Text(
                                    b == BillingType.perItem
                                        ? 'Per Item Price'
                                        : b == BillingType.hourly
                                            ? 'Hourly Rate (ZMW/hr)'
                                            : b == BillingType.monthly
                                                ? 'Monthly Subscription'
                                                : 'Flat Fixed Payout',
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedBilling = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: titleController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Title / Item Name',
                          hintText: 'e.g. SSD 1TB Drive or Full Pipe Repair',
                          filled: true,
                          fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: descController,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: 'Description & Specifications',
                          hintText: 'Provide details, specs, warranty, or delivery terms...',
                          filled: true,
                          fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Price (ZMW)',
                                hintText: '350.00',
                                prefixText: 'K ',
                                filled: true,
                                fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                          if (isProduct) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: stockController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Stock Units',
                                  hintText: '15',
                                  filled: true,
                                  fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: categoryController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Industry Category',
                          hintText: 'e.g. Home Repair, Electronics, Beauty',
                          filled: true,
                          fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Image Picker Button
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickMultiImage(imageQuality: 50);
                          if (picked.isNotEmpty) {
                            setDialogState(() {
                              newImageFiles.addAll(picked.map((e) => File(e.path)));
                            });
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                        label: Text('Upload Listing Photos (${newImageFiles.length} selected)'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final desc = descController.text.trim();
                    final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                    final stock = int.tryParse(stockController.text.trim()) ?? 0;
                    final category = categoryController.text.trim();

                    if (title.isEmpty || desc.isEmpty || price <= 0 || category.isEmpty) {
                      _showToast('Please fill out all required fields with valid values.', isError: true);
                      return;
                    }

                    Navigator.pop(context);
                    setState(() => _isLoading = true);

                    List<String> images = existingListing?.images ?? [];
                    if (images.isEmpty) {
                      images = [mockImages[title.hashCode.abs() % mockImages.length]];
                    }

                    final listing = ListingModel(
                      id: existingListing?.id ?? '',
                      providerId: user.uid,
                      providerName: user.displayName,
                      providerImage: user.personalInfo.profileImageURL,
                      title: title,
                      description: desc,
                      price: price,
                      listingType: selectedType,
                      billingType: selectedBilling,
                      category: category,
                      images: images,
                      stockCount: isProduct ? stock : 0,
                      createdAt: existingListing?.createdAt ?? DateTime.now(),
                    );

                    try {
                      final repo = ref.read(marketplaceRepositoryProvider);
                      if (isEdit) {
                        await repo.updateListing(listing);
                      } else {
                        await repo.createListing(listing);
                      }

                      ref.invalidate(providerListingsProvider(user.uid));
                      ref.invalidate(allListingsProvider);

                      _showToast(
                        isEdit ? 'Catalog item updated!' : 'Item successfully published to your storefront!',
                        isError: false,
                      );
                    } catch (e) {
                      _showToast('Failed to save listing: $e', isError: true);
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(isEdit ? 'Save Changes' : 'Publish Item', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteListing(ListingModel listing) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Catalog Item', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to remove "${listing.title}" from your store? Active escrow bookings will not be affected.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  final repo = ref.read(marketplaceRepositoryProvider);
                  await repo.deleteListing(listing.id, listing.providerId);

                  ref.invalidate(providerListingsProvider(listing.providerId));
                  ref.invalidate(allListingsProvider);

                  _showToast('Item deleted successfully.', isError: false);
                } catch (e) {
                  _showToast('Failed to delete listing: $e', isError: true);
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: const Text('Delete Item'),
            ),
          ],
        );
      },
    );
  }

  void _showToast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final user = ref.watch(authStateProvider).user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Access Denied. Please log in.')));
    }

    final listingsAsync = ref.watch(providerListingsProvider(user.uid));
    final profile = user.providerProfile;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Storefront Catalog Manager', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 28),
            onPressed: () => _showAddEditListingDialog(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditListingDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Listing', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Vendor Storefront Banner Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        child: HubbleImage(
                          imagePath: user.personalInfo.profileImageURL,
                          width: 56,
                          height: 56,
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile.professionTitle.isNotEmpty ? profile.professionTitle : 'Hubble Verified Seller',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                const SizedBox(width: 2),
                                Text(
                                  '${profile.ratingAsProvider.toStringAsFixed(1)} (${profile.reviewCount} reviews)',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const StorefrontSetupScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.storefront_rounded, size: 16),
                        label: const Text('Store Profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                // Filter Segment Chips
                Container(
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('All Catalog', 0),
                      const SizedBox(width: 8),
                      _buildFilterChip('📦 Products Only', 1),
                      const SizedBox(width: 8),
                      _buildFilterChip('🛠️ Services Only', 2),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Catalog Items List
                Expanded(
                  child: listingsAsync.when(
                    data: (allListings) {
                      final filtered = allListings.where((l) {
                        if (_selectedFilterIndex == 1) return l.listingType == ListingType.product;
                        if (_selectedFilterIndex == 2) return l.listingType == ListingType.service;
                        return true;
                      }).toList();

                      if (filtered.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.grid_view_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                                const SizedBox(height: 16),
                                const Text(
                                  'No catalog items match this filter.',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Tap the + button below to create new products or structured service packages.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final listing = filtered[index];
                          final isProduct = listing.listingType == ListingType.product;

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: HubbleImage(
                                        imagePath: listing.images.isNotEmpty ? listing.images.first : '',
                                        width: 64,
                                        height: 64,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            listing.title,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${listing.category} · ${isProduct ? "Item" : "Service"}',
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                          if (isProduct) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              'Stock Remaining: ${listing.stockCount}',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: listing.stockCount > 0 ? Colors.green : Colors.red),
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Text(
                                            'K ${listing.price.toStringAsFixed(0)}',
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(value: 'edit', child: Text('Edit Listing')),
                                        const PopupMenuItem(value: 'delete', child: Text('Delete Item', style: TextStyle(color: Colors.red))),
                                      ],
                                      onSelected: (val) {
                                        if (val == 'edit') {
                                          _showAddEditListingDialog(existingListing: listing);
                                        } else if (val == 'delete') {
                                          _confirmDeleteListing(listing);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                if (isProduct) ...[
                                  const Divider(height: 18),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            listing.stockCount > 0 ? Icons.inventory_rounded : Icons.warning_amber_rounded,
                                            size: 16,
                                            color: listing.stockCount > 5
                                                ? AppColors.success
                                                : (listing.stockCount > 0 ? Colors.amber : Colors.red),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            listing.stockCount > 0 ? 'Stock: ${listing.stockCount} left' : 'OUT OF STOCK',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: listing.stockCount > 5
                                                  ? AppColors.success
                                                  : (listing.stockCount > 0 ? Colors.amber : Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Quick Stock Counter Stepper (+ / -)
                                      Row(
                                        children: [
                                          const Text('Quick Adjust: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                          InkWell(
                                            onTap: () => _updateStock(listing, -1),
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: isDark ? Colors.white10 : Colors.grey.shade200,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(Icons.remove_rounded, size: 16),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            child: Text(
                                              '${listing.stockCount}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => _updateStock(listing, 1),
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Error loading catalog: $err')),
                  ),
                ),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.25),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedFilterIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          HapticFeedback.selectionClick();
          setState(() => _selectedFilterIndex = index);
        }
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: isSelected ? Colors.white : Colors.grey,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
