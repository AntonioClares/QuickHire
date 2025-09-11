import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/utils/time_ago_util.dart';
import 'package:quickhire/features/job_application/models/job_application_model.dart';
import 'package:quickhire/features/job_application/services/job_application_service.dart';
import 'package:quickhire/features/job_application/viewmodels/job_application_viewmodel.dart';
import 'package:quickhire/core/navigation/views/widgets/confirmation_dialog.dart';
import 'package:quickhire/core/navigation/views/widgets/custom_dialog.dart';
import 'package:quickhire/core/services/loading_service.dart';

class ApplicationCard extends ConsumerWidget {
  final JobApplication application;
  final VoidCallback? onWithdraw;

  const ApplicationCard({
    super.key,
    required this.application,
    this.onWithdraw,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Fix overflow issue
          children: [
            // Job Title and Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    application.jobTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Palette.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(),
              ],
            ),
            const SizedBox(height: 12),

            // Application Message Preview
            Flexible(
              // Use Flexible instead of constraining height
              child: Text(
                application.message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Palette.subtitle,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),

            // Application Time
            Text(
              'Applied ${TimeAgoUtil.formatTimeAgo(application.appliedAt)}',
              style: const TextStyle(
                fontSize: 12,
                color: Palette.imagePlaceholder,
              ),
            ),

            if (application.updatedAt != null &&
                application.updatedAt != application.appliedAt) ...[
              const SizedBox(height: 4),
              Text(
                'Updated ${TimeAgoUtil.formatTimeAgo(application.updatedAt!)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Palette.imagePlaceholder,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action Button
            Row(children: [Expanded(child: _buildActionButton(context))]),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    Color textColor;

    switch (application.status) {
      case ApplicationStatus.pending:
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange.shade700;
        break;
      case ApplicationStatus.accepted:
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green.shade700;
        break;
      case ApplicationStatus.rejected:
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red.shade700;
        break;
      case ApplicationStatus.withdrawn:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        application.statusDisplayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (application.status == ApplicationStatus.pending) {
      return OutlinedButton(
        onPressed: () => _showWithdrawDialog(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red.shade600,
          side: BorderSide(color: Colors.red.shade600),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Withdraw',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      );
    } else if (application.status == ApplicationStatus.accepted) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'Congratulations! 🎉',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.green.shade700,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showWithdrawDialog(BuildContext context) {
    ConfirmationDialog.show(
      context: context,
      title: 'Withdraw Application',
      message:
          'Are you sure you want to withdraw your application for "${application.jobTitle}"?',
      confirmText: 'Withdraw',
      cancelText: 'Cancel',
      icon: Icons.warning_outlined,
      iconColor: Colors.orange,
      confirmButtonColor: Colors.red,
      onConfirm: () => _withdrawApplication(context),
    );
  }

  void _withdrawApplication(BuildContext context) async {
    try {
      await LoadingService.runWithLoading(context, () async {
        await JobApplicationService().withdrawApplication(
          jobId: application.jobId,
          applicationId: application.id,
        );

        // Invalidate providers to refresh data immediately
        if (context.mounted) {
          final container = ProviderScope.containerOf(context);
          container.invalidate(hasAppliedProvider(application.jobId));
          container.invalidate(userApplicationsProvider);
          container.invalidate(jobApplicationsProvider(application.jobId));
          container.invalidate(jobApplicationCountProvider(application.jobId));
        }
      });

      if (context.mounted) {
        CustomDialog.show(
          context: context,
          title: 'Application Withdrawn',
          message:
              'Your application has been withdrawn successfully. You can apply again if you change your mind.',
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
          buttonText: 'OK',
        );
      }

      onWithdraw?.call();
    } catch (e) {
      if (context.mounted) {
        CustomDialog.show(
          context: context,
          title: 'Error',
          message: 'Failed to withdraw application. Please try again.',
          icon: Icons.error_outline,
          iconColor: Colors.red,
          buttonText: 'OK',
        );
      }
    }
  }
}
