import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/model/job_listings_model.dart';
import 'package:quickhire/core/utils/time_ago_util.dart';
import 'package:quickhire/core/views/widgets/custom_button.dart';
import 'package:quickhire/core/views/widgets/custom_loading_indicator.dart';
import 'package:quickhire/core/views/widgets/poster_name_widget.dart';
import 'package:quickhire/core/navigation/views/widgets/custom_dialog.dart';
import 'package:quickhire/core/navigation/views/widgets/confirmation_dialog.dart';
import 'package:quickhire/core/services/loading_service.dart';
import 'package:quickhire/core/services/auth_service.dart';
import 'package:quickhire/features/job_application/models/job_application_model.dart';
import 'package:quickhire/features/job_application/services/job_application_service.dart';
import 'package:quickhire/features/job_application/viewmodels/job_application_viewmodel.dart';
import 'package:quickhire/features/messaging/services/messaging_service.dart';
import 'package:quickhire/features/messaging/view/pages/chat_page.dart';

class JobApplicantsPage extends ConsumerWidget {
  final JobListing job;

  const JobApplicantsPage({super.key, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(jobApplicationsProvider(job.id));

    return Scaffold(
      backgroundColor: Palette.background,
      body: RefreshIndicator(
        color: Palette.primary,
        onRefresh: () async {
          ref.invalidate(jobApplicationsProvider(job.id));
        },
        child: CustomScrollView(
          slivers: [
            // Header section matching account information page
            SliverAppBar(
              expandedHeight: 120,
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
                            onTap: () => context.pop(),
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
                        // Title
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 20,
                          child: Center(
                            child: Text(
                              'Applicants - ${job.title}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Content
            applicationsAsync.when(
              data: (applications) {
                if (applications.isEmpty) {
                  return SliverToBoxAdapter(child: _buildEmptyState(context));
                }

                // Filter out withdrawn applications for display
                final activeApplications =
                    applications
                        .where(
                          (app) => app.status != ApplicationStatus.withdrawn,
                        )
                        .toList();

                if (activeApplications.isEmpty) {
                  return SliverToBoxAdapter(child: _buildEmptyState(context));
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final application = activeApplications[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: index == activeApplications.length - 1 ? 16 : 0,
                        top: index == 0 ? 16 : 16,
                      ),
                      child: ApplicantCard(
                        application: application,
                        onAccept:
                            () => _handleAcceptApplication(
                              context,
                              ref,
                              application,
                            ),
                        onReject:
                            () => _handleRejectApplication(
                              context,
                              ref,
                              application,
                            ),
                        onMessage:
                            () => _handleMessageApplicant(context, application),
                      ),
                    );
                  }, childCount: activeApplications.length),
                );
              },
              loading:
                  () => const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(64.0),
                        child: CustomLoadingIndicator(),
                      ),
                    ),
                  ),
              error:
                  (error, stackTrace) => SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Palette.subtitle,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error Loading Applicants',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Palette.subtitle,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error.toString(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Palette.subtitle,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            CustomButton(
                              text: 'Retry',
                              onPressed: () {
                                ref.invalidate(jobApplicationsProvider(job.id));
                              },
                              backgroundColor: Palette.primary,
                              foregroundColor: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Palette.subtitle),
          const SizedBox(height: 16),
          Text(
            'No Applicants Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Palette.subtitle,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When people apply for this job, they\'ll appear here.',
            style: TextStyle(fontSize: 14, color: Palette.subtitle),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _handleAcceptApplication(
    BuildContext context,
    WidgetRef ref,
    JobApplication application,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Accept Application',
      message: 'Are you sure you want to accept this application?',
      confirmText: 'Accept',
      cancelText: 'Cancel',
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
      confirmButtonColor: Colors.green,
    );

    if (confirmed == true && context.mounted) {
      try {
        await LoadingService.runWithLoading(context, () async {
          await JobApplicationService().updateApplicationStatus(
            jobId: application.jobId,
            applicationId: application.id,
            status: ApplicationStatus.accepted,
          );

          // Refresh the applications list
          ref.invalidate(jobApplicationsProvider(job.id));
        });

        if (context.mounted) {
          CustomDialog.show(
            context: context,
            title: 'Application Accepted',
            message:
                'The application has been accepted successfully. The applicant will be notified.',
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
            buttonText: 'OK',
          );
        }
      } catch (e) {
        if (context.mounted) {
          CustomDialog.show(
            context: context,
            title: 'Error',
            message: 'Failed to accept the application. Please try again.',
            icon: Icons.error_outline,
            iconColor: Colors.red,
            buttonText: 'OK',
          );
        }
      }
    }
  }

  Future<void> _handleRejectApplication(
    BuildContext context,
    WidgetRef ref,
    JobApplication application,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Reject Application',
      message: 'Are you sure you want to reject this application?',
      confirmText: 'Reject',
      cancelText: 'Cancel',
      icon: Icons.cancel_outlined,
      iconColor: Colors.red,
      confirmButtonColor: Colors.red,
    );

    if (confirmed == true && context.mounted) {
      try {
        await LoadingService.runWithLoading(context, () async {
          await JobApplicationService().updateApplicationStatus(
            jobId: application.jobId,
            applicationId: application.id,
            status: ApplicationStatus.rejected,
          );

          // Refresh the applications list
          ref.invalidate(jobApplicationsProvider(job.id));
        });

        if (context.mounted) {
          CustomDialog.show(
            context: context,
            title: 'Application Rejected',
            message:
                'The application has been rejected. The applicant will be notified.',
            icon: Icons.check_circle_outline,
            iconColor: Colors.orange,
            buttonText: 'OK',
          );
        }
      } catch (e) {
        if (context.mounted) {
          CustomDialog.show(
            context: context,
            title: 'Error',
            message: 'Failed to reject the application. Please try again.',
            icon: Icons.error_outline,
            iconColor: Colors.red,
            buttonText: 'OK',
          );
        }
      }
    }
  }

  Future<void> _handleMessageApplicant(
    BuildContext context,
    JobApplication application,
  ) async {
    try {
      await LoadingService.runWithLoading(context, () async {
        final messagingService = MessagingService();
        final authService = AuthService();

        // Get applicant's name
        final applicantName = await authService.getUserNameByUid(
          application.applicantUid,
        );

        final conversationId = await messagingService.createOrGetConversation(
          application.applicantUid,
        );

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ChatPage(
                    conversationId: conversationId,
                    otherUserName: applicantName,
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
          message: 'Failed to start conversation. Please try again.',
          icon: Icons.error_outline,
          iconColor: Colors.red,
          buttonText: 'OK',
        );
      }
    }
  }
}

class ApplicantCard extends StatelessWidget {
  final JobApplication application;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onMessage;

  const ApplicantCard({
    super.key,
    required this.application,
    this.onAccept,
    this.onReject,
    this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with applicant info and status
            Row(
              children: [
                // Profile picture placeholder
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Palette.primary.withOpacity(0.1),
                    border: Border.all(color: Palette.primary, width: 2),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Palette.primary,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PosterNameWidget(
                        posterUid: application.applicantUid,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text(
                            'Verified User',
                            style: TextStyle(
                              fontSize: 14,
                              color: Palette.subtitle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            const SizedBox(height: 16),

            // Applied date
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Palette.subtitle),
                const SizedBox(width: 4),
                Text(
                  'Applied ${TimeAgoUtil.formatTimeAgo(application.appliedAt)}',
                  style: TextStyle(fontSize: 14, color: Palette.subtitle),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Application message
            if (application.message.isNotEmpty) ...[
              const Text(
                'Message:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Palette.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  application.message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action buttons
            if (application.status == ApplicationStatus.pending) ...[
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'REJECT',
                      onPressed: onReject,
                      backgroundColor: Colors.red.withOpacity(0.1),
                      foregroundColor: Colors.red,
                      height: 40,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'ACCEPT',
                      onPressed: onAccept,
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      height: 40,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Message button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'MESSAGE APPLICANT',
                onPressed: onMessage,
                backgroundColor: Palette.secondary,
                foregroundColor: Colors.white,
                height: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (application.status) {
      case ApplicationStatus.pending:
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange.shade700;
        text = 'Pending';
        break;
      case ApplicationStatus.accepted:
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green.shade700;
        text = 'Accepted';
        break;
      case ApplicationStatus.rejected:
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red.shade700;
        text = 'Rejected';
        break;
      case ApplicationStatus.withdrawn:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey.shade700;
        text = 'Withdrawn';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
