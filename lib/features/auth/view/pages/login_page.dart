import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quickhire/core/services/auth_service.dart';
import 'package:quickhire/core/services/loading_service.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/views/widgets/custom_button.dart';
import 'package:quickhire/features/auth/view/widgets/custom_checkbox.dart';
import 'package:quickhire/core/navigation/views/widgets/custom_dialog.dart';
import 'package:quickhire/core/views/widgets/custom_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Basic validation
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      CustomDialog.show(
        context: context,
        title: "Login Failed",
        message: "Please enter your email address.",
      );
      return;
    }

    if (password.isEmpty) {
      CustomDialog.show(
        context: context,
        title: "Login Failed",
        message: "Please enter your password.",
      );
      return;
    }

    try {
      // Show loading and proceed with login
      await LoadingService.runWithLoading(
        context,
        () => authService.value.signIn(email: email, password: password),
      );

      // Check if user is verified (only for email/password sign-ins)
      if (mounted) {
        final user = authService.value.currentUser;

        // If user signed in with email/password and is not verified, go to verification page
        if (user != null &&
            !user.emailVerified &&
            _isEmailPasswordSignIn(user)) {
          context.push('/verification');
        } else {
          // User is verified or signed in with third-party provider
          // Now check if they have a user type
          await _navigateBasedOnUserType();
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getFirebaseErrorMessage(e);

      CustomDialog.show(
        context: context,
        title: "Login Failed",
        message: errorMessage,
      );
    } catch (e) {
      CustomDialog.show(
        context: context,
        title: "Login Failed",
        message: "An unexpected error occurred. Please try again.",
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      await LoadingService.runWithLoading(
        context,
        () => authService.value.signInWithGoogle(),
      );

      // Google sign-in users skip verification but still need to check user type
      if (mounted) {
        await _navigateBasedOnUserType();
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getGoogleSignInErrorMessage(e);

      CustomDialog.show(
        context: context,
        title: "Google Sign-In Failed",
        message: errorMessage,
      );
    } catch (e) {
      CustomDialog.show(
        context: context,
        title: "Google Sign-In Failed",
        message: "An unexpected error occurred. Please try again.",
      );
    }
  }

  // Add this new method to check user type and navigate accordingly
  Future<void> _navigateBasedOnUserType() async {
    try {
      final user = authService.value.currentUser;
      if (user == null) {
        context.go('/onboarding');
        return;
      }

      // Check if user has selected a user type
      final userDoc = await authService.value.getUserDocument(user.uid);
      final userData = userDoc.data();

      final hasUserType =
          userData != null &&
          userData.containsKey('type') &&
          userData['type'] != null &&
          userData['type'].toString().isNotEmpty;

      if (hasUserType) {
        context.go('/home');
      } else {
        context.go('/auth/user-type');
      }
    } catch (e) {
      print('Error checking user type: $e');
      // If there's an error checking user type, assume they need to set it
      context.go('/auth/user-type');
    }
  }

  void _handleSocialLogin(String provider) {
    if (provider == "Google") {
      _handleGoogleSignIn();
    } else {
      // Placeholder for other social logins - these would also skip verification
      CustomDialog.show(
        context: context,
        title: "Coming Soon",
        message: "$provider login will be available soon.",
      );
    }
  }

  // Helper method to check if user signed in with email/password
  bool _isEmailPasswordSignIn(User user) {
    // Check if the user has email/password as their sign-in method
    return user.providerData.any(
          (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID,
        ) &&
        !authService.value.isSignedInWithGoogle();
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return "No user found with this email address.";
      case 'wrong-password':
        return "Incorrect password. Please try again.";
      case 'invalid-email':
        return "The email address is not valid.";
      case 'user-disabled':
        return "This account has been disabled.";
      case 'too-many-requests':
        return "Too many failed attempts. Please try again later.";
      case 'network-request-failed':
        return "Network error. Please check your connection and try again.";
      default:
        return e.message ?? "An error occurred during login.";
    }
  }

  String _getGoogleSignInErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'sign_in_canceled':
        return "Sign-in was canceled.";
      case 'account-exists-with-different-credential':
        return "An account already exists with a different sign-in method.";
      case 'user-disabled':
        return "This account has been disabled.";
      case 'operation-not-allowed':
        return "Google sign-in is not enabled. Please contact support.";
      case 'network-request-failed':
        return "Network error. Please check your connection and try again.";
      case 'google_sign_in_failed':
        return "Google sign-in failed. Please try again.";
      default:
        return e.message ?? "An error occurred during Google sign-in.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping anywhere
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            // Background image
            Container(
              height: size.height * 0.4,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF121223),
                image: DecorationImage(
                  image: AssetImage('assets/images/auth_login_bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Header texts above the white card
            Positioned(
              top: size.height * 0.16,
              left: 0,
              right: 0,
              child: Column(
                children: const [
                  Text(
                    'Log In',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Palette.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please sign in to your existing account',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),

            // White card container
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: size.height * 0.70,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email
                      const Text('EMAIL'),
                      const SizedBox(height: 8),
                      CustomField(
                        controller: _emailController,
                        hintText: "example@email.com",
                      ),
                      const SizedBox(height: 20),

                      // Password
                      const Text('PASSWORD'),
                      const SizedBox(height: 8),
                      CustomField(
                        controller: _passwordController,
                        isPassword: true,
                        hintText: '**********',
                      ),
                      const SizedBox(height: 12),

                      // Remember me & Forgot Password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Remember me checkbox
                          // Row(
                          //   children: [
                          //     CustomCheckbox(),
                          //     Text(
                          //       'Remember me',
                          //       style: TextStyle(color: Color(0xFF7E8A97)),
                          //     ),
                          //   ],
                          // ),
                          const Spacer(), // This pushes the "Forgot Password" to the right
                          TextButton(
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              context.push('/forgot-password');
                            },
                            style: TextButton.styleFrom(
                              overlayColor: Palette.transparent,
                            ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(color: Palette.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Login button
                      Center(
                        child: CustomButton(
                          text: "LOG IN",
                          onPressed: _handleLogin,
                          width: 375,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Sign up text
                      Center(
                        child: Wrap(
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(color: Palette.subtitle),
                            ),
                            GestureDetector(
                              onTap: () {
                                FocusScope.of(context).unfocus();
                                context.push('/signup');
                              },
                              child: const Text(
                                'SIGN UP',
                                style: TextStyle(
                                  color: Palette.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Social media
                      const Center(
                        child: Text(
                          'Or',
                          style: TextStyle(color: Palette.subtitle),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // _buildSocialIcon(
                          //   icon: Icons.facebook,
                          //   color: Colors.indigo,
                          //   onTap: () => _handleSocialLogin("Facebook"),
                          // ),
                          // const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => _handleSocialLogin("Google"),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: Color(0xFFF0F5FA),
                              child: Image.asset(
                                'assets/icons/google_logo.png',
                                height: 24,
                                width: 24,
                              ),
                            ),
                          ),
                          // if (Platform.isIOS) ...[
                          //   const SizedBox(width: 16),
                          //   _buildSocialIcon(
                          //     icon: Icons.apple,
                          //     color: Colors.black,
                          //     onTap: () => _handleSocialLogin("Apple"),
                          //   ),
                          // ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
