import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/features/search/viewmodel/search_viewmodel.dart';
import 'package:quickhire/features/home/employee/views/widgets/job_card.dart';

class SearchResults extends StatelessWidget {
  final SearchViewModel viewModel;
  final String searchQuery;

  const SearchResults({
    super.key,
    required this.viewModel,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final results = viewModel.searchResults;

    if (results.isEmpty) {
      return _buildNoResults();
    }

    return Column(
      children: [
        _buildResultsHeader(results.length),
        Expanded(
          child: Skeletonizer(
            enabled: false,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final job = results[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: JobCard(
                    title: job.title,
                    posterUid: job.posterUid,
                    location: job.displayLocation,
                    salary: job.payment,
                    tags: job.tags,
                    jobListing: job,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsHeader(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Palette.white,
        border: Border(bottom: BorderSide(color: Palette.background, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Palette.secondary,
              ),
              children: [
                TextSpan(text: '$count result${count != 1 ? 's' : ''} '),
                TextSpan(
                  text: 'for "$searchQuery"',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Palette.primary,
                  ),
                ),
              ],
            ),
          ),
          if (viewModel.hasActiveFilters) ...[
            const SizedBox(height: 8),
            _buildActiveFilters(),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    final filters = <Widget>[];

    if (viewModel.selectedTags.isNotEmpty) {
      for (final tag in viewModel.selectedTags) {
        filters.add(
          _buildFilterChip(tag, () {
            final newTags = List<String>.from(viewModel.selectedTags)
              ..remove(tag);
            viewModel.setTagsFilter(newTags);
          }),
        );
      }
    }

    if (viewModel.selectedPayType != PayType.all) {
      filters.add(
        _buildFilterChip(
          _getPayTypeDisplayName(viewModel.selectedPayType),
          () => viewModel.setPayTypeFilter(PayType.all),
        ),
      );
    }

    if (viewModel.minSalary > 0.0 || viewModel.maxSalary < 10000.0) {
      final salaryText =
          viewModel.selectedPayType == PayType.hourly
              ? 'RM${viewModel.minSalary.toInt()}-${viewModel.maxSalary.toInt()}/hr'
              : 'RM${viewModel.minSalary.toInt()}-${viewModel.maxSalary.toInt()}';
      filters.add(
        _buildFilterChip(
          salaryText,
          () => viewModel.setSalaryRangeFilter(0.0, 10000.0),
        ),
      );
    }

    if (viewModel.selectedLocation.isNotEmpty) {
      filters.add(
        _buildFilterChip(
          viewModel.selectedLocation,
          () => viewModel.setLocationFilter(''),
        ),
      );
    }

    if (filters.isNotEmpty) {
      filters.add(_buildClearAllButton());
    }

    return Wrap(spacing: 8, runSpacing: 4, children: filters);
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Palette.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.primary, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Palette.primary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: Palette.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildClearAllButton() {
    return GestureDetector(
      onTap: viewModel.clearFilters,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Palette.subtitle.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Clear all',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Palette.subtitle,
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Palette.subtitle),
            const SizedBox(height: 16),
            Text(
              'No jobs found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Palette.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters\nto find what you\'re looking for',
              style: TextStyle(fontSize: 14, color: Palette.subtitle),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (viewModel.hasActiveFilters)
              ElevatedButton(
                onPressed: viewModel.clearFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Clear Filters'),
              ),
          ],
        ),
      ),
    );
  }

  String _getPayTypeDisplayName(PayType type) {
    switch (type) {
      case PayType.hourly:
        return 'Hourly Pay';
      case PayType.basePayment:
        return 'Base Payment';
      case PayType.all:
        return 'All Pay Types';
    }
  }
}
