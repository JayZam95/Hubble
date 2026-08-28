import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/presentation/screens/main_layout.dart';
import '../providers/auth_provider.dart';
import 'google_setup_screen.dart';
import 'role_selection_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(authStateProvider.notifier).signInWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
    }
  }

  void _resetPassword() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address first.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    ref.read(authStateProvider.notifier).sendPasswordResetEmail(email);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // Listen to changes in authState (errors, password resets, and successful login)
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next.isAuthenticated) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainLayout()),
          (route) => false,
        );
      } else if (next.isPartialAuth) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const GoogleSetupScreen()),
          (route) => false,
        );
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(authStateProvider.notifier).clearError();
      }
      if (next.isPasswordResetSent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('A password reset link has been sent to ${_emailController.text.trim()}.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(authStateProvider.notifier).clearPasswordReset();
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: isDark
                    ? AppColors.darkBackgroundGradient
                    : const LinearGradient(
                        colors: [Color(0xFFEEF2F6), Color(0xFFF8FAFC)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
              ),
            ),
          ),
          // Ambient Glow Circle for Dark Mode
          if (isDark)
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 120,
                    ),
                  ],
                ),
              ),
            ),
          // Main Scrollable Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo Icon
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.explore_outlined,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // App Name & Welcome
                      Text(
                        'HUBBLE',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.displayLarge.copyWith(
                          foreground: Paint()
                            ..shader = AppColors.primaryGradient.createShader(
                              const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                            ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Log in to connect with service exchange experts.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Card Form
                      Card(
                        elevation: isDark ? 8 : 2,
                        shadowColor: isDark ? Colors.black38 : Colors.grey.shade200,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Email Field
                                Text(
                                  'Email Address',
                                  style: AppTextStyles.label.copyWith(
                                    color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    hintText: 'name@example.com',
                                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                      return 'Please enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                // Password Field
                                Text(
                                  'Password',
                                  style: AppTextStyles.label.copyWith(
                                    color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: InputDecoration(
                                    hintText: '••••••••',
                                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                // Forgot Password Link (Mirrors Swift)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: authState.isLoading ? null : _resetPassword,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 0),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text('Forgot Password?'),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Submit Button
                                ElevatedButton(
                                  onPressed: authState.isLoading ? null : _submit,
                                  child: authState.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text('Log In'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Divider OR
                      Row(
                        children: [
                          Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'OR',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Google Sign In Button
                      OutlinedButton.icon(
                        onPressed: authState.isLoading
                            ? null
                            : () => ref.read(authStateProvider.notifier).signInWithGoogle(),
                        icon: const Icon(Icons.g_mobiledata, size: 30),
                        label: const Text('Sign in with Google'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          foregroundColor: isDark ? Colors.white : Colors.black87,
                          side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: AppTextStyles.buttonText,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Toggle Register
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const RoleSelectionScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Sign Up',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
