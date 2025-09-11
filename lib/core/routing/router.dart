import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickhire/core/services/auth_service.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/views/pages/main_navigation_page.dart';
import 'package:quickhire/core/views/widgets/custom_loading_indicator.dart';
import 'package:quickhire/features/auth/view/pages/login_page.dart';
import 'package:quickhire/features/auth/view/pages/signup_page.dart';
import 'package:quickhire/features/auth/view/pages/forgot_password_page.dart';
import 'package:quickhire/features/auth/view/pages/user_type_page.dart';
import 'package:quickhire/features/auth/view/pages/verification_page.dart';
import 'package:quickhire/features/job_posting/views/pages/job_posting_page.dart';
import 'package:quickhire/features/onboarding/view/pages/onboarding_page.dart';
import 'package:quickhire/features/permissions/view/pages/location_page.dart';
import 'package:quickhire/features/profile/view/pages/account_information_page.dart';

// Global navigator key
final rootNavKey = GlobalKey<NavigatorState>();

// Auth state model
class AuthenticationState {
  final bool isLoggedIn;
  final bool isVerified;
  final bool hasUserType;
  final String? error;

  const AuthenticationState({
    required this.isLoggedIn,
    required this.isVerified,
    required this.hasUserType,
    this.error,
  });
}

// Auth provider
final authProvider = FutureProvider<AuthenticationState>((ref) async {
  try {
    final user = authService.value.currentUser;
    final isLoggedIn = user != null;
    final isVerified =
        user?.emailVerified == true ||
        (user != null && authService.value.isSignedInWithGoogle());

    bool hasUserType = false;

    if (isLoggedIn && isVerified) {
      try {
        final userDoc = await authService.value.getUserDocument(user.uid);
        final userData = userDoc.data();
        hasUserType =
            userData != null &&
            userData.containsKey('type') &&
            userData['type'] != null &&
            userData['type'].toString().isNotEmpty;
      } catch (e) {
        print('Error checking user type: $e');
        hasUserType = false;
      }
    }

    return AuthenticationState(
      isLoggedIn: isLoggedIn,
      isVerified: isVerified,
      hasUserType: hasUserType,
    );
  } catch (e) {
    return AuthenticationState(
      isLoggedIn: false,
      isVerified: false,
      hasUserType: false,
      error: e.toString(),
    );
  }
});

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(authProvider.future).then((authState) async {
      if (rootNavKey.currentContext == null) return;

      if (authState.error != null) {
        GoRouter.of(rootNavKey.currentContext!).go('/onboarding');
        return;
      }

      if (!authState.isLoggedIn) {
        GoRouter.of(rootNavKey.currentContext!).go('/onboarding');
      } else if (!authState.isVerified) {
        GoRouter.of(rootNavKey.currentContext!).go('/verification');
      } else if (!authState.hasUserType) {
        await FirebaseAuth.instance.signOut();
        GoRouter.of(rootNavKey.currentContext!).go('/login');
      } else {
        GoRouter.of(rootNavKey.currentContext!).go('/home');
      }
    });

    return const Scaffold(
      backgroundColor: Palette.background,
      body: Center(child: CustomLoadingIndicator(size: 80.0)),
    );
  }
}

// GoRouter configuration
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    navigatorKey: rootNavKey,
    redirect: (context, state) {
      // Always allow splash screen
      if (state.matchedLocation == '/splash') {
        return null;
      }

      // Check current auth state
      final currentUser = authService.value.currentUser;

      // If user is signed out and trying to access protected routes, redirect to login
      if (currentUser == null && state.matchedLocation.startsWith('/home')) {
        return '/login';
      }

      return null;
    },
    refreshListenable: authService, // Listen to auth state changes
    routes: [
      // Splash Screen Route
      GoRoute(
        path: '/splash',
        pageBuilder:
            (context, state) => const NoTransitionPage(child: SplashScreen()),
      ),

      // Auth & Onboarding Routes
      GoRoute(
        path: '/onboarding',
        pageBuilder:
            (context, state) => NoTransitionPage(child: const OnboardingPage()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => const MaterialPage(child: LoginPage()),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder:
            (context, state) => const MaterialPage(child: SignupPage()),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder:
            (context, state) => const MaterialPage(child: ForgotPasswordPage()),
      ),
      GoRoute(
        path: '/verification',
        pageBuilder:
            (context, state) => const MaterialPage(child: VerificationPage()),
      ),
      GoRoute(
        path: '/permissions/location',
        pageBuilder:
            (context, state) => const MaterialPage(child: LocationPage()),
      ),
      GoRoute(
        path: '/auth/user-type',
        pageBuilder:
            (context, state) => const MaterialPage(child: UserTypePage()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder:
            (context, state) =>
                const NoTransitionPage(child: MainNavigationPage()),
      ),
      GoRoute(
        path: '/job-posting',
        pageBuilder:
            (context, state) => const MaterialPage(child: JobPostingPage()),
      ),
      GoRoute(
        path: '/account-information',
        pageBuilder:
            (context, state) =>
                const MaterialPage(child: AccountInformationPage()),
      ),
    ],
  );
});
