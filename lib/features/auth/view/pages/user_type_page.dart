import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/services/auth_service.dart';
import 'package:quickhire/core/services/loading_service.dart';
import 'package:quickhire/core/navigation/views/widgets/custom_dialog.dart';

class UserTypePage extends StatefulWidget {
  final Function(String)? onUserTypeSelected;

  const UserTypePage({super.key, this.onUserTypeSelected});

  @override
  State<UserTypePage> createState() => _UserTypePageState();
}

class _UserTypePageState extends State<UserTypePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleUserTypeSelection(String userType) async {
    try {
      // Show loading while updating user type
      await LoadingService.runWithLoading(
        context,
        () => authService.value.updateUserType(userType),
      );

      // Call the optional callback if provided
      widget.onUserTypeSelected?.call(userType);

      // Navigate to home page after successful update
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      // Show error dialog if something goes wrong
      if (mounted) {
        CustomDialog.show(
          context: context,
          title: "Selection Failed",
          message: "Failed to save your selection. Please try again.",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                children: [
                  // Back button

                  // Header Section
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Palette.primary.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_search_rounded,
                            size: 48,
                            color: Palette.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Let's set things up for you",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Tell us what you're here for,\njob hunting or hiring?",
                          style: TextStyle(
                            fontSize: 16,
                            color: Palette.subtitle,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Cards Section
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Employer Option
                        _buildUserTypeCard(
                          context: context,
                          title: 'Employer',
                          description:
                              'Need help with work? Find reliable workers here.',
                          animationPath: 'assets/animations/employer.json',
                          iconColor: Colors.blue,
                          isEmployer: true,
                          onTap: () => _handleUserTypeSelection('employer'),
                        ),

                        const SizedBox(height: 20),

                        // Employee Option
                        _buildUserTypeCard(
                          context: context,
                          title: 'Employee',
                          description:
                              'Looking for work? See what jobs are available.',
                          animationPath: 'assets/animations/employee.json',
                          iconColor: Colors.green,
                          isEmployer: false,
                          onTap: () => _handleUserTypeSelection('employee'),
                        ),
                      ],
                    ),
                  ),

                  // Footer
                  const Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "Don't worry, you can change this later",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeCard({
    required BuildContext context,
    required String title,
    required String description,
    required String animationPath,
    required Color iconColor,
    required bool isEmployer,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween(begin: 1.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTapDown: (_) => setState(() {}),
            onTapUp: (_) => setState(() {}),
            onTapCancel: () => setState(() {}),
            onTap: () {
              // Add haptic feedback
              HapticFeedback.selectionClick();

              // Scale animation
              setState(() {});

              // Call the callback after a short delay for visual feedback
              Future.delayed(const Duration(milliseconds: 100), () {
                onTap();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: iconColor.withAlpha(50), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withAlpha(15),
                    spreadRadius: 0,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.grey.withAlpha(13),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Animation Container
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: iconColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Transform.translate(
                        offset: isEmployer ? const Offset(-17, 0) : Offset.zero,
                        child: Lottie.asset(
                          animationPath,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: iconColor.withAlpha(50),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Popular',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: iconColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: iconColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
