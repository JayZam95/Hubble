import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class KycVerificationScreen extends ConsumerStatefulWidget {
  const KycVerificationScreen({super.key});

  @override
  ConsumerState<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends ConsumerState<KycVerificationScreen> {
  File? _idImage;
  File? _selfieImage;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isSelfie, ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50,
        preferredCameraDevice: isSelfie ? CameraDevice.front : CameraDevice.rear,
      );

      if (pickedFile != null) {
        setState(() {
          if (isSelfie) {
            _selfieImage = File(pickedFile.path);
          } else {
            _idImage = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      _showToast('Failed to pick image: $e', isError: true);
    }
  }

  void _showImageSourceDialog(bool isSelfie) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(isSelfie, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(isSelfie, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitVerification() async {
    if (_idImage == null || _selfieImage == null) {
      _showToast('Please provide both ID and Selfie images.', isError: true);
      return;
    }

    final user = ref.read(authStateProvider).user;
    if (user == null) {
      _showToast('User not authenticated.', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Simulate image upload delay
      await Future.delayed(const Duration(seconds: 2));

      // Mock URLs
      final idUrl = 'https://mockstorage.com/kyc/${user.uid}/id.jpg';
      final selfieUrl = 'https://mockstorage.com/kyc/${user.uid}/selfie.jpg';

      // Write to kyc_verifications collection
      await FirebaseFirestore.instance.collection('kyc_verifications').add({
        'userId': user.uid,
        'status': 'pending',
        'idUrl': idUrl,
        'selfieUrl': selfieUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update user document
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'kycStatus': 'pending',
      });

      // Refresh user state
      await ref.read(authStateProvider.notifier).refreshUser();

      if (mounted) {
        _showToast('KYC Verification submitted successfully!', isError: false);
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showToast('Submission failed: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildImageSelector({
    required String title,
    required String description,
    required File? imageFile,
    required bool isSelfie,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () => _showImageSourceDialog(isSelfie),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: imageFile != null ? AppColors.primary : (isDark ? Colors.white24 : Colors.black12),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  imageFile,
                  fit: BoxFit.cover,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelfie ? Icons.face : Icons.badge,
                    size: 48,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        title: const Text(
          'Identity Verification',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please provide photos of your Government ID and a clear selfie to verify your identity.',
                    style: TextStyle(fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Government ID',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  _buildImageSelector(
                    title: 'Upload ID Photo',
                    description: 'NRC, Passport, or Driver\'s License',
                    imageFile: _idImage,
                    isSelfie: false,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Selfie Photo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  _buildImageSelector(
                    title: 'Take a Selfie',
                    description: 'Ensure your face is clearly visible',
                    imageFile: _selfieImage,
                    isSelfie: true,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitVerification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Submit for Verification',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Uploading documents...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
