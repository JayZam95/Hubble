import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/presentation/widgets/hubble_image.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/marketplace_provider.dart';

class StorefrontSetupScreen extends ConsumerStatefulWidget {
  const StorefrontSetupScreen({super.key});

  @override
  ConsumerState<StorefrontSetupScreen> createState() => _StorefrontSetupScreenState();
}

class _StorefrontSetupScreenState extends ConsumerState<StorefrontSetupScreen> {
  final _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedBusinessType; // 'shop' or 'individual'
  String? _selectedCategory;
  
  final _titleController = TextEditingController();
  final _rateController = TextEditingController();
  final _bioController = TextEditingController();
  final List<String> _existingImages = [];
  final List<File> _newImages = [];

  final List<Map<String, dynamic>> _industries = [
    {'name': 'Medical', 'icon': Icons.medical_services},
    {'name': 'Technology', 'icon': Icons.computer},
    {'name': 'Trades', 'icon': Icons.handyman},
    {'name': 'Beauty', 'icon': Icons.face},
    {'name': 'Creative', 'icon': Icons.brush},
    {'name': 'Education', 'icon': Icons.school},
    {'name': 'Transport', 'icon': Icons.local_shipping},
    {'name': 'Home', 'icon': Icons.cleaning_services},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).user;
      if (user != null) {
        ref.read(marketplaceProvider.notifier).fetchProfile(user.uid);
        if (user.providerProfile.professionTitle.isNotEmpty || user.providerProfile.isActive) {
          setState(() {
            _selectedBusinessType = user.providerProfile.businessType.isNotEmpty ? user.providerProfile.businessType : 'individual';
            _selectedCategory = user.providerProfile.category.isNotEmpty ? user.providerProfile.category : null;
            _titleController.text = user.providerProfile.professionTitle;
            _rateController.text = user.providerProfile.hourlyRate > 0 ? user.providerProfile.hourlyRate.toStringAsFixed(0) : '';
            _bioController.text = user.providerProfile.bio;
            if (user.providerProfile.portfolioImages.isNotEmpty && _existingImages.isEmpty) {
              _existingImages.addAll(user.providerProfile.portfolioImages);
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _rateController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();
    if (_pageController.page == 0 && _selectedBusinessType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an account type.')));
      return;
    }
    if (_pageController.page == 1 && _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an industry.')));
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _previousPage() {
    FocusScope.of(context).unfocus();
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 50);
    if (pickedFiles.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compressing images...')));
      }
      for (var picked in pickedFiles) {
        setState(() {
          _newImages.add(File(picked.path));
        });
      }
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImages.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedBusinessType == null || _selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Missing selection in previous steps.')));
        return;
      }
      final user = ref.read(authStateProvider).user;
      if (user != null) {
        ref.read(marketplaceProvider.notifier).saveProfile(
              uid: user.uid,
              professionTitle: _titleController.text.trim(),
              category: _selectedCategory!,
              businessType: _selectedBusinessType!,
              hourlyRate: double.tryParse(_rateController.text.trim()) ?? 0.0,
              bio: _bioController.text.trim(),
              newImageFiles: _newImages,
              existingImageUrls: _existingImages,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final marketplaceState = ref.watch(marketplaceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<MarketplaceState>(marketplaceProvider, (previous, next) {
      if (previous?.isLoading == true && next.isLoading == false) {
        if (next.errorMessage.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          ref.read(marketplaceProvider.notifier).clearError();
        } else if (next.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storefront published successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          ref.read(marketplaceProvider.notifier).clearSuccess();
          Navigator.of(context).pop();
        }
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_pageController.hasClients && _pageController.page! > 0) {
              _previousPage();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: SmoothPageIndicator(
                controller: _pageController,
                count: 3,
                effect: ExpandingDotsEffect(
                  activeDotColor: AppColors.primary,
                  dotColor: isDark ? Colors.white24 : Colors.black12,
                  dotHeight: 8,
                  dotWidth: 8,
                  expansionFactor: 3,
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(isDark),
                  _buildStep2(isDark),
                  _buildStep3(isDark, marketplaceState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose your account type',
            style: AppTextStyles.heading1.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'How do you want to operate on Hubble?',
            style: AppTextStyles.bodyLarge.copyWith(
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            ),
          ),
          const SizedBox(height: 32),
          _buildAccountTypeCard(
            isDark: isDark,
            title: 'Physical Retail Store',
            subtitle: 'Sell products from a physical location, manage inventory, and handle orders.',
            icon: Icons.storefront,
            value: 'shop',
          ),
          const SizedBox(height: 20),
          _buildAccountTypeCard(
            isDark: isDark,
            title: 'Service & Freelance',
            subtitle: 'Offer skills, trades, or professional services to clients directly.',
            icon: Icons.person_outline,
            value: 'individual',
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTypeCard({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _selectedBusinessType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBusinessType = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withValues(alpha: 0.1) 
              : (isDark ? AppColors.bgDarkCard : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? Colors.white12 : Colors.black12),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : (isDark ? Colors.white12 : Colors.black12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.heading3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : (isDark ? Colors.white38 : Colors.black26),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select your industry',
            style: AppTextStyles.heading1.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps clients find you in the right category.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: _industries.length,
              itemBuilder: (context, index) {
                final ind = _industries[index];
                final isSelected = _selectedCategory == ind['name'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = ind['name'] as String;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppColors.primary 
                          : (isDark ? AppColors.bgDarkCard : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : (isDark ? Colors.white12 : Colors.black12),
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ] : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          ind['icon'] as IconData,
                          size: 40,
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          ind['name'] as String,
                          style: AppTextStyles.heading3.copyWith(
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(bool isDark, MarketplaceState marketplaceState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Specific Details',
              style: AppTextStyles.heading1.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us more about what you offer.',
              style: AppTextStyles.bodyLarge.copyWith(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Profession / Store Title',
              style: AppTextStyles.label.copyWith(
                color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: _selectedBusinessType == 'shop' ? 'e.g. Acme Electronics' : 'e.g. Senior Plumber',
                prefixIcon: const Icon(Icons.work_outline, size: 20),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
            ),
            const SizedBox(height: 24),

            Text(
              _selectedBusinessType == 'shop' ? 'Starting Price (K)' : 'Hourly Rate (K)',
              style: AppTextStyles.label.copyWith(
                color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _rateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '0.00',
                prefixIcon: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Text('K', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required field';
                if (double.tryParse(value) == null) return 'Must be a valid number';
                return null;
              },
            ),
            const SizedBox(height: 24),

            Text(
              'Bio & Description',
              style: AppTextStyles.label.copyWith(
                color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bioController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe your skills or your store...',
              ),
              validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Images',
                  style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_a_photo, color: AppColors.primary),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_existingImages.isNotEmpty || _newImages.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _existingImages.length + _newImages.length,
                itemBuilder: (context, index) {
                  final isExisting = index < _existingImages.length;
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: isDark ? AppColors.bgDarkCard : Colors.grey[200],
                          child: isExisting
                              ? HubbleImage(imagePath: _existingImages[index], fit: BoxFit.cover)
                              : Image.file(_newImages[index - _existingImages.length], fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => isExisting ? _removeExistingImage(index) : _removeNewImage(index - _existingImages.length),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              )
            else
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.bgDarkCard : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('No images added.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 48),

            ElevatedButton(
              onPressed: marketplaceState.isLoading ? null : _submit,
              child: marketplaceState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : const Text('Publish Storefront'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
