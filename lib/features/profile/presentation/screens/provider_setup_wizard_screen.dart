import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/category_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/image_utils.dart';

class ProviderSetupWizardScreen extends ConsumerStatefulWidget {
  const ProviderSetupWizardScreen({super.key});

  @override
  ConsumerState<ProviderSetupWizardScreen> createState() => _ProviderSetupWizardScreenState();
}

class _ProviderSetupWizardScreenState extends ConsumerState<ProviderSetupWizardScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  String? _businessType; // 'shop' or 'individual'
  String? _category;
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();

  File? _avatarImage;
  final List<File> _portfolioImages = [];

  bool _isSaving = false;

  final List<String> _storeCategories = [
    "Clothing & Apparel",
    "Electronics & Gadgets",
    "Groceries & Food",
    "Home & Furniture",
    "Health & Beauty Products",
    "Automotive Parts",
    "Books & Stationery",
    "Sports & Outdoors",
    "Hardware & Tools",
    "Other Retail"
  ];

  final List<String> _serviceCategories = [
    "Plumbing & Home Repair",
    "Education & Tutoring",
    "Business Consulting",
    "Technology Support",
    "Medical & Healthcare",
    "Legal Services",
    "Beauty & Wellness",
    "Transport & Delivery",
    "Events & Entertainment",
    "Creative & Design",
    "Cleaning Services",
    "Other Services"
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).user;
      if (user != null) {
        if (user.providerProfile.businessType.isNotEmpty) {
          _businessType = user.providerProfile.businessType;
        }
        if (user.providerProfile.category.isNotEmpty) {
          _category = user.providerProfile.category;
        }
        if (user.providerProfile.professionTitle.isNotEmpty) {
          _titleController.text = user.providerProfile.professionTitle;
        }
        if (user.providerProfile.hourlyRate > 0) {
          _rateController.text = user.providerProfile.hourlyRate.toStringAsFixed(0);
        }
        if (mounted) setState(() {});
      }
    });
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _avatarImage = File(pickedFile.path));
    }
  }

  Future<void> _pickPortfolioImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _portfolioImages.addAll(pickedFiles.map((f) => File(f.path)));
      });
    }
  }

  void _removePortfolioImage(int index) {
    setState(() => _portfolioImages.removeAt(index));
  }

  Future<void> _finishSetup() async {
    final user = ref.read(authStateProvider).user;
    if (user == null || _businessType == null || _category == null) return;

    final title = _titleController.text.trim();
    final rate = double.tryParse(_rateController.text.trim()) ?? 0.0;

    setState(() => _isSaving = true);
    try {
      String? avatarUrl = user.personalInfo.profileImageURL;
      if (_avatarImage != null) {
        avatarUrl = await ImageUtils.fileToBase64(_avatarImage!);
      }

      List<String> portfolioUrls = List.from(user.providerProfile.portfolioImages);
      if (_portfolioImages.isNotEmpty) {
        final List<String> base64Images = [];
        for (var file in _portfolioImages) {
          final b64 = await ImageUtils.fileToBase64(file);
          if (b64 != null) base64Images.add(b64);
        }
        portfolioUrls.addAll(base64Images);
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        if (avatarUrl != null && avatarUrl.isNotEmpty) 'personalInfo.profileImageURL': avatarUrl,
        'providerProfile.isActive': true,
        'providerProfile.businessType': _businessType,
        'providerProfile.category': _category,
        'providerProfile.professionTitle': title,
        'providerProfile.hourlyRate': rate,
        'providerProfile.portfolioImages': portfolioUrls,
      });
      await ref.read(authStateProvider.notifier).refreshUser();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Provider profile updated!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () {
            if (_currentPage == 0) {
              Navigator.pop(context);
            } else {
              _previousPage();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage >= index ? AppColors.primary : (isDark ? Colors.white12 : Colors.black12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildStep1(isDark),
                  ref.watch(appCategoriesProvider).when(
                        data: (cats) => _buildStep2(isDark, cats),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, st) => Center(child: Text('Error loading categories')),
                      ),
                  _buildStep3(isDark),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isSaving ? null : () {
                    if (_currentPage == 0) {
                      if (_businessType != null) {
                        // Clear category if business type changes
                        if (_businessType == 'shop' && !_storeCategories.contains(_category)) {
                          _category = null;
                        } else if (_businessType == 'individual' && !_serviceCategories.contains(_category)) {
                          _category = null;
                        }
                        _nextPage();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an option.')));
                      }
                    } else if (_currentPage == 1) {
                      if (_category != null) {
                        _nextPage();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category.')));
                      }
                    } else {
                      if (_titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a title/name.')));
                      } else {
                        _finishSetup();
                      }
                    }
                  },
                  child: _isSaving 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          _currentPage == 2 ? 'Finish Setup' : 'Next',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What are you offering?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 12),
          Text('Choose the type of business you want to run on Hubble.', style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 32),
          _buildSelectionCard(
            title: 'Physical Goods / Store',
            subtitle: 'Sell products like electronics, clothing, groceries, etc.',
            icon: Icons.storefront,
            isSelected: _businessType == 'shop',
            isDark: isDark,
            onTap: () => setState(() => _businessType = 'shop'),
          ),
          const SizedBox(height: 16),
          _buildSelectionCard(
            title: 'Professional Services',
            subtitle: 'Offer services like plumbing, tutoring, consulting, etc.',
            icon: Icons.business_center,
            isSelected: _businessType == 'individual',
            isDark: isDark,
            onTap: () => setState(() => _businessType = 'individual'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(bool isDark, AppCategories appCategories) {
    final categories = _businessType == 'shop' ? appCategories.retailCategories : appCategories.serviceCategories;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select your Industry', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 12),
          Text('Choose a category that best describes your offerings.', style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = _category == cat;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : (isDark ? AppColors.bgDarkCard : Colors.white),
                      border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 2),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(cat, style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isDark ? Colors.white : Colors.black87)),
                        if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Final Details', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 12),
            Text('Just a few more details to get your storefront ready.', style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black54)),
            const SizedBox(height: 32),
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: isDark ? AppColors.bgDarkCard : Colors.grey[200],
                      backgroundImage: _avatarImage != null
                          ? FileImage(_avatarImage!)
                          : null,
                      child: _avatarImage == null
                          ? Icon(Icons.person, size: 50, color: isDark ? Colors.white54 : Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: _businessType == 'shop' ? 'Store Name' : 'Professional Title',
                hintText: _businessType == 'shop' ? 'e.g. Acme Electronics' : 'e.g. Expert Plumber',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? AppColors.bgDarkCard : Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _rateController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Base Hourly Rate (Optional)',
                hintText: 'e.g. 150',
                suffixText: 'ZMW',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? AppColors.bgDarkCard : Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text('Portfolio Images', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ..._portfolioImages.asMap().entries.map((e) {
                  int idx = e.key;
                  File file = e.value;
                  return Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: GestureDetector(
                          onTap: () => _removePortfolioImage(idx),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                GestureDetector(
                  onTap: _pickPortfolioImages,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.bgDarkCard : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 2),
                    ),
                    child: const Icon(Icons.add_a_photo, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : (isDark ? AppColors.bgDarkCard : Colors.white),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : (isDark ? Colors.white12 : Colors.black12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
