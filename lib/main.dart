import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'core/theme/app_theme.dart';

import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/role_selection_screen.dart';
import 'features/auth/presentation/screens/google_setup_screen.dart';
import 'features/auth/presentation/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/presentation/screens/main_layout.dart';
import 'firebase_options.dart';

import 'core/services/push_notification_service.dart';
import 'core/services/telemetry_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    TelemetryService.initialize();

    // Parallelize core essential initializations
    final results = await Future.wait([
      Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      SharedPreferences.getInstance(),
    ]);

    final prefs = results[1] as SharedPreferences;
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    // Launch UI immediately so app opens instantly
    runApp(
      ProviderScope(
        child: MyApp(hasSeenOnboarding: hasSeenOnboarding),
      ),
    );

    // Defer non-critical network initializations in background
    _initSecondaryServices();
  } catch (e, stackTrace) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'STARTUP ERROR: $e\n\n$stackTrace',
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _initSecondaryServices() async {
  if (!kDebugMode) {
    try {
      // ignore: deprecated_member_use
      await FirebaseAppCheck.instance.activate(
        // ignore: deprecated_member_use
        androidProvider: AndroidProvider.playIntegrity,
        // ignore: deprecated_member_use
        appleProvider: AppleProvider.deviceCheck,
      );
    } catch (e) {
      debugPrint('Firebase AppCheck init deferred error: $e');
    }
  }

  try {
    await pushNotificationService.initialize();
  } catch (e) {
    debugPrint('Push notifications deferred error: $e');
  }
}

class MyApp extends ConsumerStatefulWidget {
  final bool hasSeenOnboarding;

  const MyApp({super.key, required this.hasSeenOnboarding});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Mark as online when app starts
    Future.microtask(() {
      ref.read(authStateProvider.notifier).updatePresence(true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(authStateProvider.notifier).updatePresence(true);
    } else if (state == AppLifecycleState.paused || 
               state == AppLifecycleState.detached || 
               state == AppLifecycleState.inactive) {
      ref.read(authStateProvider.notifier).updatePresence(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'Hubble',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: widget.hasSeenOnboarding ? const AuthGate() : const OnboardingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authState.isAuthenticated) {
      return const MainLayout();
    }
    
    if (authState.isPartialAuth) {
      return const GoogleSetupScreen();
    }

    if (authState.errorMessage != null) {
      // In a real app, we might want a dedicated ErrorScreen
      // For now, we'll show the role selection but with a way to see the error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(authStateProvider.notifier).clearError();
      });
    }

    return const RoleSelectionScreen();
  }
}
