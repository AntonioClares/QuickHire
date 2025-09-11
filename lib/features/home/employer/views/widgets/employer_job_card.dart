import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/model/job_listings_model.dart';
import 'package:quickhire/core/utils/time_ago_util.dart';
import 'package:quickhire/core/views/widgets/custom_button.dart';
import 'package:quickhire/features/job_application/viewmodels/job_application_viewmodel.dart';

class EmployerJobCard extends ConsumerWidget {
  final JobListing job;
  final VoidCallback? onEdit;
  final VoidCallback? onViewApplications;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onDelete;

  const EmployerJobCard({
    super.key,
    required this.job,
    this.onEdit,
    this.onViewApplications,
    this.onToggleStatus,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get application count for this job
    final applicationCountAsync = ref.watch(
      jobApplicationCountProvider(job.id),
    );

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
            // Header with status and menu
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Palette.subtitle,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              job.location,
                              style: TextStyle(
                                fontSize: 14,
                                color: Palette.subtitle,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildStatusChip(),
                    const SizedBox(height: 4),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Palette.subtitle),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                      color: Colors.white,
                      position: PopupMenuPosition.under,
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit?.call();
                            break;
                          case 'toggle':
                            onToggleStatus?.call();
                            break;
                          case 'delete':
                            onDelete?.call();
                            break;
                        }
                      },
                      itemBuilder:
                          (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      size: 20,
                                      color: Palette.primary,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Edit',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      job.isActive
                                          ? Icons.pause_circle_outline
                                          : Icons.play_circle_outline,
                                      size: 20,
                                      color:
                                          job.isActive
                                              ? Colors.orange
                                              : Colors.green,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      job.isActive ? 'Pause' : 'Activate',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Payment and date info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Palette.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    job.payment,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Palette.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Posted ${TimeAgoUtil.formatTimeAgo(job.createdAt)}',
                    style: TextStyle(fontSize: 12, color: Palette.subtitle),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description preview
            Text(
              job.description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // Tags
            if (job.tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children:
                    job.tags
                        .take(3)
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Applications and actions
            Row(
              children: [
                Expanded(
                  child: applicationCountAsync.when(
                    data:
                        (count) => RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            children: [
                              TextSpan(
                                text: '$count',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Palette.primary,
                                ),
                              ),
                              TextSpan(
                                text:
                                    count == 1
                                        ? ' Application'
                                        : ' Applications',
                              ),
                            ],
                          ),
                        ),
                    loading:
                        () => const Text(
                          'Loading...',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                    error:
                        (_, __) => const Text(
                          '0 Applications',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                CustomButton(
                  text: 'VIEW APPLICANTS',
                  onPressed: onViewApplications,
                  width: 182,
                  height: 42,
                  backgroundColor: Palette.primary,
                  foregroundColor: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            job.isActive
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        job.isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: job.isActive ? Colors.green.shade700 : Colors.grey.shade700,
        ),
      ),
    );
  }
}
