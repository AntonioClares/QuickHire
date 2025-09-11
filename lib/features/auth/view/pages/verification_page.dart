import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/views/widgets/custom_button.dart';
import 'package:quickhire/core/services/auth_service.dart';
import 'package:quickhire/core/navigation/views/widgets/custom_dialog.dart';
import 'package:quickhire/features/home/employee/views/pages/home_page.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  bool _isEmailVerified = false;
  int _secondsRemaining = 30;
  bool _canResend = false;
  Timer? _resendTimer;
  Timer? _verificationCheckTimer;

  @override
  void initState() {
    super.initState();
    _checkInitialVerificationStatus();
    _startResendCountdown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _verificationCheckTimer?.cancel();
    super.dispose();
  }

  void _checkInitialVerificationStatus() {
    _isEmailVerified =
        FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (!_isEmailVerified) {
      sendVerificationEmail();
      _startVerificationCheck();
    }
  }

  void _startVerificationCheck() {
    _verificationCheckTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkEmailVerified(),
    );
  }

  Future<void> _checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser!.reload();

    final isVerified = FirebaseAuth.instance.currentUser!.emailVerified;

    if (isVerified && mounted) {
      _verificationCheckTimer?.cancel();
      // Navigate based on user type instead of directly to home
      await _navigateBasedOnUserType();
    } else {
      setState(() {
        _isEmailVerified = isVerified;
      });
    }
  }

  Future<void> _navigateBasedOnUserType() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
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

  void sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();
    } catch (e) {
      debugPrint('Error sending verification email: ${e.toString()}');
    }
  }

  void _startResendCountdown() {
    _secondsRemaining = 30;
    _canResend = false;

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  void _resendVerificationEmail() {
    sendVerificationEmail();
    _startResendCountdown();
  }

  // Handle back button press
  Future<void> _handleBackPress() async {
    // Sign out the user and go back to login page
    await authService.value.signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  String get _userEmail =>
      FirebaseAuth.instance.currentUser?.email ?? 'your email';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_isEmailVerified) {
      return const HomePage();
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildBackgroundImage(size),
          _buildBackButton(),
          _buildHeaderText(size),
          _buildContentCard(size),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage(Size size) {
    return Container(
      height: size.height * 0.4,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF121223),
        image: DecorationImage(
          image: AssetImage('assets/images/auth_login_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      child: GestureDetector(
        onTap: _handleBackPress, // Updated to use the new handler
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF5E616F),
            size: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderText(Size size) {
    return Positioned(
      top: size.height * 0.16,
      left: 0,
      right: 0,
      child: Column(
        children: [
          const Text(
            'Verify Your Email',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Palette.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We have sent a verification email to:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          Text(
            _userEmail,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(Size size) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: size.height * 0.70,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.email_outlined, color: Palette.primary, size: 75),
            const SizedBox(height: 16),
            Text(
              'Verify your email address',
              style: TextStyle(
                fontSize: 18,
                color: Palette.secondary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Please check your email inbox to verify your account before proceeding.',
              style: TextStyle(fontSize: 16, color: Palette.subtitle),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            _buildResendOption(),
            const SizedBox(height: 30),
            CustomButton(
              text: "ALREADY VERIFIED",
              onPressed: () async {
                // Check verification status and navigate accordingly
                await FirebaseAuth.instance.currentUser!.reload();
                final isVerified =
                    FirebaseAuth.instance.currentUser!.emailVerified;

                if (isVerified) {
                  await _navigateBasedOnUserType();
                } else {
                  // Show a message that they're not verified yet
                  CustomDialog.show(
                    context: context,
                    title: 'Verification Required',
                    message: 'Please verify your email first',
                    icon: Icons.email_outlined,
                    iconColor: Colors.orange,
                    buttonText: 'OK',
                  );
                }
              },
              width: 375,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResendOption() {
    return _canResend
        ? GestureDetector(
          onTap: _resendVerificationEmail,
          child: Text(
            'Resend verification email',
            style: TextStyle(
              color: Palette.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        )
        : Text(
          'Resend available in $_secondsRemaining seconds',
          style: const TextStyle(fontSize: 14, color: Color(0xFF5E616F)),
        );
  }
}
