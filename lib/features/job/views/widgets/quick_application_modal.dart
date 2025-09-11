import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/views/widgets/custom_button.dart';
import 'package:quickhire/core/views/widgets/custom_loading_indicator.dart';
import 'package:quickhire/core/model/job_listings_model.dart';
import 'package:quickhire/core/views/widgets/poster_name_widget.dart';
import 'package:quickhire/features/profile/views/widgets/employer_profile_modal.dart';
import 'package:quickhire/core/services/loading_service.dart';
import 'package:quickhire/core/navigation/views/widgets/custom_dialog.dart';
import 'package:quickhire/core/services/auth_service.dart';
import 'package:quickhire/core/views/widgets/static_map_widget.dart';
import 'package:quickhire/features/job_application/viewmodels/job_application_viewmodel.dart';

class QuickApplicationModal extends ConsumerStatefulWidget {
  final JobListing job;
  final bool hideViewFullListing;

  const QuickApplicationModal({
    super.key,
    required this.job,
    this.hideViewFullListing = false,
  });

  @override
  ConsumerState<QuickApplicationModal> createState() =>
      _QuickApplicationModalState();
}

class _QuickApplicationModalState extends ConsumerState<QuickApplicationModal> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Update message in viewmodel when text changes
    _messageController.addListener(() {
      ref
          .read(jobApplicationFormViewModelProvider.notifier)
          .updateMessage(_messageController.text);
    });
  }

  Future<void> _submitApplication() async {
    final viewModel = ref.read(jobApplicationFormViewModelProvider.notifier);

    final success = await viewModel.submitApplication(widget.job);

    if (success && mounted) {
      // Invalidate providers to refresh data immediately - force refresh
      ref.invalidate(hasAppliedProvider(widget.job.id));
      ref.invalidate(userApplicationsProvider);
      ref.invalidate(jobApplicationsProvider(widget.job.id));
      ref.invalidate(jobApplicationCountProvider(widget.job.id));

      // Give a brief moment for the invalidation to propagate
      await Future.delayed(const Duration(milliseconds: 100));

      Navigator.of(context).pop();

      CustomDialog.show(
        context: context,
        title: 'Application Submitted!',
        message:
            'Your application has been successfully submitted. The employer will get back to you soon.',
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
      );
    }
    // Error handling is done in the viewmodel and displayed in UI
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobApplicationFormViewModelProvider);
    final hasAppliedAsync = ref.watch(hasAppliedProvider(widget.job.id));

    return hasAppliedAsync.when(
      data: (hasApplied) {
        // If user has already applied, show a message instead of the form
        if (hasApplied) {
          return _buildAlreadyAppliedView(context);
        }

        return _buildApplicationForm(context, state);
      },
      loading: () => _buildLoadingView(context),
      error: (error, stackTrace) => _buildApplicationForm(context, state),
    );
  }

  Widget _buildAlreadyAppliedView(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Application Already Submitted',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Palette.secondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'You have already applied for this job. Please wait for the employer to respond to your application.',
              style: TextStyle(fontSize: 14, color: Palette.subtitle),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: "Close",
              onPressed: () => Navigator.of(context).pop(),
              backgroundColor: Palette.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.3,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: const Center(child: CustomLoadingIndicator()),
    );
  }

  Widget _buildApplicationForm(
    BuildContext context,
    JobApplicationFormState state,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Center(
            child: Text(
              'Quick Application',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Job details
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Palette.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.job.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Palette.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.job.location,
                  style: const TextStyle(fontSize: 14, color: Palette.subtitle),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.job.payment,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Message section
          const Text(
            'Tell the employer why you\'re interested:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Message field
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F5FA),
              borderRadius: BorderRadius.circular(14),
              border:
                  state.error != null
                      ? Border.all(color: Colors.red, width: 1)
                      : null,
            ),
            child: TextField(
              controller: _messageController,
              maxLines: 5,
              cursorColor: Palette.primary,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(16),
                hintText: "Hi! I'm interested in this position because...",
                hintStyle: TextStyle(color: Color(0xFFA0A5BA)),
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),
          ),

          // Error message
          if (state.error != null) ...[
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],

          const SizedBox(height: 20),

          // Submit button
          Center(
            child: CustomButton(
              text: state.isSubmitting ? 'SUBMITTING...' : 'SUBMIT APPLICATION',
              onPressed: state.isSubmitting ? null : () => _submitApplication(),
              backgroundColor: Palette.primary,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),

          // View full listing button (only show if not hiding it)
          if (!widget.hideViewFullListing) ...[
            Center(
              child: CustomButton(
                text: 'VIEW FULL LISTING',
                onPressed: () {
                  Navigator.of(context).pop();
                  _showFullJobListing(context);
                },
                backgroundColor: Colors.transparent,
                foregroundColor: Palette.primary,
                transparent: true,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  void _showFullJobListing(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => JobDetailPage(job: widget.job)),
    );
  }
}

class JobDetailPage extends ConsumerWidget {
  final JobListing job;

  const JobDetailPage({super.key, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final headerHeight = (size.height * 0.17).clamp(160.0, 200.0);

    // Check if user has applied for this job
    final hasAppliedAsync = ref.watch(hasAppliedProvider(job.id));

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Header section (matching account information page style)
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
                              'Job Details',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: size.width < 350 ? 26 : 30,
                                fontWeight: FontWeight.bold,
                                color: Palette.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Complete job listing information',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: size.width < 350 ? 14 : 16,
                                color: Palette.white.withValues(alpha: 0.9),
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
                  // Job title
                  Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Location and payment
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Palette.subtitle,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          job.location,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Palette.subtitle,
                          ),
                        ),
                      ),
                      Text(
                        job.payment,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Palette.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Tags
                  if (job.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          job.tags
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Palette.primary.withAlpha(30),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    tag,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Palette.primary,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Employer Profile Section
                  const Text(
                    'Posted by',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showEmployerProfileModal(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Palette.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Palette.primary.withAlpha(50),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Profile Picture
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Palette.primary.withAlpha(30),
                              border: Border.all(
                                color: Palette.primary,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Palette.primary,
                              size: 25,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Employer Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PosterNameWidget(
                                  posterUid: job.posterUid,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Verified Employer',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Palette.subtitle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Arrow icon
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Palette.subtitle,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description section
                  const Text(
                    'Job Description',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Palette.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      job.description,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Location Section
                  const Text(
                    'Job Location',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  StaticMapWidget(
                    locationData: job.locationData,
                    fallbackAddress: job.location,
                    height: 200,
                  ),
                  const SizedBox(height: 24),

                  // Posted date
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Posted',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(job.createdAt),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Palette.subtitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Apply button
                  Center(
                    child: hasAppliedAsync.when(
                      data:
                          (hasApplied) => CustomButton(
                            text:
                                hasApplied
                                    ? 'ALREADY APPLIED'
                                    : 'APPLY FOR THIS JOB',
                            onPressed:
                                hasApplied
                                    ? null
                                    : () {
                                      _showQuickApplicationModal(context, ref);
                                    },
                            backgroundColor:
                                hasApplied ? Colors.grey : Palette.primary,
                            foregroundColor: Colors.white,
                          ),
                      loading:
                          () => CustomButton(
                            text: 'APPLY FOR THIS JOB',
                            onPressed: () {
                              _showQuickApplicationModal(context, ref);
                            },
                            backgroundColor: Palette.primary,
                            foregroundColor: Colors.white,
                          ),
                      error:
                          (_, __) => CustomButton(
                            text: 'APPLY FOR THIS JOB',
                            onPressed: () {
                              _showQuickApplicationModal(context, ref);
                            },
                            backgroundColor: Palette.primary,
                            foregroundColor: Colors.white,
                          ),
                    ),
                  ),
                  // Add SafeArea bottom padding to prevent overlap with system navigation
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showQuickApplicationModal(BuildContext context, WidgetRef ref) {
    if (job != null) {
      // Defensive check for job ID
      if (job!.id.isEmpty) {
        CustomDialog.show(
          context: context,
          title: 'Error',
          message:
              'This job is not fully loaded yet. Please try again in a moment.',
          icon: Icons.error_outline,
          iconColor: Colors.red,
          buttonText: 'OK',
        );
        return;
      }
      // Reset the form state before showing the modal
      ref.read(jobApplicationFormViewModelProvider.notifier).reset();

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: QuickApplicationModal(job: job!),
            ),
      );
    }
  }

  void _showEmployerProfileModal(BuildContext context) async {
    try {
      // Show loading while fetching employer data
      await LoadingService.runWithLoading(context, () async {
        // Pre-load employer data before showing modal
        final authService = AuthService();
        await authService.getUserDocument(job.posterUid);
      });

      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder:
              (context) => EmployerProfileModal(employerUid: job.posterUid),
        );
      }
    } catch (e) {
      // Handle any errors during data loading
      if (context.mounted) {
        CustomDialog.show(
          context: context,
          title: 'Error',
          message: 'Failed to load employer profile',
          icon: Icons.error_outline,
          iconColor: Colors.red,
          buttonText: 'OK',
        );
      }
    }
  }
}
