import 'package:flutter/foundation.dart';
import 'package:quickhire/core/model/job_listings_model.dart';
import 'package:quickhire/core/services/job_service.dart';
import 'package:quickhire/core/services/auth_service.dart';

enum PayType { all, hourly, basePayment }

class SearchViewModel extends ChangeNotifier {
  final JobService _jobService = JobService();
  final AuthService _authService = AuthService();

  // Search state
  List<JobListing> _searchResults = [];
  List<JobListing> _allJobs = [];
  bool _isLoading = false;
  bool _isSearchActive = false;
  String _searchQuery = '';
  String? _errorMessage;

  // Cache for poster names to avoid repeated lookups
  final Map<String, String> _posterNamesCache = {};

  // Filter state
  List<String> _selectedTags = [];
  PayType _selectedPayType = PayType.all;
  double _minSalary = 0.0;
  double _maxSalary = 10000.0;
  String _selectedLocation = '';

  // Available job tags for filtering (from job posting categories)
  final List<String> _availableJobTags = [
    'Construction',
    'Cleaning',
    'Electrical Work',
    'Plumbing',
    'Painting',
    'Moving & Delivery',
    'Gardening & Landscaping',
    'Handyman Services',
    'Security',
    'Food Service',
    'Other',
    'Fixed Rate',
    'Hourly',
  ];

  // Search suggestions
  List<String> _recentSearches = [];
  List<String> _jobTitleSuggestions = [];
  List<String> _locationSuggestions = [];

  // Getters
  List<JobListing> get searchResults => _searchResults;
  List<JobListing> get allJobs => _allJobs;
  bool get isLoading => _isLoading;
  bool get isSearchActive => _isSearchActive;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;

  List<String> get selectedTags => _selectedTags;
  PayType get selectedPayType => _selectedPayType;
  double get minSalary => _minSalary;
  double get maxSalary => _maxSalary;
  String get selectedLocation => _selectedLocation;
  List<String> get availableJobTags => _availableJobTags;

  List<String> get recentSearches => _recentSearches;
  List<String> get jobTitleSuggestions => _jobTitleSuggestions;
  List<String> get locationSuggestions => _locationSuggestions;

  // Check if any filters are active
  bool get hasActiveFilters =>
      _selectedTags.isNotEmpty ||
      _selectedPayType != PayType.all ||
      _minSalary > 0.0 ||
      _maxSalary < 10000.0 ||
      _selectedLocation.isNotEmpty;

  Future<void> initialize() async {
    await _loadAllJobs();
    _generateSuggestions();
  }

  Future<void> _loadAllJobs() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Load more jobs for comprehensive search
      final results = await Future.wait([
        _jobService.getRecommendedJobListings(limit: 50),
        _jobService.getRecentJobListings(limit: 50),
      ]);

      // Combine and deduplicate jobs
      final allJobsSet = <String, JobListing>{};
      for (final jobList in results) {
        for (final job in jobList) {
          allJobsSet[job.id] = job;
        }
      }

      _allJobs = allJobsSet.values.toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error loading jobs for search: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _generateSuggestions() {
    // Generate job title suggestions
    final titleSet = <String>{};
    final locationSet = <String>{};

    for (final job in _allJobs) {
      // Extract job titles
      titleSet.add(job.title);

      // Extract locations
      if (job.displayLocation.isNotEmpty) {
        locationSet.add(job.displayLocation);

        // Also add city names (assuming format "City, State")
        final parts = job.displayLocation.split(',');
        if (parts.isNotEmpty) {
          titleSet.add(parts.first.trim());
        }
      }

      // Extract keywords from title and description
      final titleWords = job.title.toLowerCase().split(' ');
      final descWords = job.description.toLowerCase().split(' ');

      for (final word in [...titleWords, ...descWords]) {
        if (word.length > 3 && !_isCommonWord(word)) {
          titleSet.add(word.toLowerCase());
        }
      }
    }

    _jobTitleSuggestions = titleSet.toList()..sort();
    _locationSuggestions = locationSet.toList()..sort();
  }

