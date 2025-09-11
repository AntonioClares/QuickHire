import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:quickhire/core/model/job_listings_model.dart';
import 'package:quickhire/features/home/employee/views/widgets/horizontal_job_card.dart';
import 'package:quickhire/features/home/employee/views/widgets/job_card.dart';
import 'package:quickhire/features/job_application/views/widgets/my_applications_section.dart';

class JobSections extends StatelessWidget {
  final List<JobListing> recommendedJobs;
  final List<JobListing> recentJobs;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  const JobSections({
    super.key,
    required this.recommendedJobs,
    required this.recentJobs,
    required this.isLoading,
    this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // My Applications Section (conditionally shown)
        const MyApplicationsSection(),

        // Recommendations Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: _buildSectionHeader(
            context,
            'Recommendations',
            recommendedJobs.length,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(height: 220, child: _buildRecommendationsSection()),
        const SizedBox(height: 24),

        // Recent Jobs Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: _buildSectionHeader(context, 'Recent Jobs', recentJobs.length),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildRecommendationsSection() {
    if (!isLoading && errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Error loading recommendations'),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (!isLoading && recommendedJobs.isEmpty) {
      return const Center(child: Text('No recommended jobs available'));
    }

    return Skeletonizer(
      enabled: isLoading,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 24.0),
        itemCount: recommendedJobs.length + 1,
        itemBuilder: (context, index) {
          if (index == recommendedJobs.length) {
            return const SizedBox(width: 24);
          }

          final job = recommendedJobs[index];
          return HorizontalJobCard(job);
        },
      ),
    );
  }
}

class RecentJobsSliver extends StatelessWidget {
  final List<JobListing> recentJobs;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  const RecentJobsSliver({
    super.key,
    required this.recentJobs,
    required this.isLoading,
    this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading && errorMessage != null) {
      return SliverToBoxAdapter(
        child: Center(
          child: Column(
            children: [
              const Text('Error loading recent jobs'),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (!isLoading && recentJobs.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: Text('No recent jobs available')),
      );
    }

    return SliverSkeletonizer(
      enabled: isLoading,
      child: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == recentJobs.length) {
            return const SizedBox(height: 24);
          }

          final job = recentJobs[index];
          return JobCard(
            title: job.title,
            posterUid: job.posterUid,
            location: job.location,
            salary: job.payment,
            tags: job.tags,
            jobListing: job, // Add this line
          );
        }, childCount: recentJobs.length + 1),
      ),
    );
  }
}
