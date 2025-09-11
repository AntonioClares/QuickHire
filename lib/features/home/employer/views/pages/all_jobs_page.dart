import 'package:flutter/material.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/features/home/employer/views/widgets/employer_job_card.dart';

class AllJobsPage extends StatelessWidget {
  final String title;
  final List<dynamic> jobs;
  final Function(dynamic) onEdit;
  final Function(dynamic) onViewApplications;
  final Function(dynamic) onToggleStatus;
  final Function(dynamic) onDelete;

  const AllJobsPage({
    super.key,
    required this.title,
    required this.jobs,
    required this.onEdit,
    required this.onViewApplications,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final headerHeight = (size.height * 0.17).clamp(160.0, 200.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Header section with consistent design
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

                      // Title
                      Positioned.fill(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${jobs.length} job${jobs.length != 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content section
          SliverToBoxAdapter(
            child:
                jobs.isEmpty
                    ? _buildEmptyState()
                    : Padding(
                      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
                      child: Column(
                        children: [
                          ...jobs.map(
                            (job) => Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: EmployerJobCard(
                                job: job,
                                onEdit: () => onEdit(job),
                                onViewApplications:
                                    () => onViewApplications(job),
                                onToggleStatus: () => onToggleStatus(job),
                                onDelete: () => onDelete(job),
                              ),
                            ),
                          ),
                          // Add bottom padding to avoid navigation bar overlap
                          SizedBox(
                            height: MediaQuery.of(context).padding.bottom + 16,
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Icon(Icons.work_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No ${title.toLowerCase()} found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title.contains('Active')
                  ? 'You don\'t have any active job listings at the moment.'
                  : 'You don\'t have any inactive job listings at the moment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
