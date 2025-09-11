import 'package:flutter/material.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/model/job_listings_model.dart';
import 'package:quickhire/features/home/employee/views/widgets/job_card.dart';

class AllRecentJobsPage extends StatelessWidget {
  final List<JobListing> jobs;

  const AllRecentJobsPage({super.key, required this.jobs});

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
                              const Text(
                                'Recent Jobs',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${jobs.length} recent job${jobs.length != 1 ? 's' : ''}',
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
                              child: JobCard(
                                title: job.title,
                                posterUid: job.posterUid,
                                location: job.location,
                                salary: job.payment,
                                tags: job.tags,
                                jobListing: job,
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
            Icon(Icons.access_time, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No recent jobs found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'New jobs are added regularly. Check back soon for fresh opportunities!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
