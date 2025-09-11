import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/job_application_viewmodel.dart';
import 'application_card.dart';

class MyApplicationsSection extends ConsumerWidget {
  const MyApplicationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(userApplicationsProvider);

    return applicationsAsync.when(
      data: (applications) {
        // Hide section if no applications
        if (applications.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildSectionHeader(context, applications.length),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200, // Fixed height for horizontal scroll
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: applications.length,
                itemBuilder: (context, index) {
                  final application = applications[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == applications.length - 1 ? 0 : 12,
                    ),
                    child: SizedBox(
                      width: 300, // Fixed width for each card
                      child: ApplicationCard(application: application),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
      loading: () => _buildLoadingSkeleton(context),
      error: (error, stack) {
        // Hide section on error to avoid breaking the UI
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, int count) {
    return Text(
      'My Applications',
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    // Show loading skeleton for a short time
    return FutureBuilder(
      future: Future.delayed(const Duration(seconds: 2)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // Hide after loading timeout
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                height: 24,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: 3, // Show 3 skeleton cards
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(right: index == 2 ? 0 : 12),
                    child: Container(
                      width: 300,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 20,
                              width: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 16,
                              width: 150,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 32,
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}