  bool _isCommonWord(String word) {
    const commonWords = {
      'the',
      'and',
      'for',
      'with',
      'this',
      'that',
      'will',
      'have',
      'from',
      'they',
      'know',
      'want',
      'been',
      'good',
      'much',
      'some',
      'time',
      'very',
      'when',
      'come',
      'here',
      'just',
      'like',
      'long',
      'make',
      'many',
      'over',
    };
    return commonWords.contains(word.toLowerCase());
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    _isSearchActive = query.isNotEmpty;

    if (query.isNotEmpty) {
      _performSearch().then((_) => notifyListeners());
    } else {
      _searchResults = [];
      notifyListeners();
    }
  }

  Future<void> _performSearch() async {
    List<JobListing> results = List.from(_allJobs);

    // Text search with improved accuracy
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      results =
          results.where((job) {
            // Check if query matches job title (highest priority)
            final titleMatch = job.title.toLowerCase().contains(query);

            // Check if query matches job type/category (high priority)
            final typeMatch = job.type.toLowerCase().contains(query);

            // Check if query matches job tags (high priority)
            final tagMatch = job.tags.any(
              (tag) => tag.toLowerCase().contains(query),
            );

            // Check if query matches location (medium priority)
            final locationMatch = job.displayLocation.toLowerCase().contains(
              query,
            );

            // Check if query matches description (lower priority)
            final descMatch = job.description.toLowerCase().contains(query);

            return titleMatch ||
                typeMatch ||
                tagMatch ||
                locationMatch ||
                descMatch;
          }).toList();

      // Also search for jobs by poster name
      final posterNameResults = await _searchJobsByPosterName(query);

      // Combine results and remove duplicates
      for (final job in posterNameResults) {
        if (!results.any((existingJob) => existingJob.id == job.id)) {
          results.add(job);
        }
      }
    }

    // Apply filters - this will work even if there's no search query
    results = _applyFilters(results);

    // Ensure search is active if we have filters or search query
    if (_searchQuery.isNotEmpty || hasActiveFilters) {
      _isSearchActive = true;
    }

