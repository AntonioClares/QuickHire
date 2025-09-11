import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quickhire/core/navigation/views/widgets/custom_dialog.dart';
import 'package:quickhire/core/services/auth_service.dart';
import 'package:quickhire/core/services/loading_service.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/views/widgets/custom_button.dart';
import 'package:quickhire/core/views/pages/main_navigation_page.dart';
import 'package:quickhire/features/profile/view/widgets/profile_card.dart';
import 'package:quickhire/core/views/widgets/custom_loading_indicator.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  Future<void> _handleSignOut() async {
    CustomDialog.show(
      context: context,
      title: "Sign Out",
      message: "Are you sure you want to sign out of your account?",
      buttonText: "SIGN OUT",
      icon: Icons.logout,
      onButtonPressed: () async {
        context.pop(); // Close the dialog first
        try {
          await LoadingService.runWithLoading(context, () async {
            await authService.value.signOut();
          });
          if (mounted) {
            context.go('/login');
          }
        } catch (e) {
          if (mounted) {
            CustomDialog.show(
              context: context,
              title: "Sign Out Failed",
              message: "An error occurred while signing out. Please try again.",
              icon: Icons.error_outline,
              iconColor: Colors.red,
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final currentUser = authService.value.currentUser;

    // If no user, show loading (router will handle navigation)
    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Palette.background,
        body: Center(child: CustomLoadingIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Palette.background,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              _buildHeader(), // Header
              const SizedBox(
                height: 60,
              ), // Space to accommodate overlapping profile card
            ],
          ),
          // Profile card overlapping header and content
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25 - 60,
            left: 24,
            right: 24,
            child: Column(
              children: [
                ProfileCard(user: currentUser),
                const SizedBox(height: 20),
                Column(
                  children: [
                    _buildProfileOptions(), // Options
                    const SizedBox(height: 20),
                    CustomButton(
                      text: "SIGN OUT",
                      onPressed: _handleSignOut,
                      width: size.width.round(),
                      backgroundColor: Colors.red,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.29,
      decoration: const BoxDecoration(color: Palette.primary),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Palette.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your account settings',
                style: TextStyle(
                  fontSize: 14,
                  color: Palette.white.withAlpha(220),
                ),
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOptions() {
    final options = [
      _ProfileOption(
        icon: Icons.person_outline,
        title: 'Account Information',
        subtitle: 'Update your personal details',
      ),
      // _ProfileOption(
      //   icon: Icons.settings_outlined,
      //   title: 'Settings',
      //   subtitle: 'App preferences and notifications',
      // ),
      // _ProfileOption(
      //   icon: Icons.help_outline,
      //   title: 'Help & Support',
      //   subtitle: 'Get help and contact support',
      // ),
    ];

    return Column(
      children:
          options
              .map(
                (option) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildProfileOptionCard(option),
                ),
              )
              .toList(),
    );
  }

  Widget _buildProfileOptionCard(_ProfileOption option) {
    return GestureDetector(
      onTap: () {
        if (option.title == 'Account Information') {
          context.push('/account-information');
        } else {
          CustomDialog.show(
            context: context,
            title: 'Coming Soon',
            message: '${option.title} - Coming Soon',
            icon: Icons.info_outline,
            iconColor: Palette.primary,
            buttonText: 'OK',
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Palette.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Palette.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(option.icon, color: Palette.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    option.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Palette.subtitle,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Palette.subtitle, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ProfileOption {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
