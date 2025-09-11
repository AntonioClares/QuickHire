import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/views/widgets/custom_button.dart';
import 'package:quickhire/core/views/widgets/custom_field.dart';
import 'package:quickhire/core/views/widgets/custom_loading_indicator.dart';
import 'package:quickhire/core/navigation/views/widgets/custom_dialog.dart';
import 'package:quickhire/core/services/job_service.dart';
import 'package:quickhire/core/services/auth_service.dart';
import 'package:quickhire/core/views/widgets/location_picker_widget.dart';
import 'package:quickhire/core/model/location_data.dart';

class JobPostingPage extends ConsumerStatefulWidget {
  const JobPostingPage({super.key});

  @override
  ConsumerState<JobPostingPage> createState() => _JobPostingPageState();
}

class _JobPostingPageState extends ConsumerState<JobPostingPage> {
  final JobService _jobService = JobService();
  final AuthService _authService = AuthService();

  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _payAmountController = TextEditingController();
  final TextEditingController _jobDescriptionController =
      TextEditingController();
  final TextEditingController _requirementsController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  String _selectedJobCategory = 'Construction';
  String _selectedPayType = 'Fixed Amount';
  bool _isPosting = false;
  LocationData? _selectedLocation;

  // Track if user has made any changes
  bool _hasUnsavedChanges = false;

  final List<String> _jobCategories = [
    'Construction',
    'Cleaning',
    'Electrical Work',
    'Plumbing',
    'Painting',
    'Moving & Delivery',
    'Gardening & Landscaping',
    'Handyman Services',
    'Security',
    'Food Service',
    'Other',
  ];

  final List<String> _payTypes = ['Fixed Amount', 'Per Hour'];

  @override
  void initState() {
    super.initState();
    _setupFormListeners();
  }

