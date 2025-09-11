import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:quickhire/core/model/job_listings_model.dart';
import 'package:quickhire/core/services/auth_service.dart';
import 'package:quickhire/core/services/job_service.dart';
import 'dart:async';

class EmployerHomeViewModel extends ChangeNotifier {
  final JobService _jobService = JobService();
  final AuthService _authService = AuthService();
  final Connectivity _connectivity = Connectivity();

  // Data state
  List<JobListing> _myJobListings = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  String _userName = "Username";

  // Connectivity state
  bool _hasInternetConnection = true;
  bool _isInitialized = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<List<JobListing>>? _jobListingsSubscription;

  // Getters
  List<JobListing> get myJobListings => _myJobListings;
  List<JobListing> get activeJobListings =>
      _myJobListings.where((job) => job.isActive).toList();
  List<JobListing> get inactiveJobListings =>
      _myJobListings.where((job) => !job.isActive).toList();
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
      await refreshJobs();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _jobListingsSubscription?.cancel();
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
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) async {
      if (results.contains(ConnectivityResult.none)) {
        _hasInternetConnection = false;
        notifyListeners();
      } else {
        final hasConnection = await _checkInternetConnection();
        final wasConnected = _hasInternetConnection;
        _hasInternetConnection = hasConnection;

        if (!wasConnected && hasConnection && _isInitialized) {
          // Reconnected - reload data
          await loadJobs();
        }
        notifyListeners();
      }
    });
  }

  Future<bool> _checkInternetConnection() async {
    try {
      // First check connectivity status
      final connectivityResults = await _connectivity.checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none)) {
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

    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      _errorMessage = 'User not authenticated';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      // Cancel any existing subscription
      _jobListingsSubscription?.cancel();

      // Set up real-time subscription to employer's job listings
      _jobListingsSubscription = _jobService
          .getEmployerJobListingsStream(currentUser.uid)
          .listen(
            (jobs) {
              _myJobListings = jobs;
              _errorMessage = null;
              _isLoading = false;
              notifyListeners();
            },
            onError: (error) {
              _errorMessage = error.toString();
              _isLoading = false;
              notifyListeners();
            },
          );
    } catch (e) {
      _errorMessage = e.toString();
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

      // Clear caches to force fresh data
      _jobService.invalidateJobCaches();
      _authService.clearUserNameCache();

      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        // Force refresh by clearing cache and fetching fresh data
        _jobService.clearEmployerJobCache(currentUser.uid);
        final jobs = await _jobService.getEmployerJobListings(
          currentUser.uid,
          forceRefresh: true,
        );
        _myJobListings = jobs;
        _errorMessage = null;

        if (_userName == "Username") {
          await loadUserName();
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // Update job listing
  Future<void> updateJobListing({
    required String jobId,
    String? title,
    String? description,
    String? payment,
    List<String>? tags,
    bool? isActive,
  }) async {
    try {
      await _jobService.updateJobListing(
        jobId: jobId,
        title: title,
        description: description,
        payment: payment,
        tags: tags,
        isActive: isActive,
      );
      // The stream subscription will automatically update the UI
    } catch (e) {
      throw Exception('Failed to update job listing: $e');
    }
  }

  // Close job listing
  Future<void> closeJobListing(String jobId) async {
    try {
      await _jobService.closeJobListing(jobId);
      // The stream subscription will automatically update the UI
    } catch (e) {
      throw Exception('Failed to close job listing: $e');
    }
  }

  // Delete job listing
  Future<void> deleteJobListing(String jobId) async {
    try {
      await _jobService.deleteJobListing(jobId);
      // The stream subscription will automatically update the UI
    } catch (e) {
      throw Exception('Failed to delete job listing: $e');
    }
  }

  List<JobListing> createFakeJobListings(int count) {
    return List.generate(
      count,
      (index) => JobListing(
        id: 'fake-$index',
        title: 'My Job Posting ${index + 1}',
        description: 'This is a job I posted to find skilled workers.',
        location: 'Kuala Lumpur, MY',
        payment: 'RM ${(index + 1) * 50}/Hour',
        tags: ['Active', 'Full-time', index % 2 == 0 ? 'Urgent' : 'Flexible'],
        posterUid: 'my-uid',
        isActive: index % 3 != 0, // Mix of active and inactive
        createdAt: DateTime.now().subtract(Duration(days: index)),
        updatedAt: DateTime.now().subtract(Duration(days: index)),
        type: 'Contract',
      ),
    );
  }
}
