import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickhire/core/services/auth_service.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/views/widgets/nav_bar.dart';
import 'package:quickhire/core/views/widgets/custom_loading_indicator.dart';
import 'package:quickhire/features/home/employee/views/pages/home_page.dart';
import 'package:quickhire/features/home/employer/views/pages/employer_home_page.dart';
import 'package:quickhire/features/profile/view/pages/profile_page.dart';
import 'package:quickhire/features/messaging/view/pages/messages_inbox_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Provider to manage the current tab index
final currentTabProvider = StateProvider<int>((ref) => 0);

// Provider to listen to auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  return authService.value.authStateChanges;
});

// Provider to get user type using stream for real-time updates
final userTypeProvider = StreamProvider<String?>((ref) {
  // Get the current user directly from auth service
  final currentUser = authService.value.currentUser;
  if (currentUser == null) return Stream.value(null);

  // Use the stream-based method for real-time updates
  return authService.value.getCurrentUserDataStream().map(
    (userData) => userData?.type,
  );
});

class MainNavigationPage extends ConsumerWidget {
  const MainNavigationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentTabProvider);
    final userTypeAsync = ref.watch(userTypeProvider);

    return userTypeAsync.when(
      data: (userType) {
        // Conditionally set the home page based on user type
        final homePage =
            userType == 'employer'
                ? EmployerHomePage(key: ValueKey('employer'))
                : HomePage(key: ValueKey('employee'));

        // List of pages that will be kept in memory
        final pages = [
          homePage,
          const ProfilePage(),
          const MessagesInboxPage(),
        ];

        return Scaffold(
          backgroundColor: Palette.background,
          body: IndexedStack(index: currentIndex, children: pages),
          bottomNavigationBar: NavBar(
            currentIndex: currentIndex,
            onTap: (index) {
              // Update the tab index without navigation
              ref.read(currentTabProvider.notifier).state = index;
            },
          ),
        );
      },
      loading:
          () => const Scaffold(
            backgroundColor: Palette.background,
            body: Center(child: CustomLoadingIndicator()),
          ),
      error:
          (error, stackTrace) =>
              Center(child: Text('Error loading user data: $error')),
    );
  }
}
