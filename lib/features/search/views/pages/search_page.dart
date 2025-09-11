import 'package:flutter/material.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/views/widgets/custom_loading_indicator.dart';
import 'package:quickhire/features/search/viewmodel/search_viewmodel.dart';
import 'package:quickhire/features/search/views/widgets/search_bar_widget.dart';
import 'package:quickhire/features/search/views/widgets/search_filters.dart';
import 'package:quickhire/features/search/views/widgets/search_results.dart';
import 'package:quickhire/features/search/views/widgets/search_suggestions.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final SearchViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _viewModel = SearchViewModel();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.initialize();

    _searchFocusNode.addListener(() {
      setState(() {
        _showSuggestions =
            _searchFocusNode.hasFocus && _searchController.text.isEmpty;
      });
    });

    // Auto-focus search bar when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  void _onSearchChanged(String query) {
    _viewModel.updateSearchQuery(query);
    setState(() {
      _showSuggestions = query.isEmpty && _searchFocusNode.hasFocus;
    });
  }

  void _onSearchSubmitted(String query) {
    if (query.isNotEmpty) {
      _viewModel.addToRecentSearches(query);
      _searchFocusNode.unfocus();
      setState(() {
        _showSuggestions = false;
      });
    }
  }

  void _onSuggestionSelected(String suggestion) {
    _searchController.text = suggestion;
    _viewModel.updateSearchQuery(suggestion);
    _viewModel.addToRecentSearches(suggestion);
    _searchFocusNode.unfocus();
    setState(() {
      _showSuggestions = false;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _viewModel.clearSearch();
    setState(() {
      _showSuggestions = true;
    });
  }

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchFilters(viewModel: _viewModel),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        backgroundColor: Palette.primary,
        elevation: 0,
        toolbarHeight: 80,
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Palette.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0xFF5E616F),
                      size: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SearchBarWidget(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    onSubmitted: _onSearchSubmitted,
                    onClear: _clearSearch,
                    hasActiveFilters: _viewModel.hasActiveFilters,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.tune, color: Colors.white),
                  onPressed: _showFiltersBottomSheet,
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_viewModel.isLoading) {
      return const Center(child: CustomLoadingIndicator());
    }

    if (_viewModel.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Palette.subtitle),
            const SizedBox(height: 16),
            Text(
              'Failed to load jobs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Palette.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _viewModel.errorMessage!,
              style: TextStyle(fontSize: 14, color: Palette.subtitle),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _viewModel.refreshJobs,
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_showSuggestions ||
        (!_viewModel.isSearchActive && _searchController.text.isEmpty)) {
      return SearchSuggestions(
        viewModel: _viewModel,
        searchQuery: _searchController.text,
        onSuggestionSelected: _onSuggestionSelected,
      );
    }

    if (_viewModel.isSearchActive) {
      return SearchResults(
        viewModel: _viewModel,
        searchQuery: _viewModel.searchQuery,
      );
    }

    return _buildEmptyState();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Palette.subtitle),
          const SizedBox(height: 16),
          Text(
            'Start searching for jobs',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Palette.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find your dream job by searching for\njob titles, companies, or locations',
            style: TextStyle(fontSize: 14, color: Palette.subtitle),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
