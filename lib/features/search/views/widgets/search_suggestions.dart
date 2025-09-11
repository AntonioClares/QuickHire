import 'package:flutter/material.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/features/search/viewmodel/search_viewmodel.dart';

class SearchSuggestions extends StatelessWidget {
  final SearchViewModel viewModel;
  final String searchQuery;
  final ValueChanged<String> onSuggestionSelected;

  const SearchSuggestions({
    super.key,
    required this.viewModel,
    required this.searchQuery,
    required this.onSuggestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final suggestions = viewModel.getSuggestions(searchQuery);
    final recentSearches = viewModel.recentSearches;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (searchQuery.isEmpty && recentSearches.isNotEmpty) ...[
            _buildSectionHeader('Recent Searches'),
            const SizedBox(height: 12),
            _buildRecentSearches(recentSearches),
            const SizedBox(height: 24),
          ],

          if (searchQuery.isNotEmpty && suggestions.isNotEmpty) ...[
            _buildSectionHeader('Suggestions'),
            const SizedBox(height: 12),
            _buildSuggestionsList(suggestions),
            const SizedBox(height: 24),
          ],

          if (searchQuery.isEmpty) ...[
            _buildSectionHeader('Popular Searches'),
            const SizedBox(height: 12),
            _buildPopularSearches(),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Palette.secondary,
      ),
    );
  }

  Widget _buildRecentSearches(List<String> searches) {
    return Column(
      children:
          searches
              .take(5)
              .map(
                (search) =>
                    _buildSuggestionItem(search, Icons.history, isRecent: true),
              )
              .toList(),
    );
  }

  Widget _buildSuggestionsList(List<String> suggestions) {
    return Column(
      children:
          suggestions
              .map(
                (suggestion) => _buildSuggestionItem(
                  suggestion,
                  _getSuggestionIcon(suggestion),
                ),
              )
              .toList(),
    );
  }

  Widget _buildPopularSearches() {
    final popularSearches = [
      'Cleaner',
      'Security Guard',
      'Construction Worker',
      'Factory Worker',
      'Kitchen Helper',
      'Delivery Driver',
      'Shop Assistant',
      'Warehouse Worker',
      'Plumber',
      'Electrician',
      'Mechanic',
      'General Worker',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          popularSearches.map((search) => _buildPopularChip(search)).toList(),
    );
  }

  Widget _buildSuggestionItem(
    String text,
    IconData icon, {
    bool isRecent = false,
  }) {
    return InkWell(
      onTap: () => onSuggestionSelected(text),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isRecent ? Palette.subtitle : Palette.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Palette.secondary,
                ),
              ),
            ),
            Icon(Icons.north_west, color: Palette.subtitle, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularChip(String text) {
    return InkWell(
      onTap: () => onSuggestionSelected(text),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Palette.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Palette.background, width: 1),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Palette.secondary,
          ),
        ),
      ),
    );
  }

  IconData _getSuggestionIcon(String suggestion) {
    final lowerSuggestion = suggestion.toLowerCase();

    // Location indicators
    if (lowerSuggestion.contains(',') ||
        lowerSuggestion.contains('remote') ||
        lowerSuggestion.contains('new york') ||
        lowerSuggestion.contains('san francisco') ||
        lowerSuggestion.contains('los angeles') ||
        lowerSuggestion.contains('chicago') ||
        lowerSuggestion.contains('seattle')) {
      return Icons.location_on_outlined;
    }

    // Job titles
    if (lowerSuggestion.contains('engineer') ||
        lowerSuggestion.contains('developer') ||
        lowerSuggestion.contains('manager') ||
        lowerSuggestion.contains('designer') ||
        lowerSuggestion.contains('analyst') ||
        lowerSuggestion.contains('specialist')) {
      return Icons.work_outline;
    }

    // Company names (typically proper nouns or contain certain keywords)
    if (lowerSuggestion.contains('inc') ||
        lowerSuggestion.contains('corp') ||
        lowerSuggestion.contains('llc') ||
        lowerSuggestion.contains('company')) {
      return Icons.business_outlined;
    }

    // Default to search
    return Icons.search;
  }
}