    // Sort by relevance with improved scoring
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      results.sort((a, b) {
        int aScore = 0;
        int bScore = 0;

        // Title match gets highest score
        if (a.title.toLowerCase().contains(query)) aScore += 10;
        if (b.title.toLowerCase().contains(query)) bScore += 10;

        // Exact title match gets even higher score
        if (a.title.toLowerCase() == query) aScore += 20;
        if (b.title.toLowerCase() == query) bScore += 20;

        // Type/category match gets high score
        if (a.type.toLowerCase().contains(query)) aScore += 8;
        if (b.type.toLowerCase().contains(query)) bScore += 8;

        // Tag match gets high score
        if (a.tags.any((tag) => tag.toLowerCase().contains(query))) aScore += 7;
        if (b.tags.any((tag) => tag.toLowerCase().contains(query))) bScore += 7;

        // Location match gets medium score
        if (a.displayLocation.toLowerCase().contains(query)) aScore += 5;
        if (b.displayLocation.toLowerCase().contains(query)) bScore += 5;

        // Description match gets lower score
        if (a.description.toLowerCase().contains(query)) aScore += 2;
        if (b.description.toLowerCase().contains(query)) bScore += 2;

        // If scores are equal, sort by creation date (newest first)
        if (aScore == bScore) {
          return b.createdAt.compareTo(a.createdAt);
        }

        return bScore.compareTo(aScore);
      });
    } else {
      // If no search query, just sort by creation date
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    _searchResults = results;
  }

  /// Search for jobs by poster name using cached names for performance
  Future<List<JobListing>> _searchJobsByPosterName(String query) async {
    final results = <JobListing>[];
    final queryLower = query.toLowerCase();

    // Check each job's poster name
    for (final job in _allJobs) {
      try {
        // Check if we have cached the poster name
        String posterName;
        if (_posterNamesCache.containsKey(job.posterUid)) {
          posterName = _posterNamesCache[job.posterUid]!;
        } else {
          // Fetch poster name and cache it
          posterName = await _authService.getUserNameByUid(job.posterUid);
          _posterNamesCache[job.posterUid] = posterName;
        }

        // Check if poster name matches the query
        if (posterName.toLowerCase().contains(queryLower)) {
          results.add(job);
        }
      } catch (e) {
        // If there's an error fetching the poster name, continue with other jobs
        debugPrint('Error fetching poster name for job ${job.id}: $e');
      }
    }

    return results;
  }

  List<JobListing> _applyFilters(List<JobListing> jobs) {
    List<JobListing> filtered = jobs;

    // Job tags filter - ensure ALL selected tags are present OR any selected tag matches
    if (_selectedTags.isNotEmpty) {
      filtered =
          filtered.where((job) {
            // Check if job has any of the selected tags
            return _selectedTags.any(
              (selectedTag) => job.tags.any(
                (jobTag) => jobTag.toLowerCase() == selectedTag.toLowerCase(),
              ),
            );
          }).toList();
    }

    // Location filter
    if (_selectedLocation.isNotEmpty) {
      filtered =
          filtered
              .where(
                (job) => job.displayLocation.toLowerCase().contains(
                  _selectedLocation.toLowerCase(),
                ),
              )
              .toList();
    }

    // Salary range filter
    if (_selectedPayType != PayType.all ||
        _minSalary > 0.0 ||
        _maxSalary < 10000.0) {
      filtered = filtered.where((job) => _jobMatchesSalaryFilter(job)).toList();
    }

    return filtered;
  }

  bool _jobMatchesSalaryFilter(JobListing job) {
    // Extract salary number and type from payment string
    final payment = job.payment.toLowerCase();
    final salaryMatch = RegExp(r'\d+').allMatches(payment);

    if (salaryMatch.isEmpty)
      return true; // If no salary info, show in all ranges

    final salaryStr = salaryMatch.first.group(0);
    if (salaryStr == null) return true;

    double salary = double.tryParse(salaryStr) ?? 0;

    // Check pay type filter
    if (_selectedPayType == PayType.hourly &&
        !(payment.contains('hour') ||
            payment.contains('/hr') ||
            payment.contains('per hour'))) {
      return false;
    }

    if (_selectedPayType == PayType.basePayment &&
        (payment.contains('hour') ||
            payment.contains('/hr') ||
            payment.contains('per hour'))) {
      return false;
    }

    // Check salary range
    return salary >= _minSalary && salary <= _maxSalary;
  }

  void setTagsFilter(List<String> tags) {
    _selectedTags = tags;
    // Always trigger search when filters change, regardless of search state
    _performSearch().then((_) => notifyListeners());
  }

  void setPayTypeFilter(PayType payType) {
    _selectedPayType = payType;
    // Always trigger search when filters change, regardless of search state
    _performSearch().then((_) => notifyListeners());
  }

  void setSalaryRangeFilter(double minSalary, double maxSalary) {
    _minSalary = minSalary;
    _maxSalary = maxSalary;
    // Always trigger search when filters change, regardless of search state
    _performSearch().then((_) => notifyListeners());
  }

  void setLocationFilter(String location) {
    _selectedLocation = location;
    // Always trigger search when filters change, regardless of search state
    _performSearch().then((_) => notifyListeners());
  }

  void clearFilters() {
    _selectedTags.clear();
    _selectedPayType = PayType.all;
    _minSalary = 0.0;
    _maxSalary = 10000.0;
    _selectedLocation = '';

    // If we have no search query after clearing filters, clear the search
    if (_searchQuery.isEmpty) {
      _isSearchActive = false;
      _searchResults = [];
      notifyListeners();
    } else {
      // Otherwise, re-run search with just the query
      _performSearch().then((_) => notifyListeners());
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _isSearchActive = false;
    _searchResults = [];
    notifyListeners();
  }

  void addToRecentSearches(String query) {
    if (query.isEmpty) return;

    _recentSearches.remove(query); // Remove if already exists
    _recentSearches.insert(0, query); // Add to beginning

    // Keep only last 10 searches
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.take(10).toList();
    }

    notifyListeners();
  }

  List<String> getSuggestions(String query) {
    if (query.isEmpty) return _recentSearches;

    final suggestions = <String>{};
    final queryLower = query.toLowerCase();

    // Add matching job titles
    for (final title in _jobTitleSuggestions) {
      if (title.toLowerCase().contains(queryLower)) {
        suggestions.add(title);
      }
    }

    // Add matching locations
    for (final location in _locationSuggestions) {
      if (location.toLowerCase().contains(queryLower)) {
        suggestions.add(location);
      }
    }

    return suggestions.take(8).toList();
  }

  Future<void> refreshJobs() async {
    await _loadAllJobs();
    if (_isSearchActive) {
      await _performSearch();
      notifyListeners();
    }
  }
}
