import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/views/widgets/custom_button.dart';
import 'package:quickhire/core/views/widgets/poster_name_widget.dart';
import 'package:quickhire/core/navigation/views/widgets/custom_dialog.dart';
import 'package:quickhire/features/profile/views/widgets/employer_profile_modal.dart';
import 'package:quickhire/features/job/views/widgets/quick_application_modal.dart';
import 'package:quickhire/core/model/job_listings_model.dart';
import 'package:quickhire/core/services/loading_service.dart';
import 'package:quickhire/core/services/auth_service.dart';
import 'package:quickhire/core/utils/time_ago_util.dart';
import 'package:quickhire/features/job_application/viewmodels/job_application_viewmodel.dart';

class JobCard extends ConsumerWidget {
  final String title;
  final String? company; // Made optional - will use posterUid if not provided
  final String? posterUid; // Added posterUid parameter
  final String location;
  final String salary;
  final String? imageUrl;
  final List<String> tags;
  final EdgeInsetsGeometry? overrideMargin;
  final JobListing?
  jobListing; // Added jobListing parameter for modal functionality

  const JobCard({
    super.key,
    required this.title,
    this.company, // Made optional
    this.posterUid, // Added posterUid parameter
    required this.location,
    required this.salary,
    this.imageUrl,
    this.tags = const ["Senior", "Fulltime", "Remote"],
    this.overrideMargin,
    this.jobListing, // Added jobListing parameter
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSkeletonEnabled = Skeletonizer.of(context).enabled;

    // Check if user has applied for this job
    final hasAppliedAsync =
        jobListing != null && !isSkeletonEnabled
            ? ref.watch(hasAppliedProvider(jobListing!.id))
            : const AsyncValue.data(false);

    return GestureDetector(
      onTap: () {
        if (!isSkeletonEnabled && jobListing != null) {
          _showJobDetailPage(context);
        }
      },
      child: Container(
        margin:
            overrideMargin ??
            const EdgeInsets.only(
              bottom: 16,
              left: 8,
              right: 8,
            ), // Use override margin if provided, otherwise use default

        decoration: BoxDecoration(
          color: Palette.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Palette.imagePlaceholder.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Replace the image widget when skeleton is enabled
                  Skeleton.replace(
                    width: 50,
                    height: 50,
                    replacement: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Palette.imagePlaceholder,
                      ),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        if (!isSkeletonEnabled && posterUid != null) {
                          _showEmployerProfileModal(context);
                        }
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Palette.imagePlaceholder,
                        ),
                        child:
                            imageUrl != null && !isSkeletonEnabled
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(25),
                                  child: Image.network(
                                    imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          Icons.person_outline,
                                          color: Palette.white,
                                          size: 20,
                                        ),
                                  ),
                                )
                                : Icon(
                                  Icons.person_outline,
                                  color: Palette.white,
                                  size: 20,
                                ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child:
                                  posterUid != null && company == null
                                      ? GestureDetector(
                                        onTap: () {
                                          if (!isSkeletonEnabled &&
                                              posterUid != null) {
                                            _showEmployerProfileModal(context);
                                          }
                                        },
                                        child: PosterNameWidget(
                                          posterUid: posterUid!,
                                          isLoading: isSkeletonEnabled,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                      : Text(
                                        company ?? 'Unknown Company',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                            ),
                            Skeleton.ignore(
                              child:
                                  jobListing != null
                                      ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Palette.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          TimeAgoUtil.formatTimeAgo(
                                            jobListing!.createdAt,
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Palette.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      )
                                      : Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Palette.subtitle.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '2h ago',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Palette.subtitle,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          location,
                          style: TextStyle(
                            fontSize: 14,
                            color: Palette.subtitle,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Job title and salary above apply button
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: Palette.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (tags.isNotEmpty)
                    Text(
                      tags.join(' • '),
                      style: TextStyle(fontSize: 14, color: Palette.subtitle),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Skeleton.replace(
                    width: 135,
                    height: 50,
                    replacement: Container(
                      width: 135,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Palette.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: hasAppliedAsync.when(
                      data:
                          (hasApplied) => CustomButton(
                            text: hasApplied ? "APPLIED" : "APPLY NOW",
                            onPressed:
                                isSkeletonEnabled || hasApplied
                                    ? null
                                    : () {
                                      if (jobListing != null) {
                                        _showQuickApplicationModal(
                                          context,
                                          ref,
                                        );
                                      }
                                    },
                            width: 135,
                            height: 50,
                            backgroundColor:
                                hasApplied ? Palette.subtitle : Palette.primary,
                          ),
                      loading:
                          () => CustomButton(
                            text: "APPLY NOW",
                            onPressed:
                                isSkeletonEnabled
                                    ? null
                                    : () {
                                      if (jobListing != null) {
                                        _showQuickApplicationModal(
                                          context,
                                          ref,
                                        );
                                      }
                                    },
                            width: 135,
                            height: 50,
                          ),
                      error:
                          (_, __) => CustomButton(
                            text: "APPLY NOW",
                            onPressed:
                                isSkeletonEnabled
                                    ? null
                                    : () {
                                      if (jobListing != null) {
                                        _showQuickApplicationModal(
                                          context,
                                          ref,
                                        );
                                      }
                                    },
                            width: 135,
                            height: 50,
                          ),
                    ),
                  ),
                  Text(
                    salary,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Palette.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJobDetailPage(BuildContext context) {
    if (jobListing != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JobDetailPage(job: jobListing!),
        ),
      );
    }
  }

  void _showQuickApplicationModal(BuildContext context, WidgetRef ref) {
    if (jobListing != null) {
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
              child: QuickApplicationModal(job: jobListing!),
            ),
      );
    }
  }

  void _showEmployerProfileModal(BuildContext context) async {
    if (posterUid != null) {
      try {
        // Show loading while fetching employer data
        await LoadingService.runWithLoading(context, () async {
          // Pre-load employer data before showing modal
          final authService = AuthService();
          await authService.getUserDocument(posterUid!);
        });

        if (context.mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => EmployerProfileModal(employerUid: posterUid!),
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
}
