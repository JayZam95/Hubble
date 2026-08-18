import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../constants/app_colors.dart';
import '../../../features/marketplace/presentation/screens/explore_screen.dart';
import '../../../features/bookings/presentation/screens/booking_list_screen.dart';
import '../../../features/chat/presentation/screens/inbox_screen.dart';
import '../../../features/profile/presentation/screens/profile_screen.dart';
import '../../../features/marketplace/presentation/screens/create_listing_screen.dart';

// Global provider so any screen (e.g. ProfileScreen) can switch the bottom nav tab
final selectedTabProvider = StateProvider<int>((ref) => 0);

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  final List<Widget> _screens = const [
    ExploreScreen(),
    BookingListScreen(),
    InboxScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      HapticFeedback.lightImpact();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreateListingScreen()),
      );
      return;
    }

    int screenIndex = index > 2 ? index - 1 : index;

    final current = ref.read(selectedTabProvider);
    if (current != screenIndex) {
      HapticFeedback.selectionClick();
      ref.read(selectedTabProvider.notifier).state = screenIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawSelectedIndex = ref.watch(selectedTabProvider);
    final navIndex = rawSelectedIndex >= 2 ? rawSelectedIndex + 1 : rawSelectedIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: rawSelectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: isDark ? AppColors.bgDarkCard : Colors.white,
            indicatorColor: AppColors.primary.withValues(alpha: 0.15),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary);
              }
              return TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: isDark ? Colors.white54 : Colors.grey);
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: AppColors.primary);
              }
              return IconThemeData(color: isDark ? Colors.white54 : Colors.grey);
            }),
          ),
          child: NavigationBar(
            selectedIndex: navIndex,
            onDestinationSelected: _onItemTapped,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: 'Explore',
              ),
              const NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Bookings',
              ),
              NavigationDestination(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
                label: 'Create',
              ),
              const NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: 'Inbox',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
