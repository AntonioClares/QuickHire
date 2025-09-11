import 'package:flutter/material.dart';
import 'package:quickhire/core/model/job_listings_model.dart';
import 'package:quickhire/features/home/employee/views/widgets/job_card.dart';

class HorizontalJobCard extends StatelessWidget {
  final JobListing job;
  const HorizontalJobCard(this.job, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 350),
      margin: const EdgeInsets.only(right: 16),
      child: JobCard(
        title: job.title,
        posterUid: job.posterUid,
        location: job.location,
        salary: job.payment,
        tags: job.tags,
        jobListing: job,
        overrideMargin: const EdgeInsets.only(bottom: 0, left: 0, right: 0),
      ),
    );
  }
}
