import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quickhire/features/job_application/models/job_application_model.dart';
import 'package:quickhire/core/services/cache_service.dart';

class JobApplicationRepository {
  static final JobApplicationRepository _instance =
      JobApplicationRepository._internal();
  factory JobApplicationRepository() => _instance;
  JobApplicationRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CacheService _cacheService = CacheService();

  static const String _applicationsCollection = 'job_applications';
  static const String _applicationsSubcollection = 'applications';

  // Cache for application counts and statuses
  final Map<String, int> _applicationCountCache = {};
  final Map<String, DateTime> _countCacheTimestamps = {};
  final Map<String, bool> _hasAppliedCache = {};
  final Map<String, DateTime> _hasAppliedTimestamps = {};

  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Check if cache is still valid
  bool _isCacheValid(String key, Map<String, DateTime> timestamps) {
    final timestamp = timestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  /// Cache application count
  void _cacheApplicationCount(String key, int count) {
    _applicationCountCache[key] = count;
    _countCacheTimestamps[key] = DateTime.now();
    _cacheService.cacheApplicationCount(key, count);
  }

  /// Get cached application count
  int? _getCachedApplicationCount(String key) {
    if (_isCacheValid(key, _countCacheTimestamps)) {
      return _applicationCountCache[key];
    }

    final cachedCount = _cacheService.getCachedApplicationCount(key);
    if (cachedCount != null) {
      _applicationCountCache[key] = cachedCount;
      _countCacheTimestamps[key] = DateTime.now();
      return cachedCount;
    }

    return null;
  }

  /// Cache hasApplied status
  void _cacheHasApplied(String jobId, String userId, bool hasApplied) {
    final key = '${jobId}_$userId';
    _hasAppliedCache[key] = hasApplied;
    _hasAppliedTimestamps[key] = DateTime.now();
  }

  /// Get cached hasApplied status
  bool? _getCachedHasApplied(String jobId, String userId) {
    final key = '${jobId}_$userId';
    if (_isCacheValid(key, _hasAppliedTimestamps)) {
      return _hasAppliedCache[key];
    }
    return null;
  }

  /// Invalidate application-related caches
  void _invalidateApplicationCaches(String jobId, String userId) {
    final hasAppliedKey = '${jobId}_$userId';
    _hasAppliedCache.remove(hasAppliedKey);
    _hasAppliedTimestamps.remove(hasAppliedKey);

    // Also invalidate count caches that might be affected
    _applicationCountCache.remove('job_$jobId');
    _countCacheTimestamps.remove('job_$jobId');
    _applicationCountCache.remove('user_$userId');
    _countCacheTimestamps.remove('user_$userId');
    _applicationCountCache.remove('pending_$userId');
    _countCacheTimestamps.remove('pending_$userId');

    // Clear all hasApplied cache entries for this user to force refresh
    final keysToRemove = <String>[];
    for (final key in _hasAppliedCache.keys) {
      if (key.endsWith('_$userId')) {
        keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      _hasAppliedCache.remove(key);
      _hasAppliedTimestamps.remove(key);
    }
  }

  /// Clear all in-memory caches (for sign out)
  void clearAllCaches() {
    _applicationCountCache.clear();
    _countCacheTimestamps.clear();
    _hasAppliedCache.clear();
    _hasAppliedTimestamps.clear();
  }

  // Submit a new job application
  Future<String> submitApplication(JobApplication application) async {
    try {
      final docRef = await _firestore
          .collection(_applicationsCollection)
          .doc(application.jobId)
          .collection(_applicationsSubcollection)
          .add(application.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to submit application: $e');
    }
  } // Submit application with atomic check and cache invalidation

  Future<String> submitApplicationWithCheck({
    required String jobId,
    required String jobTitle,
    required String employerUid,
    required String message,
    required String applicantUid,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    if (applicantUid != currentUser.uid) {
      throw Exception('Invalid user');
    }

    // Validate required parameters to prevent empty document path errors
    if (jobId.trim().isEmpty) {
      throw Exception('Invalid job ID: Job ID cannot be empty');
    }

    if (jobTitle.trim().isEmpty) {
      throw Exception('Invalid job title: Job title cannot be empty');
    }

    if (employerUid.trim().isEmpty) {
      throw Exception('Invalid employer ID: Employer ID cannot be empty');
    }

    if (message.trim().isEmpty) {
      throw Exception('Application message cannot be empty');
    }

    try {
      // Use a transaction to ensure atomicity and prevent race conditions
      return await _firestore.runTransaction<String>((transaction) async {
        // Check if user has already applied within the transaction
        final existingApplicationQuery =
            await _firestore
                .collection(_applicationsCollection)
                .doc(jobId)
                .collection(_applicationsSubcollection)
                .where('applicantUid', isEqualTo: currentUser.uid)
                .where('status', whereNotIn: ['withdrawn'])
                .limit(1)
                .get();

        if (existingApplicationQuery.docs.isNotEmpty) {
          throw Exception('You have already applied for this job');
        }

        // Create new application document reference
        final applicationRef =
            _firestore
                .collection(_applicationsCollection)
                .doc(jobId)
                .collection(_applicationsSubcollection)
                .doc();

        final application = JobApplication(
          id: applicationRef.id,
          jobId: jobId,
          jobTitle: jobTitle,
          applicantUid: applicantUid,
          employerUid: employerUid,
          message: message,
          status: ApplicationStatus.pending,
          appliedAt: DateTime.now(),
        );

        // Submit the application within the transaction
        transaction.set(applicationRef, application.toFirestore());

        print('Application submitted successfully: ${applicationRef.id}');

        // Invalidate caches after successful submission
        _invalidateApplicationCaches(jobId, applicantUid);

        return applicationRef.id;
      });
    } catch (e) {
      print('Error submitting application: $e');
      // Also invalidate caches on error to force refresh on next check
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        _invalidateApplicationCaches(jobId, currentUser.uid);
      }
      rethrow;
    }
  }

  // Check if user has already applied for a job with caching
  Future<bool> hasAppliedForJob(String jobId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    // Check cache first
    final cachedResult = _getCachedHasApplied(jobId, currentUser.uid);
    if (cachedResult != null) {
      return cachedResult;
    }

    try {
      final querySnapshot =
          await _firestore
              .collection(_applicationsCollection)
              .doc(jobId)
              .collection(_applicationsSubcollection)
              .where('applicantUid', isEqualTo: currentUser.uid)
              .where('status', whereNotIn: ['withdrawn'])
              .limit(1)
              .get();

      final hasApplied = querySnapshot.docs.isNotEmpty;

      // Cache the result
      _cacheHasApplied(jobId, currentUser.uid, hasApplied);

      return hasApplied;
    } catch (e) {
      print('Error checking application status: $e');
      return false;
    }
  }

  // Get applications by user (for job seekers)
  Stream<List<JobApplication>> getUserApplications() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collectionGroup(_applicationsSubcollection)
        .where('applicantUid', isEqualTo: currentUser.uid)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => JobApplication.fromFirestore(doc))
              .toList();
        })
        .handleError((error) {
          print('Error getting user applications: $error');
          return <JobApplication>[];
        });
  }

  // Get applications for jobs posted by employer
  Stream<List<JobApplication>> getEmployerApplications() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collectionGroup(_applicationsSubcollection)
        .where('employerUid', isEqualTo: currentUser.uid)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => JobApplication.fromFirestore(doc))
              .toList();
        })
        .handleError((error) {
          print('Error getting employer applications: $error');
          return <JobApplication>[];
        });
  }

  // Get applications for a specific job
  Stream<List<JobApplication>> getJobApplications(String jobId) {
    return _firestore
        .collection(_applicationsCollection)
        .doc(jobId)
        .collection(_applicationsSubcollection)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => JobApplication.fromFirestore(doc))
              .toList();
        })
        .handleError((error) {
          print('Error getting job applications: $error');
          return <JobApplication>[];
        });
  }

  // Update application status (for employers) with cache invalidation
  Future<void> updateApplicationStatus({
    required String jobId,
    required String applicationId,
    required ApplicationStatus status,
    String? employerMessage,
  }) async {
    try {
      final updateData = {
        'status': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (employerMessage != null) {
        updateData['employerMessage'] = employerMessage;
      }

      await _firestore
          .collection(_applicationsCollection)
          .doc(jobId)
          .collection(_applicationsSubcollection)
          .doc(applicationId)
          .update(updateData);

      // Invalidate relevant caches
      _applicationCountCache.clear();
      _countCacheTimestamps.clear();
    } catch (e) {
      throw Exception('Failed to update application status: $e');
    }
  }

  // Withdraw application (for job seekers) with cache invalidation
  Future<void> withdrawApplication({
    required String jobId,
    required String applicationId,
  }) async {
    try {
      await _firestore
          .collection(_applicationsCollection)
          .doc(jobId)
          .collection(_applicationsSubcollection)
          .doc(applicationId)
          .update({
            'status': ApplicationStatus.withdrawn.name,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });

      // Invalidate relevant caches
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        _invalidateApplicationCaches(jobId, currentUser.uid);
      }
    } catch (e) {
      throw Exception('Failed to withdraw application: $e');
    }
  }

  // Get application by ID (note: with new structure, this requires knowing jobId)
  Future<JobApplication?> getApplicationById({
    required String jobId,
    required String applicationId,
  }) async {
    try {
      final doc =
          await _firestore
              .collection(_applicationsCollection)
              .doc(jobId)
              .collection(_applicationsSubcollection)
              .doc(applicationId)
              .get();

      if (doc.exists) {
        return JobApplication.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting application: $e');
      return null;
    }
  }

  // Get application count for a specific job with caching
  Future<int> getJobApplicationCount(String jobId) async {
    final cacheKey = 'job_$jobId';

    // Check cache first
    final cachedCount = _getCachedApplicationCount(cacheKey);
    if (cachedCount != null) {
      return cachedCount;
    }

    try {
      final querySnapshot =
          await _firestore
              .collection(_applicationsCollection)
              .doc(jobId)
              .collection(_applicationsSubcollection)
              .where('status', whereNotIn: ['withdrawn'])
              .count()
              .get();

      final count = querySnapshot.count ?? 0;

      // Cache the result
      _cacheApplicationCount(cacheKey, count);

      return count;
    } catch (e) {
      print('Error getting application count: $e');
      return 0;
    }
  }

  // Get pending applications count for employer with caching
  Future<int> getPendingApplicationsCount() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return 0;

    final cacheKey = 'pending_${currentUser.uid}';

    // Check cache first
    final cachedCount = _getCachedApplicationCount(cacheKey);
    if (cachedCount != null) {
      return cachedCount;
    }

    try {
      final querySnapshot =
          await _firestore
              .collectionGroup(_applicationsSubcollection)
              .where('employerUid', isEqualTo: currentUser.uid)
              .where('status', isEqualTo: ApplicationStatus.pending.name)
              .count()
              .get();

      final count = querySnapshot.count ?? 0;

      // Cache the result
      _cacheApplicationCount(cacheKey, count);

      return count;
    } catch (e) {
      print('Error getting pending applications count: $e');
      return 0;
    }
  }
}
