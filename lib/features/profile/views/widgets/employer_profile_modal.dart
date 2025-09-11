import 'package:flutter/material.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/services/auth_service.dart';
import 'package:quickhire/core/views/widgets/custom_loading_indicator.dart';
import 'package:quickhire/core/views/widgets/custom_button.dart';
import 'package:quickhire/core/services/loading_service.dart';
import 'package:quickhire/core/navigation/views/widgets/custom_dialog.dart';
import 'package:quickhire/features/messaging/services/messaging_service.dart';
import 'package:quickhire/features/messaging/view/pages/chat_page.dart';

class EmployerProfileModal extends StatefulWidget {
  final String employerUid;

  const EmployerProfileModal({super.key, required this.employerUid});

  @override
  State<EmployerProfileModal> createState() => _EmployerProfileModalState();
}

class _EmployerProfileModalState extends State<EmployerProfileModal> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String _employerName = '';
  DateTime? _accountCreationDate;

  @override
  void initState() {
    super.initState();
    _loadEmployerData();
  }

  Future<void> _loadEmployerData() async {
    try {
      final userDoc = await _authService.getUserDocument(widget.employerUid);
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        setState(() {
          _employerName = userData['name'] ?? 'Unknown';
          _accountCreationDate = userData['createdAt']?.toDate();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _employerName = 'Unknown';
        _isLoading = false;
      });
    }
  }

  String _formatMemberSince() {
    if (_accountCreationDate == null) return 'Member since Unknown';

    final now = DateTime.now();
    final difference = now.difference(_accountCreationDate!);

    if (difference.inDays < 30) {
      return 'Member since ${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Member since $months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Member since $years year${years > 1 ? 's' : ''} ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          if (_isLoading) ...[
            const CustomLoadingIndicator(size: 60),
            const SizedBox(height: 20),
            const Text('Loading profile...'),
          ] else ...[
            // Profile Picture
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Palette.primary.withAlpha(30),
                border: Border.all(color: Palette.primary, width: 3),
              ),
              child: const Icon(Icons.person, size: 40, color: Palette.primary),
            ),
            const SizedBox(height: 16),

            // Name
            Text(
              _employerName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Member since
            Text(
              _formatMemberSince(),
              style: const TextStyle(fontSize: 14, color: Palette.subtitle),
            ),
            const SizedBox(height: 20),

            // View Full Profile Button
            CustomButton(
              text: 'VIEW FULL PROFILE',
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to full profile page
                _showFullProfile(context);
              },
              backgroundColor: Palette.primary,
              foregroundColor: Colors.white,
            ),
            const SizedBox(height: 12),

            // Message Button
            CustomButton(
              text: 'MESSAGE EMPLOYER',
              onPressed: () => _showMessageModalFromMain(context),
              backgroundColor: Palette.secondary,
              foregroundColor: Colors.white,
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showFullProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EmployerFullProfilePage(
              employerUid: widget.employerUid,
              employerName: _employerName,
              memberSince: _formatMemberSince(),
            ),
      ),
    );
  }

  void _showMessageModalFromMain(BuildContext context) async {
    final messagingService = MessagingService();

    try {
      await LoadingService.runWithLoading(context, () async {
        final conversationId = await messagingService.createOrGetConversation(
          widget.employerUid,
        );

        if (context.mounted) {
          Navigator.pop(context); // Close the profile modal
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ChatPage(
                    conversationId: conversationId,
                    otherUserName: _employerName,
                  ),
            ),
          );
        }
      });
    } catch (e) {
      if (context.mounted) {
        CustomDialog.show(
          context: context,
          title: 'Error',
          message: 'Failed to start conversation: ${e.toString()}',
          icon: Icons.error_outline,
          iconColor: Colors.red,
          buttonText: 'OK',
        );
      }
    }
  }
}

class EmployerFullProfilePage extends StatelessWidget {
  final String employerUid;
  final String employerName;
  final String memberSince;

  const EmployerFullProfilePage({
    super.key,
    required this.employerUid,
    required this.employerName,
    required this.memberSince,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final headerHeight = (size.height * 0.17).clamp(160.0, 200.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Header section
          SliverAppBar(
            expandedHeight: headerHeight,
            backgroundColor: Palette.primary,
            pinned: false,
            floating: false,
            snap: false,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(color: Palette.primary),
                child: SafeArea(
                  child: Stack(
                    children: [
                      // Back button (matching account information page style)
                      Positioned(
                        top: 10,
                        left: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
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
                      // Header texts - centered and responsive
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 35,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Employer Profile',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: size.width < 350 ? 26 : 30,
                                fontWeight: FontWeight.bold,
                                color: Palette.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'View employer details and information',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: size.width < 350 ? 14 : 16,
                                color: Palette.white.withOpacity(0.9),
                              ),
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
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Picture
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Palette.primary.withAlpha(30),
                      border: Border.all(color: Palette.primary, width: 4),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Palette.primary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name
                  Text(
                    employerName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Member since
                  Text(
                    memberSince,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Palette.subtitle,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Message Button
                  CustomButton(
                    text: 'MESSAGE EMPLOYER',
                    onPressed: () => _showMessageModal(context),
                    backgroundColor: Palette.secondary,
                    foregroundColor: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageModal(BuildContext context) async {
    final messagingService = MessagingService();

    try {
      await LoadingService.runWithLoading(context, () async {
        final conversationId = await messagingService.createOrGetConversation(
          employerUid,
        );

        if (context.mounted) {
          Navigator.pop(context); // Close the profile modal
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ChatPage(
                    conversationId: conversationId,
                    otherUserName: employerName,
                  ),
            ),
          );
        }
      });
    } catch (e) {
      if (context.mounted) {
        CustomDialog.show(
          context: context,
          title: 'Error',
          message: 'Failed to start conversation: ${e.toString()}',
          icon: Icons.error_outline,
          iconColor: Colors.red,
          buttonText: 'OK',
        );
      }
    }
  }
}
