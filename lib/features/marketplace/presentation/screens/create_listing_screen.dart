import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/presentation/widgets/hubble_image.dart';
import '../../../../core/providers/category_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/listing_model.dart';
import '../../data/repositories/marketplace_repository.dart';
import '../providers/marketplace_provider.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Core Fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _stockController = TextEditingController(text: '1');

  // Service Specifics
  String? _estimatedDuration = '1 Hour';
  bool _travelsToClient = false;
  final _travelRadiusController = TextEditingController(text: '10');
  bool _isVariablePrice = false;

  // Real Estate / Property Specifics
  int _bedrooms = 2;
  int _bathrooms = 1;
  final _propertyAreaController = TextEditingController(text: '120');
  bool _isFurnished = false;
  final Set<String> _selectedAmenities = {'WiFi', '24/7 Security', 'Borehole Water'};

  // Vehicle Specifics
  final _vehicleMakeController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleYearController = TextEditingController(text: '2020');
  final _mileageController = TextEditingController(text: '45000');
  String _transmission = 'Automatic';
  String _fuelType = 'Petrol';

  // Professional & Trades Specifics
  final _qualificationController = TextEditingController();
  final _warrantyController = TextEditingController(text: '3 Months');
  bool _emergencyAvailable = false;

  // Electronics Specifics
  final _brandController = TextEditingController();
  String _itemCondition = 'Brand New';
  final _storageCapacityController = TextEditingController();

  // Listing Category & Billing Type
  ListingType _selectedListingType = ListingType.product;
  BillingType _selectedBillingType = BillingType.perItem;

  final List<File> _selectedImages = [];
  bool _isLoading = false;

  static const Map<String, String> _keywordMap = {
    'phone': 'Electronics & Mobile', 'iphone': 'Electronics & Mobile', 'laptop': 'Electronics & Mobile', 'tv': 'Electronics & Mobile',
    'house': 'Property & Rentals', 'apartment': 'Property & Rentals', 'room': 'Property & Rentals', 'rent': 'Property & Rentals',
    'car': 'Vehicles & Transportation', 'truck': 'Vehicles & Transportation', 'cab': 'Vehicles & Transportation', 'taxi': 'Vehicles & Transportation',
    'plumb': 'Home Repair & Trades', 'pipe': 'Home Repair & Trades', 'electric': 'Home Repair & Trades', 'wire': 'Home Repair & Trades',
    'doctor': 'Medical & Healthcare', 'nurse': 'Medical & Healthcare', 'lawyer': 'Legal & Financial', 'tax': 'Legal & Financial',
    'hair': 'Beauty & Spa', 'makeup': 'Beauty & Spa', 'barber': 'Beauty & Spa',
    'dress': 'Clothing & Apparel', 'shoes': 'Clothing & Apparel', 'shirt': 'Clothing & Apparel',
  };

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_suggestCategory);
    _descriptionController.addListener(_suggestCategory);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _stockController.dispose();
    _travelRadiusController.dispose();
    _propertyAreaController.dispose();
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _vehicleYearController.dispose();
    _mileageController.dispose();
    _qualificationController.dispose();
    _warrantyController.dispose();
    _brandController.dispose();
    _storageCapacityController.dispose();
    super.dispose();
  }

  void _suggestCategory() {
    final text = '${_titleController.text} ${_descriptionController.text}'.toLowerCase();
    for (var entry in _keywordMap.entries) {
      if (text.contains(entry.key)) {
        if (_categoryController.text != entry.value && !FocusScope.of(context).hasFocus) {
          setState(() {
            _categoryController.text = entry.value;
          });
        }
        break;
      }
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 60);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((e) => File(e.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields correctly.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authStateProvider).user;
      if (user == null) throw Exception("User not authenticated");

      final repo = MarketplaceRepository();

      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        final tempListingId = DateTime.now().millisecondsSinceEpoch.toString();
        imageUrls = await repo.uploadListingImages(tempListingId, _selectedImages);
      } else {
        imageUrls = [
          _selectedListingType == ListingType.service
              ? 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=600'
              : 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600'
        ];
      }

      // Format description with category specifics
      StringBuffer fullDescription = StringBuffer(_descriptionController.text.trim());

      final category = _categoryController.text.trim().toLowerCase();
      if (category.contains('property') || category.contains('real estate') || category.contains('rent')) {
        fullDescription.write('\n\n🏠 Property Details:\n- Bedrooms: $_bedrooms | Bathrooms: $_bathrooms\n- Area: ${_propertyAreaController.text} sqm\n- Furnished: ${_isFurnished ? "Yes" : "No"}\n- Amenities: ${_selectedAmenities.join(", ")}');
      } else if (category.contains('vehicle') || category.contains('auto') || category.contains('cab')) {
        fullDescription.write('\n\n🚗 Vehicle Specifications:\n- Make/Model: ${_vehicleMakeController.text} ${_vehicleModelController.text} (${_vehicleYearController.text})\n- Transmission: $_transmission | Fuel: $_fuelType\n- Mileage: ${_mileageController.text} km');
      } else if (category.contains('repair') || category.contains('trade') || category.contains('plumb')) {
        fullDescription.write('\n\n🛠️ Service Guarantee:\n- Warranty: ${_warrantyController.text}\n- 24/7 Emergency Callout: ${_emergencyAvailable ? "Available" : "Standard Hours"}');
      } else if (category.contains('electronic') || category.contains('mobile') || category.contains('hardware')) {
        fullDescription.write('\n\n📱 Hardware Specs:\n- Brand: ${_brandController.text}\n- Condition: $_itemCondition\n- Storage/Spec: ${_storageCapacityController.text}');
      }

      final newListing = ListingModel(
        id: '',
        providerId: user.uid,
        providerName: user.displayName,
        providerImage: user.personalInfo.profileImageURL,
        title: _titleController.text.trim(),
        description: fullDescription.toString(),
        price: double.parse(_priceController.text.trim()),
        listingType: _selectedListingType,
        billingType: _selectedBillingType,
        category: _categoryController.text.trim(),
        images: imageUrls,
        stockCount: _selectedListingType == ListingType.product ? (int.tryParse(_stockController.text.trim()) ?? 1) : 0,
        estimatedDuration: _selectedListingType == ListingType.service ? _estimatedDuration : null,
        travelsToClient: _selectedListingType == ListingType.service ? _travelsToClient : false,
        travelRadius: _selectedListingType == ListingType.service && _travelsToClient ? int.tryParse(_travelRadiusController.text.trim()) : null,
        isVariablePrice: _selectedListingType == ListingType.service ? _isVariablePrice : false,
        createdAt: DateTime.now(),
      );

      await repo.createListing(newListing);

      ref.invalidate(providerListingsProvider(user.uid));
      ref.invalidate(allListingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing published successfully! ✨'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish listing: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;

    final categoriesAsync = ref.watch(appCategoriesProvider);
    final List<String> availableCategories = categoriesAsync.hasValue
        ? [
            'Electronics & Mobile',
            'Property & Rentals',
            'Vehicles & Transportation',
            'Home Repair & Trades',
            'Medical & Healthcare',
            'Legal & Financial',
            'Beauty & Spa',
            'Clothing & Apparel',
            'Food & Groceries',
            'Education & Tutoring',
            ...categoriesAsync.value!.retailCategories,
            ...categoriesAsync.value!.serviceCategories,
          ].toSet().toList()
        : [
            'Electronics & Mobile',
            'Property & Rentals',
            'Vehicles & Transportation',
            'Home Repair & Trades',
            'Medical & Healthcare',
            'Legal & Financial',
            'Beauty & Spa',
            'Clothing & Apparel',
            'Food & Groceries',
            'Education & Tutoring',
          ];

    final currentCategory = _categoryController.text.trim().toLowerCase();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('New Storefront Listing', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Step 1: Listing Type Selector
                  _buildSectionHeader('1. Choose Listing Type'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTypeCard(
                          isDark: isDark,
                          title: 'Physical Product',
                          subtitle: 'Sell items, goods, or retail inventory',
                          icon: Icons.inventory_2_rounded,
                          isSelected: _selectedListingType == ListingType.product,
                          onTap: () {
                            setState(() {
                              _selectedListingType = ListingType.product;
                              _selectedBillingType = BillingType.perItem;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTypeCard(
                          isDark: isDark,
                          title: 'Service & Booking',
                          subtitle: 'Offer professional skills, repair, or consultations',
                          icon: Icons.handyman_rounded,
                          isSelected: _selectedListingType == ListingType.service,
                          onTap: () {
                            setState(() {
                              _selectedListingType = ListingType.service;
                              _selectedBillingType = BillingType.fixed;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Step 2: Basic Details
                  _buildSectionHeader('2. Item Information'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Title / Item Name *',
                      hintText: 'e.g. 3 Bedroom House in Mass Media or Solar Installation',
                      filled: true,
                      fillColor: cardColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Description & Scope of Work *',
                      hintText: 'Provide details, terms, inclusions, or specifications...',
                      filled: true,
                      fillColor: cardColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Price (ZMW) *',
                            prefixText: 'K ',
                            hintText: '450.00',
                            filled: true,
                            fillColor: cardColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<BillingType>(
                          value: _selectedBillingType,
                          decoration: InputDecoration(
                            labelText: 'Pricing Model',
                            filled: true,
                            fillColor: cardColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                          items: (_selectedListingType == ListingType.product
                                  ? [BillingType.perItem]
                                  : [BillingType.fixed, BillingType.hourly, BillingType.monthly])
                              .map((b) => DropdownMenuItem(
                                    value: b,
                                    child: Text(
                                      b == BillingType.perItem
                                          ? 'Per Unit'
                                          : b == BillingType.hourly
                                              ? 'Per Hour'
                                              : b == BillingType.monthly
                                                  ? 'Monthly'
                                                  : 'Flat Rate',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedBillingType = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Category Autocomplete Picker
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return availableCategories;
                      return availableCategories.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      setState(() {
                        _categoryController.text = selection;
                      });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      if (_categoryController.text.isNotEmpty && controller.text != _categoryController.text) {
                        controller.text = _categoryController.text;
                      }
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Category *',
                          hintText: 'Select or type category...',
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _categoryController.text = val;
                          });
                        },
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Step 3: Polymorphic Category-Specific Attributes
                  if (currentCategory.contains('property') || currentCategory.contains('real estate') || currentCategory.contains('rent')) ...[
                    _buildSectionHeader('3. 🏠 Property & Rental Specs'),
                    const SizedBox(height: 12),
                    _buildPropertySpecsCard(isDark, cardColor),
                    const SizedBox(height: 24),
                  ] else if (currentCategory.contains('vehicle') || currentCategory.contains('auto') || currentCategory.contains('cab')) ...[
                    _buildSectionHeader('3. 🚗 Vehicle & Fleet Specs'),
                    const SizedBox(height: 12),
                    _buildVehicleSpecsCard(isDark, cardColor),
                    const SizedBox(height: 24),
                  ] else if (currentCategory.contains('repair') || currentCategory.contains('trade') || currentCategory.contains('plumb')) ...[
                    _buildSectionHeader('3. 🛠️ Trade & Service Guarantee'),
                    const SizedBox(height: 12),
                    _buildTradeSpecsCard(isDark, cardColor),
                    const SizedBox(height: 24),
                  ] else if (currentCategory.contains('electronic') || currentCategory.contains('mobile') || currentCategory.contains('hardware')) ...[
                    _buildSectionHeader('3. 📱 Electronics & Hardware Specs'),
                    const SizedBox(height: 12),
                    _buildElectronicsSpecsCard(isDark, cardColor),
                    const SizedBox(height: 24),
                  ] else if (_selectedListingType == ListingType.product) ...[
                    _buildSectionHeader('3. 📦 Stock & Inventory'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Available Stock Quantity *',
                        hintText: 'e.g. 15',
                        filled: true,
                        fillColor: cardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Step 4: Photo Gallery
                  _buildSectionHeader('4. Item Photo Gallery'),
                  const SizedBox(height: 12),
                  _buildPhotoGalleryPicker(isDark, cardColor),

                  const SizedBox(height: 28),

                  // Publish Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      icon: const Icon(Icons.rocket_launch_rounded),
                      label: const Text('Publish Storefront Listing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.2),
    );
  }

  Widget _buildTypeCard({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? Colors.white10 : Colors.black12),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey, size: 28),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? AppColors.primary : null),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertySpecsCard(bool isDark, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bedrooms', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<int>(
                      value: _bedrooms,
                      items: [1, 2, 3, 4, 5, 6].map((e) => DropdownMenuItem(value: e, child: Text('$e Beds'))).toList(),
                      onChanged: (v) => setState(() => _bedrooms = v ?? 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Baths', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<int>(
                      value: _bathrooms,
                      items: [1, 2, 3, 4].map((e) => DropdownMenuItem(value: e, child: Text('$e Baths'))).toList(),
                      onChanged: (v) => setState(() => _bathrooms = v ?? 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _propertyAreaController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Property Area (Sqm)', hintText: '120'),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Fully Furnished', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            value: _isFurnished,
            onChanged: (v) => setState(() => _isFurnished = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          const Align(alignment: Alignment.centerLeft, child: Text('Included Amenities:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['WiFi', '24/7 Security', 'Borehole Water', 'Generator', 'Swimming Pool', 'Paved Yard'].map((amenity) {
              final isSel = _selectedAmenities.contains(amenity);
              return FilterChip(
                label: Text(amenity, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : null)),
                selected: isSel,
                selectedColor: AppColors.primary,
                onSelected: (sel) {
                  setState(() {
                    if (sel) {
                      _selectedAmenities.add(amenity);
                    } else {
                      _selectedAmenities.remove(amenity);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSpecsCard(bool isDark, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _vehicleMakeController,
                  decoration: const InputDecoration(labelText: 'Make (e.g. Toyota)', hintText: 'Toyota'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _vehicleModelController,
                  decoration: const InputDecoration(labelText: 'Model (e.g. Hilux)', hintText: 'Hilux'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _vehicleYearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Year', hintText: '2020'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _mileageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Mileage (km)', hintText: '45000'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _transmission,
                  decoration: const InputDecoration(labelText: 'Transmission'),
                  items: ['Automatic', 'Manual'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _transmission = v ?? 'Automatic'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _fuelType,
                  decoration: const InputDecoration(labelText: 'Fuel Type'),
                  items: ['Petrol', 'Diesel', 'Hybrid', 'Electric'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _fuelType = v ?? 'Petrol'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTradeSpecsCard(bool isDark, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          TextFormField(
            controller: _warrantyController,
            decoration: const InputDecoration(labelText: 'Workmanship Warranty', hintText: 'e.g. 3 Months Guarantee'),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text('24/7 Emergency Callout Available', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: const Text('Provider accepts immediate emergency dispatches'),
            value: _emergencyAvailable,
            onChanged: (v) => setState(() => _emergencyAvailable = v),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildElectronicsSpecsCard(bool isDark, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _brandController,
                  decoration: const InputDecoration(labelText: 'Brand / Manufacturer', hintText: 'Samsung / Apple'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _itemCondition,
                  decoration: const InputDecoration(labelText: 'Item Condition'),
                  items: ['Brand New', 'Like New', 'Refurbished', 'Fair'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _itemCondition = v ?? 'Brand New'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _storageCapacityController,
            decoration: const InputDecoration(labelText: 'Storage & RAM Specs', hintText: 'e.g. 256GB SSD, 16GB RAM'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGalleryPicker(bool isDark, Color cardColor) {
    return Column(
      children: [
        if (_selectedImages.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(_selectedImages[index], width: 100, height: 100, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _pickImages,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: const Icon(Icons.add_a_photo_rounded),
          label: Text(_selectedImages.isEmpty ? 'Select High-Res Item Photos' : 'Add More Photos (${_selectedImages.length})'),
        ),
      ],
    );
  }
}
