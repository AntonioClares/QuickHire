import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quickhire/core/services/auth_service.dart';
import 'package:quickhire/core/services/loading_service.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/views/widgets/custom_button.dart';
import 'package:quickhire/core/navigation/views/widgets/custom_dialog.dart';
import 'package:quickhire/core/views/widgets/custom_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    // Check if email is empty
    if (email.isEmpty) {
      CustomDialog.show(
        context: context,
        title: "Empty Field",
        message: "Please enter your email address.",
      );
      return;
    }

    // Validate email format
    if (!_isValidEmail(email)) {
      CustomDialog.show(
        context: context,
        title: "Invalid Email",
        message: "Please enter a valid email address.",
      );
      return;
    }

    try {
      // Show loading indicator while processing
      await LoadingService.runWithLoading(context, () async {
        // Try to find the email in Firebase
        await authService.value.resetPassword(email);
      });

      // If successful, show success dialog then navigate to login
      if (mounted) {
        // Show success dialog
        CustomDialog.show(
          icon: Icons.mark_email_read_outlined,
          iconColor: Palette.primary,
          context: context,
          title: "Password Reset Email Sent",
          message:
              "Check your email inbox for instructions to reset your password.",
          onButtonPressed: () {
            // Navigate back to login page and clear stack
            context.go('/login');
          },
          onDismissed: () {
            // Navigate back to login page and clear stack
            context.go('/login');
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase-specific errors
      String errorMessage = "An error occurred. Please try again.";

      if (e.code == 'user-not-found') {
        errorMessage = "No account found with this email address.";
      }

      CustomDialog.show(
        context: context,
        title: "Reset Failed",
        message: errorMessage,
      );
    } catch (e) {
      // Handle generic errors
      CustomDialog.show(
        context: context,
        title: "Reset Failed",
        message: "An unexpected error occurred. Please try again.",
      );
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

            // Back button
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  context.pop();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0xFF5E616F),
                      size: 15,
                    ),
                  ),
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
                    'Forgot Password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Palette.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Enter your email to reset your password',
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
                      // Icon and explanation
                      Center(
                        child: Icon(
                          Icons.lock_reset,
                          color: Palette.primary,
                          size: 75,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Reset your password',
                          style: TextStyle(
                            fontSize: 18,
                            color: Palette.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Enter your registered email address below. We will send instructions to help you reset your password.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Palette.subtitle,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Email
                      const Text('EMAIL'),
                      const SizedBox(height: 8),
                      CustomField(
                        hintText: "example@email.com",
                        controller: _emailController,
                      ),
                      const SizedBox(height: 30),

                      Center(
                        child: CustomButton(
                          text: "RESET PASSWORD",
                          onPressed: _resetPassword,
                          width: 375,
                        ),
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
