import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:quickhire/core/model/job_listings_model.dart';
import 'package:quickhire/core/services/auth_service.dart';
import 'package:quickhire/core/services/job_service.dart';
import 'dart:async';

class HomeViewModel extends ChangeNotifier {
  final JobService _jobService = JobService();
  final AuthService _authService = AuthService();
  final Connectivity _connectivity = Connectivity();

  // Data state
  List<JobListing> _recommendedJobs = [];
  List<JobListing> _recentJobs = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  String _userName = "Username";

  // Connectivity state
  bool _hasInternetConnection = true;
  bool _isInitialized = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Getters
  List<JobListing> get recommendedJobs => _recommendedJobs;
  List<JobListing> get recentJobs => _recentJobs;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  String get userName => _userName;
  bool get hasInternetConnection => _hasInternetConnection;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    await _initializeConnectivity();
    _setupConnectivityListener();
    _isInitialized = true;
    notifyListeners();

    // Trigger automatic refresh when app launches to ensure fresh data
    if (_hasInternetConnection) {
      // Only refresh jobs if user is available
      if (_authService.currentUser != null) {
        await refreshJobs();
      }
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeConnectivity() async {
    try {
      final hasConnection = await _checkInternetConnection();
      _hasInternetConnection = hasConnection;

      if (hasConnection) {
        await Future.wait([loadJobs(), loadUserName()]);
      } else {
        // Important: Set loading to false when no internet during initialization
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _hasInternetConnection = false;
      _isLoading = false; // Also handle the error case
      notifyListeners();
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) async {
      debugPrint('Connectivity changed: $results');

      if (results.contains(ConnectivityResult.none)) {
        _hasInternetConnection = false;
        notifyListeners();
      } else {
        final hasConnection = await _checkInternetConnection();
        debugPrint('Internet connection verified: $hasConnection');

        final wasConnected = _hasInternetConnection;
        _hasInternetConnection = hasConnection;
        notifyListeners();

        // If we just regained connection and have no data, reload
        if (!wasConnected &&
            hasConnection &&
            _isInitialized &&
            (_recommendedJobs.isEmpty || _recentJobs.isEmpty)) {
          await Future.wait([loadJobs(), loadUserName()]);
        }
      }
    });
  }

  Future<bool> _checkInternetConnection() async {
    try {
      // First check if we have any network connectivity
      final results = await _connectivity.checkConnectivity();
      if (results.contains(ConnectivityResult.none)) {
        return false;
      }

      // Then verify actual internet access with a real network request
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadUserName() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final userDoc = await _authService.getUserDocument(currentUser.uid);
        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data()!;
          _userName = userData['name'] ?? 'Failed to get name';
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading user name: $e');
    }
  }

  Future<void> loadJobs() async {
    if (!_hasInternetConnection) return;
    // Only load jobs if user is available
    if (_authService.currentUser == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      // Use parallel requests with optimized caching
      final results = await Future.wait([
        _jobService.getRecommendedJobListings(limit: 5),
        _jobService.getRecentJobListings(limit: 10),
      ]);

      _recommendedJobs = results[0];
      _recentJobs = results[1];
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshJobs() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    notifyListeners();

    try {
      final hasConnection = await _checkInternetConnection();
      _hasInternetConnection = hasConnection;

      if (!hasConnection) {
        return;
      }

      // Clear caches for fresh data on manual refresh
      _jobService.invalidateJobCaches();
      _authService.clearUserNameCache();

      // Force refresh to bypass cache
      final results = await Future.wait([
        _jobService.getRecommendedJobListings(limit: 5, forceRefresh: true),
        _jobService.getRecentJobListings(limit: 10, forceRefresh: true),
      ]);

      _recommendedJobs = results[0];
      _recentJobs = results[1];
      _errorMessage = null;

      if (_userName == "Username") {
        await loadUserName();
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  List<JobListing> createFakeJobListings(int count) {
    return List.generate(
      count,
      (index) => JobListing(
        id: 'fake-$index',
        title: 'Software Engineer Position',
        description:
            'This is a great opportunity to work with cutting-edge technology.',
        location: 'San Francisco, CA',
        payment: '\$80/Hour',
        tags: ['Full-time', 'Remote', 'Senior'],
        posterUid: 'Tech Company Inc.',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        type: 'Full-time',
      ),
    );
  }
}
