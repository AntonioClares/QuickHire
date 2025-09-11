import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quickhire/core/services/auth_service.dart';
import 'package:quickhire/core/services/loading_service.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/views/widgets/custom_button.dart';
import 'package:quickhire/core/views/widgets/custom_field.dart';
import 'package:quickhire/core/views/widgets/custom_loading_indicator.dart';
import 'package:quickhire/core/navigation/views/widgets/custom_dialog.dart';

class AccountInformationPage extends ConsumerStatefulWidget {
  const AccountInformationPage({super.key});

  @override
  ConsumerState<AccountInformationPage> createState() =>
      _AccountInformationPageState();
}

class _AccountInformationPageState
    extends ConsumerState<AccountInformationPage> {
  final TextEditingController _nameController = TextEditingController();

  String _currentUserType = '';
  String _selectedUserType = ''; // New field to track selected user type
  String _originalUserType = ''; // Store original user type for comparison
  String _originalName = ''; // Store original name for comparison
  bool _canChangeName = true;
  int _daysUntilNameChange = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Add listener to name controller to update button state when user types
    _nameController.addListener(() {
      setState(() {}); // Trigger rebuild to update button state
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final userData = await authService.value.getCurrentUserData();
      final user = authService.value.currentUser;

      if (userData != null && user != null) {
        _nameController.text = userData.name;
        _currentUserType = userData.type ?? '';
        _selectedUserType = _currentUserType; // Initialize selected type
        _originalUserType = _currentUserType; // Store original user type
        _originalName = userData.name; // Store original name
      }

      _canChangeName = await authService.value.canChangeUserName();
      if (!_canChangeName) {
        _daysUntilNameChange = await authService.value.getDaysUntilNameChange();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (!_validateForm()) return;

    try {
      await LoadingService.runWithLoading(context, () async {
        final user = authService.value.currentUser;
        if (user == null) throw Exception('No user found');

        bool hasChanges = false;

        // Update name if changed and allowed
        if (_nameController.text.trim() != _originalName &&
            _nameController.text.trim().isNotEmpty &&
            _canChangeName) {
          final success = await authService.value.updateUserName(
            _nameController.text.trim(),
          );
          if (!success) {
            throw Exception('Failed to update name. Please try again later.');
          }
          hasChanges = true;
        }

        // Update user type if changed
        if (_selectedUserType != _originalUserType &&
            _selectedUserType.isNotEmpty) {
          final success = await authService.value.updateUserType(
            _selectedUserType,
          );
          if (!success) {
            throw Exception(
              'Failed to update user type. Please try again later.',
            );
          }
          hasChanges = true;
        }

        if (hasChanges) {
          await _loadUserData(); // Reload data to reflect changes
        }
      });
      if (mounted) {
        // Update original values to reflect the saved state
        _originalName = _nameController.text.trim();
        _originalUserType = _selectedUserType;
        _currentUserType = _selectedUserType;

        CustomDialog.show(
          context: context,
          title: "Success",
          message: "Your account information has been updated successfully.",
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
          onButtonPressed: () {
            // Close the entire page when dialog is dismissed
            context.pop();
          },
        );
      }
    } catch (e) {
      CustomDialog.show(
        context: context,
        title: "Error",
        message: e.toString().replaceFirst('Exception: ', ''),
        icon: Icons.error_outline,
        iconColor: Colors.red,
      );
    }
  }

  bool _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      CustomDialog.show(
        context: context,
        title: "Invalid Input",
        message: "Please enter a valid name.",
        icon: Icons.warning_outlined,
        iconColor: Colors.orange,
      );
      return false;
    }

    if (_nameController.text.trim().length < 2) {
      CustomDialog.show(
        context: context,
        title: "Invalid Input",
        message: "Name must be at least 2 characters long.",
        icon: Icons.warning_outlined,
        iconColor: Colors.orange,
      );
      return false;
    }
    return true;
  }

  bool _hasUnsavedChanges() {
    final nameChanged =
        _canChangeName && _nameController.text.trim() != _originalName;
    final userTypeChanged = _selectedUserType != _originalUserType;
    return nameChanged || userTypeChanged;
  }

  Future<bool> _showUnsavedChangesDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false, // Prevent dismissing by tapping outside
          builder:
              (BuildContext dialogContext) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                backgroundColor: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon at the top
                      Icon(Icons.warning_outlined, color: Colors.red, size: 48),
                      const SizedBox(height: 16),

                      // Title
                      const Text(
                        "Unsaved Changes",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Message
                      const Text(
                        "You have unsaved changes. Are you sure you want to go back? Your changes will not be saved.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF5E616F),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed:
                                  () => Navigator.of(dialogContext).pop(false),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: Palette.primary.withOpacity(0.3),
                                  ),
                                ),
                              ),
                              child: Text(
                                "Stay",
                                style: TextStyle(
                                  color: Palette.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  () => Navigator.of(dialogContext).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Palette.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                "Leave",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        ) ??
        false;
  }

  Future<void> _handleBackNavigation() async {
    if (_hasUnsavedChanges()) {
      final shouldPop = await _showUnsavedChangesDialog();
      if (shouldPop) {
        if (mounted) context.pop();
      }
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final headerHeight = (size.height * 0.17).clamp(160.0, 200.0);

    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges()) {
          return await _showUnsavedChangesDialog();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body:
            _isLoading
                ? const Center(child: CustomLoadingIndicator(size: 80.0))
                : CustomScrollView(
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
                          decoration: const BoxDecoration(
                            color: Palette.primary,
                          ),
                          child: SafeArea(
                            child: Stack(
                              children: [
                                // Back button
                                Positioned(
                                  top: 10,
                                  left: 16,
                                  child: GestureDetector(
                                    onTap: _handleBackNavigation,
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
                                        'Account Information',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: size.width < 350 ? 26 : 30,
                                          fontWeight: FontWeight.bold,
                                          color: Palette.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Update your personal details',
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPersonalInfoSection(),
                            const SizedBox(height: 32),
                            _buildUserTypeSection(),
                            const SizedBox(height: 40),
                            _buildSaveButton(),
                            // Add SafeArea bottom padding to prevent overlap with system navigation
                            SizedBox(
                              height:
                                  MediaQuery.of(context).padding.bottom + 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Palette.secondary,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Full Name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Palette.secondary,
              ),
            ),
            const SizedBox(height: 8),
            AbsorbPointer(
              absorbing: !_canChangeName,
              child: Opacity(
                opacity: _canChangeName ? 1.0 : 0.6,
                child: CustomField(
                  controller: _nameController,
                  hintText: 'Enter your full name',
                ),
              ),
            ),
            if (!_canChangeName) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You can change your name again in $_daysUntilNameChange day${_daysUntilNameChange == 1 ? '' : 's'}.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildUserTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User Type',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Palette.secondary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildUserTypeCard(
                title: 'Employee',
                description: 'Looking for work',
                userType: 'employee',
                isSelected: _selectedUserType == 'employee',
                isCurrent: _currentUserType == 'employee',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildUserTypeCard(
                title: 'Employer',
                description: 'Need help with work',
                userType: 'employer',
                isSelected: _selectedUserType == 'employer',
                isCurrent: _currentUserType == 'employer',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserTypeCard({
    required String title,
    required String description,
    required String userType,
    required bool isSelected,
    required bool isCurrent,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUserType = userType;
        });
      },
      child: Container(
        // Set a minimum height to ensure both cards are equal
        constraints: const BoxConstraints(minHeight: 120),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected
                    ? Palette.primary
                    : Palette.imagePlaceholder.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  userType == 'employee' ? Icons.person : Icons.business,
                  color: isSelected ? Palette.primary : Palette.secondary,
                  size: 24,
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: Palette.primary, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Palette.secondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(fontSize: 12, color: Palette.subtitle),
            ),
            // Always reserve space for the "Current" tag to maintain equal height
            const SizedBox(height: 8),
            SizedBox(
              height: 20, // Fixed height for the tag area
              child:
                  isCurrent
                      ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Palette.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Current',
                          style: TextStyle(
                            fontSize: 10,
                            color: Palette.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                      : const SizedBox(), // Empty space to maintain height
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final hasChanges = _hasUnsavedChanges();

    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'SAVE CHANGES',
        onPressed: hasChanges ? _saveChanges : null,
        backgroundColor:
            hasChanges ? Palette.primary : Palette.imagePlaceholder,
        foregroundColor: Palette.white,
      ),
    );
  }
}
