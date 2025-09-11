import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quickhire/core/services/auth_service.dart';
import 'package:quickhire/core/services/loading_service.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/views/widgets/custom_button.dart';
import 'package:quickhire/core/navigation/views/widgets/custom_dialog.dart';
import 'package:quickhire/core/views/widgets/custom_field.dart';
import 'package:quickhire/features/auth/services/signup_validation_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController retypePasswordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    retypePasswordController.dispose();
    super.dispose();
  }

  void validateAndRegister() async {
    // Validate form fields
    final validationResult = ValidationService.validateSignupForm(
      name: nameController.text,
      email: emailController.text,
      password: passwordController.text,
      retypePassword: retypePasswordController.text,
    );

    // Show error dialog if validation fails
    if (!validationResult.isValid) {
      CustomDialog.show(
        context: context,
        title: validationResult.errorTitle!,
        message: validationResult.errorMessage!,
      );
      return;
    }

    // If validation passes, show loading and proceed with registration
    try {
      await LoadingService.runWithLoading(context, () async {
        // Create account first
        await authService.value.createAccount(
          email: emailController.text,
          password: passwordController.text,
        );

        // Update user profile with name
        await authService.value.updateUsername(nameController.text);
      });

      // If registration is successful, navigate to verification page
      if (mounted) {
        context.push('/verification');
      }
    } on FirebaseAuthException catch (e) {
      // Show error dialog for Firebase auth exceptions
      CustomDialog.show(
        context: context,
        title: "Registration Failed",
        message: e.message ?? "An error occurred during registration.",
      );
    } catch (e) {
      // Show error dialog for other exceptions
      CustomDialog.show(
        context: context,
        title: "Registration Failed",
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
              height: size.height,
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
                  Navigator.pop(context);
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

            // Main content
            Column(
              children: [
                // Header section
                Container(
                  height: size.height * 0.3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Sign Up',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Palette.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please sign up to get started',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Form section
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name field
                          const Text('NAME'),
                          const SizedBox(height: 8),
                          CustomField(
                            hintText: "John Doe",
                            controller: nameController,
                          ),
                          const SizedBox(height: 20),

                          // Email field
                          const Text('EMAIL'),
                          const SizedBox(height: 8),
                          CustomField(
                            hintText: "example@email.com",
                            controller: emailController,
                          ),
                          const SizedBox(height: 20),

                          // Password field
                          const Text('PASSWORD'),
                          const SizedBox(height: 8),
                          CustomField(
                            hintText: "**********",
                            isPassword: true,
                            controller: passwordController,
                          ),
                          const SizedBox(height: 20),

                          // Re-type password field
                          const Text('RE-TYPE PASSWORD'),
                          const SizedBox(height: 8),
                          CustomField(
                            hintText: "**********",
                            isPassword: true,
                            controller: retypePasswordController,
                          ),
                          const SizedBox(height: 30),

                          // Sign up button
                          Center(
                            child: CustomButton(
                              text: "SIGN UP",
                              onPressed: validateAndRegister,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
