import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../../core/presentation/widgets/hubble_image.dart';
import '../../../profile/presentation/screens/dashboard_screen.dart';
import '../../../profile/presentation/screens/provider_setup_wizard_screen.dart';
import 'manage_listings_screen.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../admin/presentation/screens/category_admin_screen.dart';
import '../../../marketplace/presentation/screens/create_listing_screen.dart';
import '../../../bookings/presentation/screens/provider_calendar_screen.dart';
import 'kyc_verification_screen.dart';
import '../../../ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../../rewards/presentation/screens/rewards_screen.dart';
import '../../../favorites/presentation/screens/favorites_screen.dart';
import '../../../../core/services/pdf_invoice_service.dart';
import '../../../bookings/domain/models/booking_model.dart';


class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isUpdating = false;

  // Mock Notification preferences stored locally
  bool _pushNotifications = true;
  bool _smsReceipts = true;
  bool _soundAlerts = true;
  Future<void> _updateFirestoreField(UserModel user, String field, dynamic value, String successMsg) async {
    setState(() => _isUpdating = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        field: value,
      });
      await ref.read(authStateProvider.notifier).refreshUser();
      _showToast(successMsg, isError: false);
    } catch (e) {
      _showToast('Failed to save settings: $e', isError: true);
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _toggleIdentity(UserModel user, bool isProvider) async {
    if (isProvider && !user.providerProfile.isActive) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProviderSetupWizardScreen(),
        ),
      );
    } else {
      _updateFirestoreField(
        user,
        'providerProfile.isActive',
        false,
        'Returned to Client Mode!',
      );
    }
  }

  void _showEditNameDialog(UserModel user) {
    final firstController = TextEditingController(text: user.personalInfo.firstName);
    final lastController = TextEditingController(text: user.personalInfo.lastName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Personal Name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'First Name', hintText: 'e.g. Mwansa'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lastController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Last Name', hintText: 'e.g. Chisha'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final first = firstController.text.trim();
                final last = lastController.text.trim();
                if (first.isNotEmpty && last.isNotEmpty) {
                  Navigator.pop(context);
                  setState(() => _isUpdating = true);
                  try {
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                      'personalInfo.firstName': first,
                      'personalInfo.lastName': last,
                    });
                    await ref.read(authStateProvider.notifier).refreshUser();
                    _showToast('Name updated successfully!', isError: false);
                  } catch (e) {
                    _showToast('Failed to update name: $e', isError: true);
                  } finally {
                    setState(() => _isUpdating = false);
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEditPhoneDialog(UserModel user) {
    final controller = TextEditingController(text: user.personalInfo.phoneNumber);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Contact Number'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: 'e.g. +260 971 234567',
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final phone = controller.text.trim();
                if (phone.isNotEmpty) {
                  Navigator.pop(context);
                  _updateFirestoreField(user, 'personalInfo.phoneNumber', phone, 'Phone number updated!');
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEditProfessionDialog(UserModel user) {
    final titleController = TextEditingController(text: user.providerProfile.professionTitle);
    final bioController = TextEditingController(text: user.providerProfile.bio);
    final rateController = TextEditingController(text: user.providerProfile.hourlyRate.toStringAsFixed(0));
    final isShop = user.providerProfile.businessType == 'shop';

    final List<String> storeCategories = [
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

    final List<String> serviceCategories = [
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

    final List<String> categories = isShop ? storeCategories : serviceCategories;
    
    String selectedCategory = user.providerProfile.category;
    if (selectedCategory.isEmpty || !categories.contains(selectedCategory)) {
      selectedCategory = categories.first;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Update Professional Listing'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Profession Title', hintText: 'e.g. Expert Plumber'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: rateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Hourly Rate (ZMW)', hintText: 'e.g. 150'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bioController,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(labelText: 'Professional Biography', hintText: 'Describe your expertise and tools...'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final bio = bioController.text.trim();
                    final rate = double.tryParse(rateController.text.trim()) ?? 0.0;

                    if (title.isNotEmpty && bio.isNotEmpty && rate > 0) {
                      Navigator.pop(context);
                      setState(() => _isUpdating = true);
                      try {
                        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                          'providerProfile.professionTitle': title,
                          'providerProfile.bio': bio,
                          'providerProfile.category': selectedCategory,
                          'providerProfile.hourlyRate': rate,
                        });
                        await ref.read(authStateProvider.notifier).refreshUser();
                        _showToast('Storefront listing updated successfully!', isError: false);
                      } catch (e) {
                        _showToast('Failed to update storefront: $e', isError: true);
                      } finally {
                        setState(() => _isUpdating = false);
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }



  Future<void> _addMockPortfolioImage(UserModel user) async {
    final mockWorkImages = [
      'https://images.unsplash.com/photo-1581092921461-eab62e97a780?w=500',
      'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=500',
      'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=500',
      'https://images.unsplash.com/photo-1605647540924-852290f6b0d5?w=500',
      'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=500',
    ];

    setState(() => _isUpdating = true);
    try {
      final currentList = List<String>.from(user.providerProfile.portfolioImages);
      final newMock = mockWorkImages[currentList.length % mockWorkImages.length];
      currentList.add(newMock);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'providerProfile.portfolioImages': currentList,
      });
      await ref.read(authStateProvider.notifier).refreshUser();
      _showToast('Mock work photo added to portfolio grid!', isError: false);
    } catch (e) {
      _showToast('Failed to add portfolio: $e', isError: true);
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  void _showChangePasswordDialog(UserModel user) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current Password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final currentPass = currentPasswordController.text;
                final newPass = newPasswordController.text;
                if (currentPass.isEmpty || newPass.isEmpty) {
                  _showToast('Please fill all fields', isError: true);
                  return;
                }
                Navigator.pop(context);
                setState(() => _isUpdating = true);
                try {
                  final fbUser = FirebaseAuth.instance.currentUser;
                  if (fbUser != null) {
                    final cred = EmailAuthProvider.credential(email: user.email, password: currentPass);
                    await fbUser.reauthenticateWithCredential(cred);
                    await fbUser.updatePassword(newPass);
                    _showToast('Password updated successfully!', isError: false);
                  }
                } on FirebaseAuthException catch (e) {
                  _showToast(e.message ?? 'Auth Error', isError: true);
                } catch (e) {
                  _showToast('Failed to update password: $e', isError: true);
                } finally {
                  setState(() => _isUpdating = false);
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (pickedFile != null) {
        _showToast('Processing image...', isError: false);
        await ref.read(authStateProvider.notifier).uploadProfileImage(File(pickedFile.path));
        _showToast('Profile picture updated!', isError: false);
      }
    } catch (e) {
      _showToast('Failed to upload image: $e', isError: true);
    }
  }

  void _showDeleteAccountDialog(UserModel user) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Danger Zone'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Are you absolutely sure you want to terminate your Hubble account? This action is irreversible. Please enter your password to confirm.',
                style: TextStyle(height: 1.45),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                final pass = passwordController.text;
                if (pass.isEmpty) {
                  _showToast('Please enter your password', isError: true);
                  return;
                }
                Navigator.pop(context);
                setState(() => _isUpdating = true);
                try {
                  final fbUser = FirebaseAuth.instance.currentUser;
                  if (fbUser != null) {
                    final cred = EmailAuthProvider.credential(email: user.email, password: pass);
                    await fbUser.reauthenticateWithCredential(cred);
                    await fbUser.delete();
                  }
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'isDeleted': true});
                  await ref.read(authStateProvider.notifier).signOut();
                  if (!mounted) return;
                  _showToast('Your Hubble account was securely deleted.', isError: false);
                } on FirebaseAuthException catch (e) {
                  _showToast(e.message ?? 'Auth Error', isError: true);
                } catch (e) {
                  _showToast('Delete failed: $e', isError: true);
                } finally {
                  if (mounted) {
                    setState(() => _isUpdating = false);
                  }
                }
              },
              child: const Text('Permanently Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    // Show a loading indicator while auth state is being resolved
    if (authState.isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          elevation: 0,
          title: const Text('Account Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          elevation: 0,
          title: const Text('Account Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Please log in to access settings.',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Auth state: loading=${authState.isLoading}, hasFirebaseUser=${authState.firebaseUser != null}',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    final isProviderMode = user.role == UserRole.provider;
    final vault = user.financialLedger.vaultSettings;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        title: Text(
          'Account Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              children: [
                _buildPremiumCard(
                  isDark: isDark,
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                ),
                                child: user.personalInfo.profileImageURL.trim().isNotEmpty
                                    ? HubbleImage(
                                        imagePath: user.personalInfo.profileImageURL.trim(),
                                        width: 80,
                                        height: 80,
                                        borderRadius: BorderRadius.circular(40),
                                      )
                                    : Center(
                                        child: Text(
                                          user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: AppColors.primary),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickAndUploadImage,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 4),
                            Text(user.email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Personal Profile Info', isDark),
                _buildPremiumCard(
                  isDark: isDark,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline, color: AppColors.primary),
                        title: const Text('First & Last Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(user.displayName),
                        trailing: const Icon(Icons.chevron_right, size: 18),
                        onTap: () => _showEditNameDialog(user),
                      ),
                      Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                      ListTile(
                        leading: const Icon(Icons.phone_iphone_outlined, color: AppColors.primary),
                        title: const Text('Contact Mobile Number', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(user.personalInfo.phoneNumber.isNotEmpty ? user.personalInfo.phoneNumber : 'Not set (e.g. +260 971 234567)'),
                        trailing: const Icon(Icons.chevron_right, size: 18),
                        onTap: () => _showEditPhoneDialog(user),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Marketplace Listing Mode', isDark),
                _buildPremiumCard(
                  isDark: isDark,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            isProviderMode ? Icons.storefront : Icons.shopping_bag_outlined,
                            color: isProviderMode ? AppColors.success : AppColors.primary,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isProviderMode ? 'Hiring Storefront Active' : 'Client Mode Active',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                const Text('Toggle on to offer services and accept bookings in Zambia.', style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.25)),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: isProviderMode,
                            activeTrackColor: AppColors.success,
                            onChanged: (val) => _toggleIdentity(user, val),
                          ),
                        ],
                      ),
                      if (isProviderMode) ...[
                        const SizedBox(height: 16),
                        Divider(color: isDark ? Colors.white10 : Colors.black12),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.business_center_outlined, color: AppColors.success),
                          title: const Text('Business Identity Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(user.providerProfile.businessType == 'shop' 
                              ? 'Retail Store' 
                              : 'Service Professional'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProviderSetupWizardScreen(),
                              ),
                            );
                          },
                        ),
                        Divider(color: isDark ? Colors.white10 : Colors.black12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.grid_view_rounded, color: AppColors.success),
                          title: const Text('Manage Storefront Catalog', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text('Manage your listings (${user.providerProfile.listingsCount} active items)'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ManageListingsScreen(),
                              ),
                            );
                          },
                        ),
                          Divider(color: isDark ? Colors.white10 : Colors.black12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.calendar_month_outlined, color: AppColors.success),
                            title: const Text('Booking Calendar / Schedule', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: const Text('View and manage your schedule'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProviderCalendarScreen(),
                                ),
                              );
                            },
                          ),
                          Divider(color: isDark ? Colors.white10 : Colors.black12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.analytics_outlined, color: AppColors.success),
                          title: const Text('Provider Analytics Dashboard', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('View earnings, profile views, and metrics'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DashboardScreen(),
                              ),
                            );
                          },
                        ),
                        Divider(color: isDark ? Colors.white10 : Colors.black12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.add_shopping_cart, color: AppColors.success),
                          title: const Text('Storefront Manager / Upload Product', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Add new products or services to your storefront'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreateListingScreen(),
                              ),
                            );
                          },
                        ),
                        Divider(color: isDark ? Colors.white10 : Colors.black12),
                        Builder(
                          builder: (context) {
                            final double rate = user.providerProfile.hourlyRate;
                            final String rateStr = (rate.isNaN || rate.isInfinite) ? "0" : rate.toStringAsFixed(0);
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.edit_note, color: AppColors.success),
                              title: const Text('Storefront Presentation', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Text('${user.providerProfile.professionTitle} • $rateStr ZMW/hr'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                              onTap: () => _showEditProfessionDialog(user),
                            );
                          },
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.success),
                          title: const Text('Upload Work Portfolio Photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Showcase your previous projects to clients'),
                          trailing: const Icon(Icons.add, size: 18),
                          onTap: () => _addMockPortfolioImage(user),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Trust & ID Verification', isDark),
                _buildPremiumCard(
                  isDark: isDark,
                  child: Row(
                    children: [
                      Icon(
                        user.kycStatus == 'verified' 
                            ? Icons.verified 
                            : (user.kycStatus == 'pending' ? Icons.hourglass_top : Icons.admin_panel_settings_outlined),
                        color: user.kycStatus == 'verified' 
                            ? Colors.blue 
                            : (user.kycStatus == 'pending' ? Colors.orange : Colors.redAccent),
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.kycStatus == 'verified' 
                                  ? 'Verification Complete' 
                                  : (user.kycStatus == 'pending' ? 'Verification Pending' : 'Verify Gov Identity'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.kycStatus == 'verified'
                                  ? 'Your identity is fully verified. Blue checkmark unlocked.'
                                  : (user.kycStatus == 'pending' ? 'Your identity documents are under review.' : 'Complete National ID verification to start working.'),
                              style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.25),
                            ),
                          ],
                        ),
                      ),
                      if (user.kycStatus == 'unverified')
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const KycVerificationScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Verify ID', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        )
                      else if (user.kycStatus == 'pending')
                        const Icon(Icons.access_time_filled, color: Colors.orange)
                      else
                        const Icon(Icons.check_circle, color: Colors.blue),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Savings Vault Allocation', isDark),
                _buildPremiumCard(
                  isDark: isDark,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.savings_outlined, color: AppColors.accent),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Vault Auto-Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                SizedBox(height: 2),
                                Text('Deduct a custom percentage of job payouts directly to savings vault.', style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.25)),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: vault.isAutoSaveEnabled,
                            activeTrackColor: AppColors.accent,
                            onChanged: (val) {
                              _updateFirestoreField(
                                user,
                                'financialLedger.vaultSettings.isAutoSaveEnabled',
                                val,
                                val ? 'Auto-Save Enabled!' : 'Auto-Save Disabled!',
                              );
                            },
                          ),
                        ],
                      ),
                      if (vault.isAutoSaveEnabled) ...[
                        const SizedBox(height: 16),
                        Builder(
                          builder: (context) {
                            double percentageVal = vault.autoSavePercentage;
                            if (percentageVal <= 1.0 && percentageVal > 0.0) {
                              percentageVal = percentageVal * 100.0;
                            }
                            percentageVal = percentageVal.clamp(0.0, 100.0);
                            percentageVal = (percentageVal / 5.0).roundToDouble() * 5.0;

                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Allocation Rate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    Text('${percentageVal.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
                                  ],
                                ),
                                Slider(
                                  value: percentageVal,
                                  max: 100,
                                  divisions: 20,
                                  activeColor: AppColors.accent,
                                  inactiveColor: AppColors.accent.withValues(alpha: 0.2),
                                  label: '${percentageVal.toInt()}%',
                                  onChanged: (val) {
                                    FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                                      'financialLedger.vaultSettings.autoSavePercentage': val.roundToDouble(), 
                                    });
                                  },
                                  onChangeEnd: (val) {
                                    ref.read(authStateProvider.notifier).refreshUser();
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Alert Tones & Notifications', isDark),
                _buildPremiumCard(
                  isDark: isDark,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                SizedBox(height: 2),
                                Text('Instant alerts on booking updates', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _pushNotifications,
                            activeTrackColor: AppColors.primary,
                            onChanged: (val) => setState(() => _pushNotifications = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.sms_outlined, color: AppColors.primary),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Zambian SMS Ledger Alerts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                SizedBox(height: 2),
                                Text('SMS receipt for transaction records', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _smsReceipts,
                            activeTrackColor: AppColors.primary,
                            onChanged: (val) => setState(() => _smsReceipts = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.volume_up_outlined, color: AppColors.primary),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Acoustic Sound Effects', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                SizedBox(height: 2),
                                Text('Tones on message receipt', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _soundAlerts,
                            activeTrackColor: AppColors.primary,
                            onChanged: (val) => setState(() => _soundAlerts = val),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Hubble Innovation & Smart Features', isDark),
                _buildPremiumCard(
                  isDark: isDark,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.smart_toy_outlined, color: AppColors.primary),
                        title: const Text('Hubble AI Assistant', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text('Smart intent search for services, bus schedules & escrow fees'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AiAssistantScreen()),
                          );
                        },
                      ),
                      Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                      ListTile(
                        leading: const Icon(Icons.military_tech_outlined, color: Colors.amber),
                        title: const Text('Loyalty & Rewards Program', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text('Redeem points for escrow fee waivers & discount vouchers'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RewardsScreen()),
                          );
                        },
                      ),
                      Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                      ListTile(
                        leading: const Icon(Icons.favorite_outline, color: Colors.redAccent),
                        title: const Text('Saved Favorites / Wishlist', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text('View and manage your saved service providers & listings'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const FavoritesScreen()),
                          );
                        },
                      ),
                      Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                      ListTile(
                        leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.accent),
                        title: const Text('PDF Digital Invoice Generator', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text('Generate and print official digital tax receipts & invoices'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () async {
                          final sampleBooking = BookingModel(
                            bookingId: 'HB-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                            clientId: user.uid,
                            providerId: 'prov_sample_1',
                            clientName: user.displayName,
                            providerName: 'Kabwe Plumbing & Drain Pros',
                            serviceCategory: 'Plumbing & Home Repair',
                            status: BookingStatus.COMPLETED,
                            jobDescription: 'Emergency leak repair and pipe replacement in Lusaka.',
                            financials: BookingFinancials(
                              agreedPrice: 450.0,
                              platformFee: 22.50,
                              providerPayout: 427.50,
                              isHeldInEscrow: true,
                            ),
                            timestamps: BookingTimestamps(
                              requestedAt: DateTime.now().subtract(const Duration(days: 1)),
                              scheduledFor: DateTime.now(),
                            ),
                          );
                          final pdfBytes = await PdfInvoiceService.generateBookingInvoice(sampleBooking);
                          if (context.mounted) {
                            PdfInvoiceService.previewPdf(context, pdfBytes, 'Hubble_Official_Invoice.pdf');
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('General Preferences & App Theme', isDark),
                _buildPremiumCard(
                  isDark: isDark,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Interface Dark Theme', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                SizedBox(height: 2),
                                Text('Force application night mode palette', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: ref.watch(themeProvider) == ThemeMode.dark,
                            activeTrackColor: AppColors.primary,
                            onChanged: (val) {
                              ref.read(themeProvider.notifier).setDarkMode(val);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Privacy & Communication', isDark),
                _buildPremiumCard(
                  isDark: isDark,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.quick_contacts_mail_outlined, color: AppColors.primary),
                        title: const Text('Reference Checks', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                        subtitle: const Text('Allow others to contact you for reference checks.', style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.25)),
                        trailing: Switch.adaptive(
                          value: user.clientProfile.allowsReferenceInquiries,
                          activeTrackColor: AppColors.primary,
                          onChanged: (val) {
                            _updateFirestoreField(
                              user,
                              'clientProfile.allowsReferenceInquiries',
                              val,
                              val ? 'Reference checks enabled' : 'Reference checks disabled',
                            );
                          },
                        ),
                      ),
                      Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                      ListTile(
                        leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                        title: const Text('Share My Location on Map', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                        subtitle: const Text('Allow clients to see your location on the map.', style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.25)),
                        trailing: Switch.adaptive(
                          value: user.providerProfile.isLocationShared,
                          activeTrackColor: AppColors.primary,
                          onChanged: (val) {
                            _updateFirestoreField(
                              user,
                              'providerProfile.isLocationShared',
                              val,
                              val ? 'Location sharing enabled' : 'Location sharing disabled',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (user.email == 'johnmutentwa.jr@gmail.com') ...[
                  _buildSectionTitle('Platform Admin Control', isDark),
                  _buildPremiumCard(
                    isDark: isDark,
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.admin_panel_settings, color: AppColors.accent),
                          title: const Text('Manage Global Categories', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Add, edit, or remove marketplace categories'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CategoryAdminScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                _buildSectionTitle('Security & Sign Out', isDark),
                _buildPremiumCard(
                  isDark: isDark,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock_reset, color: Colors.blue),
                        title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text('Update your secure account password'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () => _showChangePasswordDialog(user),
                      ),
                      Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.orange),
                        title: const Text('Sign Out Session', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.orange)),
                        subtitle: const Text('Gracefully exit this device authentication'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () async {
                          await ref.read(authStateProvider.notifier).signOut();
                        },
                      ),
                      Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                      ListTile(
                        leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                        title: const Text('Permanently Terminate Account', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.red)),
                        subtitle: const Text('Wipe all wallet data, reviews, and storefront'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () => _showDeleteAccountDialog(user),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
            if (_isUpdating)
              Container(
                color: Colors.black.withValues(alpha: 0.25),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: isDark ? Colors.white54 : Colors.black45,
        ),
      ),
    );
  }

  Widget _buildPremiumCard({
    required bool isDark,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