  void _setupFormListeners() {
    // Add listeners to track changes
    _jobTitleController.addListener(_onFormChanged);
    _payAmountController.addListener(_onFormChanged);
    _jobDescriptionController.addListener(_onFormChanged);
    _requirementsController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    final hasChanges =
        _jobTitleController.text.trim().isNotEmpty ||
        _payAmountController.text.trim().isNotEmpty ||
        _jobDescriptionController.text.trim().isNotEmpty ||
        _requirementsController.text.trim().isNotEmpty ||
        _selectedLocation != null ||
        _selectedJobCategory != 'Construction' ||
        _selectedPayType != 'Fixed Amount';

    if (hasChanges != _hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _jobTitleController.dispose();
    _payAmountController.dispose();
    _jobDescriptionController.dispose();
    _requirementsController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  Future<bool> _showUnsavedChangesDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
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
                      Icon(
                        Icons.warning_outlined,
                        color: Colors.orange,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Unsaved Changes",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "You have unsaved changes. Are you sure you want to go back? Your progress will be lost.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF5E616F),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
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
    if (_hasUnsavedChanges) {
      final shouldPop = await _showUnsavedChangesDialog();
      if (shouldPop) {
        if (mounted) context.pop();
      }
    } else {
      context.pop();
    }
  }

  Future<void> _validateAndPostJob() async {
    // Prevent double submission
    if (_isPosting) return;

    // Basic validation
    if (_jobTitleController.text.trim().isEmpty) {
      _showValidationDialog(
        'Missing Information',
        'Please enter what job you need done.',
      );
      return;
    }

    if (_selectedLocation == null) {
      _showValidationDialog(
        'Missing Information',
        'Please select where the work will be done using the map.',
      );
      return;
    }

    if (_payAmountController.text.trim().isEmpty) {
      _showValidationDialog(
        'Missing Information',
        'Please enter how much you will pay.',
      );
      return;
    }

    if (_jobDescriptionController.text.trim().isEmpty) {
      _showValidationDialog(
        'Missing Information',
        'Please describe what work needs to be done.',
      );
      return;
    }

    // Pay amount validation (basic numeric check)
    if (!_isValidPayAmount(_payAmountController.text.trim())) {
      _showValidationDialog(
        'Invalid Pay Amount',
        'Please enter a valid amount (numbers only).',
      );
      return;
    }

    // Per hour rate limit validation
    if (_selectedPayType == 'Per Hour') {
      final amount = double.tryParse(_payAmountController.text.trim()) ?? 0;
      if (amount > 999) {
        _showValidationDialog(
          'Invalid Pay Amount',
          'Hourly rate cannot exceed RM 999.',
        );
        return;
      }
    }

    // Check if user is authenticated
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      _showValidationDialog(
        'Authentication Error',
        'You must be logged in to post a job.',
      );
      return;
    }

    // Start posting process
    setState(() {
      _isPosting = true;
    });

    try {
      // Prepare payment string
      final paymentAmount = _payAmountController.text.trim();
      String paymentString;

      if (_selectedPayType == 'Fixed Amount') {
        // For fixed amount, add RM prefix
        paymentString = 'RM ${paymentAmount}';
      } else {
        // For hourly rate, add RM prefix and /Hour suffix
        paymentString = 'RM ${paymentAmount}/Hour';
      }

      // Prepare tags (include job category and payment type)
      final tags = <String>[
        _selectedJobCategory,
        _selectedPayType == 'Fixed Amount' ? 'Fixed Rate' : 'Hourly',
      ];

      // Create the job listing
      await _jobService.createJobListing(
        posterUid: currentUser.uid,
        title: _jobTitleController.text.trim(),
        description: _jobDescriptionController.text.trim(),
        location: _selectedLocation!.address,
        locationData: _selectedLocation,
        payment: paymentString,
        tags: tags,
        type: _selectedJobCategory,
      );

      // If successful, show success dialog
      _showSuccessDialog();
    } catch (e) {
      // Handle any errors
      _showValidationDialog(
        'Error Posting Job',
        'Failed to post your job. Please try again. Error: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isPosting = false;
      });
    }
  }

  bool _isValidPayAmount(String amount) {
    // Check if amount is numeric (integers and decimals)
    return RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(amount);
  }

  void _showValidationDialog(String title, String message) {
    CustomDialog.show(
      context: context,
      title: title,
      message: message,
      icon: Icons.warning_amber_outlined,
      iconColor: Colors.red,
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (BuildContext dialogContext) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Job Posted!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your job has been posted successfully. Workers in your area will be able to see it and contact you.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF5E616F)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(); // Close dialog only
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.primary,
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    ).then((_) {
      // If dialog is dismissed by tapping outside, also close the page
      if (mounted) {
        context.pop();
      }
    });
  }

  String _getPayHintText() {
    if (_selectedPayType == 'Fixed Amount') {
      return 'e.g., 150 for the whole job';
    } else {
      return 'e.g., 25 per hour (max 999)';
    }
  }

  void _onLocationSelected(LocationData location) {
    setState(() {
      _selectedLocation = location;
    });
    _onFormChanged(); // Track changes
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Calculate responsive header height with minimum constraints
    final headerHeight = (size.height * 0.17).clamp(160.0, 200.0);

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final shouldPop = await _showUnsavedChangesDialog();
        if (shouldPop && mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Header section that can collapse
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
                                'Post a Job',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: size.width < 350 ? 26 : 30,
                                  fontWeight: FontWeight.bold,
                                  color: Palette.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Find workers to get your job done',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: size.width < 350 ? 14 : 16,
                                  color: Colors.white,
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
            // Form content
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),

                      // Job Title/Description
                      const Text('JOB TITLE'),
                      const SizedBox(height: 8),
                      CustomField(
                        hintText: "e.g., Fix leaking pipe",
                        controller: _jobTitleController,
                      ),
                      const SizedBox(height: 20),
                      // Job Description
                      const Text('JOB DESCRIPTION'),
                      const SizedBox(height: 8),
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F5FA),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: _jobDescriptionController,
                          maxLines: 5,
                          cursorColor: Palette.primary,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.all(20),
                            hintText:
                                "Describe exactly what needs to be done, any special instructions, tools needed, etc.",
                            hintStyle: TextStyle(color: Color(0xFFA0A5BA)),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Job Category Dropdown
                      const Text('JOB CATEGORY'),
                      const SizedBox(height: 8),
                      Container(
                        height: 75,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F5FA),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: DropdownButtonFormField<String>(
                            value: _selectedJobCategory,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                            ),
                            dropdownColor: Colors.white,
                            items:
                                _jobCategories.map((String category) {
                                  return DropdownMenuItem<String>(
                                    value: category,
                                    child: Text(category),
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedJobCategory = newValue!;
                              });
                              _onFormChanged(); // Track changes
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Location Picker
                      const Text('JOB LOCATION'),
                      const SizedBox(height: 8),
                      LocationPickerWidget(
                        initialLocation: _selectedLocation,
                        onLocationSelected: _onLocationSelected,
                      ),
                      const SizedBox(height: 20),

                      // Pay Type
                      const Text('PAYMENT TYPE'),
                      const SizedBox(height: 8),
                      Container(
                        height: 75,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F5FA),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: DropdownButtonFormField<String>(
                            value: _selectedPayType,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                            ),
                            dropdownColor: Colors.white,
                            items:
                                _payTypes.map((String type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedPayType = newValue!;
                              });
                              _onFormChanged(); // Track changes
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Pay Amount
                      Text(
                        'PAYMENT AMOUNT (${_selectedPayType.toUpperCase()})',
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 75,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F5FA),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: _payAmountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                          cursorColor: Palette.primary,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(20),
                            hintText: _getPayHintText(),
                            hintStyle: const TextStyle(
                              color: Color(0xFFA0A5BA),
                            ),
                            border: const OutlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Post Job Button
                      Center(
                        child:
                            _isPosting
                                ? const CustomLoadingIndicator()
                                : CustomButton(
                                  text: "POST JOB",
                                  onPressed: _validateAndPostJob,
                                ),
                      ),
                      const SizedBox(height: 16),

                      // Info text
                      const Text(
                        'Workers in your area will see your job posting and can contact you directly.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5E616F),
                        ),
                      ),
                      // Add SafeArea bottom padding to prevent overlap with system navigation
                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 32,
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
