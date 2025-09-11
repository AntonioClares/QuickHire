import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/views/widgets/custom_button.dart';
import 'package:quickhire/core/views/widgets/custom_field.dart';
import 'package:quickhire/core/navigation/views/widgets/custom_dialog.dart';
import 'package:quickhire/core/services/loading_service.dart';
import 'package:quickhire/core/model/job_listings_model.dart';
import 'package:quickhire/features/home/employer/viewmodel/employer_home_viewmodel.dart';

class EditJobPage extends StatefulWidget {
  final JobListing job;
  final EmployerHomeViewModel viewModel;

  const EditJobPage({super.key, required this.job, required this.viewModel});

  @override
  State<EditJobPage> createState() => _EditJobPageState();
}

class _EditJobPageState extends State<EditJobPage> {
  late final TextEditingController _jobTitleController;
  late final TextEditingController _jobDescriptionController;
  late final TextEditingController _payAmountController;

  late String _selectedJobCategory;
  late String _selectedPayType;
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
    _initializeControllers();
    _setupFormListeners();
  }

  void _initializeControllers() {
    _jobTitleController = TextEditingController(text: widget.job.title);
    _jobDescriptionController = TextEditingController(
      text: widget.job.description,
    );

    // Parse payment to extract amount and type
    final payment = widget.job.payment;
    if (payment.contains('/Hour')) {
      _selectedPayType = 'Per Hour';
      _payAmountController = TextEditingController(
        text: payment.replaceAll('RM ', '').replaceAll('/Hour', ''),
      );
    } else {
      _selectedPayType = 'Fixed Amount';
      _payAmountController = TextEditingController(
        text: payment.replaceAll('RM ', ''),
      );
    }

    // Find category from tags or use first tag as category
    _selectedJobCategory =
        widget.job.tags.isNotEmpty &&
                _jobCategories.contains(widget.job.tags.first)
            ? widget.job.tags.first
            : 'Other';
  }

  void _setupFormListeners() {
    _jobTitleController.addListener(_onFormChanged);
    _payAmountController.addListener(_onFormChanged);
    _jobDescriptionController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    final hasChanges =
        _jobTitleController.text.trim() != widget.job.title ||
        _jobDescriptionController.text.trim() != widget.job.description ||
        _payAmountController.text.trim() != _extractOriginalAmount() ||
        _selectedJobCategory != _getOriginalCategory() ||
        _selectedPayType != _getOriginalPayType();

    if (hasChanges != _hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = hasChanges;
      });
    }
  }

  String _extractOriginalAmount() {
    return widget.job.payment.replaceAll('RM ', '').replaceAll('/Hour', '');
  }

  String _getOriginalCategory() {
    return widget.job.tags.isNotEmpty &&
            _jobCategories.contains(widget.job.tags.first)
        ? widget.job.tags.first
        : 'Other';
  }

  String _getOriginalPayType() {
    return widget.job.payment.contains('/Hour') ? 'Per Hour' : 'Fixed Amount';
  }

  @override
  void dispose() {
    _jobTitleController.dispose();
    _payAmountController.dispose();
    _jobDescriptionController.dispose();
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
                        "You have unsaved changes. Are you sure you want to go back? Your changes will be lost.",
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

  Future<void> _validateAndUpdateJob() async {
    // Basic validation
    if (_jobTitleController.text.trim().isEmpty) {
      _showValidationDialog(
        'Missing Information',
        'Please enter the job title.',
      );
      return;
    }

    if (_payAmountController.text.trim().isEmpty) {
      _showValidationDialog(
        'Missing Information',
        'Please enter the payment amount.',
      );
      return;
    }

    if (_jobDescriptionController.text.trim().isEmpty) {
      _showValidationDialog(
        'Missing Information',
        'Please provide a job description.',
      );
      return;
    }

    // Pay amount validation
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

    try {
      await LoadingService.runWithLoading(context, () async {
        // Prepare payment string
        final paymentAmount = _payAmountController.text.trim();
        String paymentString;

        if (_selectedPayType == 'Fixed Amount') {
          paymentString = 'RM $paymentAmount';
        } else {
          paymentString = 'RM $paymentAmount/Hour';
        }

        // Prepare tags
        final tags = <String>[
          _selectedJobCategory,
          _selectedPayType == 'Fixed Amount' ? 'Fixed Rate' : 'Hourly',
        ];

        // Update the job listing
        await widget.viewModel.updateJobListing(
          jobId: widget.job.id,
          title: _jobTitleController.text.trim(),
          description: _jobDescriptionController.text.trim(),
          payment: paymentString,
          tags: tags,
        );
      });

      if (mounted) {
        CustomDialog.show(
          context: context,
          title: 'Job Updated!',
          message: 'Your job listing has been updated successfully.',
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
          buttonText: 'OK',
          onButtonPressed: () {
            Navigator.of(context).pop();
            context.pop(); // Go back to previous screen
          },
        );
      }
    } catch (e) {
      if (mounted) {
        _showValidationDialog(
          'Error Updating Job',
          'Failed to update your job listing. Please try again.',
        );
      }
    }
  }

  bool _isValidPayAmount(String amount) {
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

  String _getPayHintText() {
    if (_selectedPayType == 'Fixed Amount') {
      return 'e.g., 150 for the whole job';
    } else {
      return 'e.g., 25 per hour (max 999)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
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
                        // Header texts
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 35,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Edit Job',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: size.width < 350 ? 26 : 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Update your job listing details',
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

                      // Job Title
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
                              _onFormChanged();
                            },
                          ),
                        ),
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
                              _onFormChanged();
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

                      // Update Job Button
                      Center(
                        child: CustomButton(
                          text: "UPDATE JOB",
                          onPressed: _validateAndUpdateJob,
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
