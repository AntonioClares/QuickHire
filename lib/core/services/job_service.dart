import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quickhire/core/model/job_listings_model.dart';
import 'package:quickhire/core/model/location_data.dart';
import 'package:quickhire/core/services/cache_service.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheService _cacheService = CacheService();
  final String _collection = 'job_listings';

  // Cache for frequently accessed data
  final Map<String, List<JobListing>> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(
    minutes: 5,
  ); // Shorter cache for better refresh

  /// Check if cache is still valid
  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  /// Cache job listings in memory
  void _cacheJobListings(String key, List<JobListing> jobs) {
    _memoryCache[key] = jobs;
    _cacheTimestamps[key] = DateTime.now();

    // Also cache in persistent storage
    final jobMaps = jobs.map((job) => job.toFirestore()).toList();
    _cacheService.cacheJobListings(key, jobMaps);
  }

  /// Get cached job listings
  List<JobListing>? _getCachedJobListings(String key) {
    // Check memory cache first
    if (_isCacheValid(key)) {
      return _memoryCache[key];
    }

    // Check persistent cache
    final cachedMaps = _cacheService.getCachedJobListings(key);
    if (cachedMaps != null) {
      try {
        final jobs =
            cachedMaps.map((map) {
              // Create a document snapshot mock for fromFirestore
              return JobListing(
                id: map['id'] ?? '',
                posterUid: map['poster_uid'] ?? '',
                createdAt: (map['createdAt'] as Timestamp).toDate(),
                description: map['description'] ?? '',
                isActive: map['isActive'] ?? true,
                location: map['location'] ?? '',
                locationData:
                    map['location_data'] != null
                        ? LocationData.fromJson(map['location_data'])
                        : null,
                payment: map['payment'] ?? '',
                tags: List<String>.from(map['tags'] ?? []),
                title: map['title'] ?? '',
                type: map['type'] ?? '',
                updatedAt: (map['updatedAt'] as Timestamp).toDate(),
              );
            }).toList();

        // Restore to memory cache
        _memoryCache[key] = jobs;
        _cacheTimestamps[key] = DateTime.now();
        return jobs;
      } catch (e) {
        print('Error parsing cached job listings: $e');
      }
    }

    return null;
  }

  // Create a new job listing
  Future<String> createJobListing({
    required String posterUid,
    required String title,
    required String description,
    required String location,
    LocationData? locationData,
    required String payment,
    required List<String> tags,
    String type = 'Freelance',
  }) async {
    final now = DateTime.now();

    final jobListing = JobListing(
      id: '', // Will be set by Firestore
      posterUid: posterUid,
      createdAt: now,
      description: description,
      isActive: true,
      location: location,
      locationData: locationData,
      payment: payment,
      tags: tags,
      title: title,
      type: type,
      updatedAt: now,
    );

    final docRef = await _firestore
        .collection(_collection)
        .add(jobListing.toFirestore());

    // Invalidate caches after creating new job
    invalidateJobCaches();
    clearEmployerJobCache(posterUid);

    return docRef.id;
  }

  // Get all active job listings ordered by creation date (one-time fetch)
  Future<List<JobListing>> getActiveJobListings() async {
    const cacheKey = 'active_jobs';

    // Try to get from cache first
    final cachedJobs = _getCachedJobListings(cacheKey);
    if (cachedJobs != null) {
      return cachedJobs;
    }

    final snapshot =
        await _firestore
            .collection(_collection)
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();

    final jobs =
        snapshot.docs.map((doc) => JobListing.fromFirestore(doc)).toList();

    // Cache the results
    _cacheJobListings(cacheKey, jobs);

    return jobs;
  }

  // Get recent job listings (limit to recent ones)
  Future<List<JobListing>> getRecentJobListings({
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'recent_jobs_$limit';

    // Skip cache if force refresh is requested
    if (!forceRefresh) {
      final cachedJobs = _getCachedJobListings(cacheKey);
      if (cachedJobs != null) {
        return cachedJobs;
      }
    }

    try {
      final snapshot =
          await _firestore
              .collection(_collection)
              .where('isActive', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      final jobs =
          snapshot.docs.map((doc) => JobListing.fromFirestore(doc)).toList();

      // Cache the results
      _cacheJobListings(cacheKey, jobs);

      return jobs;
    } catch (e) {
      // If network fails and we have no cached data, rethrow
      print('Error fetching recent job listings: $e');
      rethrow;
    }
  }

  // Get recommended job listings with basic recommendation algorithm
  Future<List<JobListing>> getRecommendedJobListings({
    int limit = 5,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'recommended_jobs_$limit';

    // Skip cache if force refresh is requested
    if (!forceRefresh) {
      final cachedJobs = _getCachedJobListings(cacheKey);
      if (cachedJobs != null) {
        return cachedJobs;
      }
    }

    try {
      // Get all active jobs first
      final snapshot =
          await _firestore
              .collection(_collection)
              .where('isActive', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .limit(50) // Get more to filter from
              .get();

      List<JobListing> allJobs =
          snapshot.docs.map((doc) => JobListing.fromFirestore(doc)).toList();

      if (allJobs.isEmpty) {
        return [];
      }

      // Basic recommendation algorithm
      final recommendedJobs = _calculateJobRecommendations(allJobs, limit);

      // Cache the results
      _cacheJobListings(cacheKey, recommendedJobs);

      return recommendedJobs;
    } catch (e) {
      // If network fails and we have no cached data, fall back to recent jobs
      print('Error fetching recommended job listings: $e');
      return await getRecentJobListings(
        limit: limit,
        forceRefresh: forceRefresh,
      );
    }
  }

  // Simple recommendation algorithm based on job attributes
  List<JobListing> _calculateJobRecommendations(
    List<JobListing> jobs,
    int limit,
  ) {
    // Score jobs based on various factors
    final scoredJobs =
        jobs.map((job) {
          double score = 0.0;

          // Factor 1: Recency (newer jobs get higher score)
          final daysSinceCreated =
              DateTime.now().difference(job.createdAt).inDays;
          if (daysSinceCreated <= 3) {
            score += 5.0; // Very recent
          } else if (daysSinceCreated <= 7) {
            score += 3.0; // Recent
          } else if (daysSinceCreated <= 14) {
            score += 1.0; // Somewhat recent
          }

          // Factor 2: Job category popularity (boost common categories)
          final popularCategories = [
            'Construction',
            'Cleaning',
            'Electrical Work',
            'Plumbing',
            'Moving & Delivery',
            'Food Service',
          ];
          for (final tag in job.tags) {
            if (popularCategories.contains(tag)) {
              score += 2.0;
              break;
            }
          }

          // Factor 3: Payment type preference (hourly jobs are common for gig work)
          if (job.payment.toLowerCase().contains('hour') ||
              job.payment.toLowerCase().contains('/hr')) {
            score += 1.5;
          }

          // Factor 4: Location preference (Malaysian locations get a boost)
          final malaysianIndicators = [
            'kuala lumpur',
            'kl',
            'selangor',
            'johor',
            'penang',
            'malaysia',
            'my',
          ];
          final locationLower = job.displayLocation.toLowerCase();
          for (final indicator in malaysianIndicators) {
            if (locationLower.contains(indicator)) {
              score += 2.0;
              break;
            }
          }

          // Factor 5: Title keywords that indicate good opportunities
          final goodKeywords = [
            'part-time',
            'flexible',
            'immediate',
            'urgent',
            'experienced',
            'skilled',
            'professional',
            'freelance',
            'contract',
          ];
          final titleLower = job.title.toLowerCase();
          for (final keyword in goodKeywords) {
            if (titleLower.contains(keyword)) {
              score += 1.0;
            }
          }

          // Factor 6: Avoid overly complex job descriptions (simpler = better for quick jobs)
          if (job.description.length < 500) {
            score += 1.0;
          }

          // Factor 7: Random factor to ensure variety
          score += (job.id.hashCode % 100) / 100.0;

          return MapEntry(job, score);
        }).toList();

    // Sort by score (descending) and take the top ones
    scoredJobs.sort((a, b) => b.value.compareTo(a.value));

    return scoredJobs.take(limit).map((entry) => entry.key).toList();
  }

  // Get job listings posted by a specific employer with caching
  Future<List<JobListing>> getEmployerJobListings(
    String employerUid, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'employer_jobs_$employerUid';

    // Skip cache if force refresh is requested
    if (!forceRefresh) {
      final cachedJobs = _getCachedJobListings(cacheKey);
      if (cachedJobs != null) {
        return cachedJobs;
      }
    }

    try {
      final snapshot =
          await _firestore
              .collection(_collection)
              .where('poster_uid', isEqualTo: employerUid)
              .orderBy('createdAt', descending: true)
              .get();

      final jobs =
          snapshot.docs.map((doc) => JobListing.fromFirestore(doc)).toList();

      // Cache the results with shorter duration for employer-specific data
      _cacheJobListings(cacheKey, jobs);

      return jobs;
    } catch (e) {
      // If network fails and we have no cached data, rethrow
      print('Error fetching employer job listings: $e');
      rethrow;
    }
  }

  // Get active job listings posted by a specific employer
  Stream<List<JobListing>> getEmployerJobListingsStream(String employerUid) {
    return _firestore
        .collection(_collection)
        .where('poster_uid', isEqualTo: employerUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final jobs =
              snapshot.docs
                  .map((doc) => JobListing.fromFirestore(doc))
                  .toList();

          // Update cache when stream data changes
          _cacheJobListings('employer_jobs_$employerUid', jobs);

          return jobs;
        });
  }

  /// Clear all job-related caches
  void clearJobCaches() {
    _memoryCache.clear();
    _cacheTimestamps.clear();
  }

  /// Clear cache for specific employer
  void clearEmployerJobCache(String employerUid) {
    final key = 'employer_jobs_$employerUid';
    _memoryCache.remove(key);
    _cacheTimestamps.remove(key);
  }

  /// Invalidate all job listing caches (call after creating/updating/deleting jobs)
  void invalidateJobCaches() {
    clearJobCaches();
    // Also clear persistent cache - use the proper cache keys with prefixes
    _cacheService.clearCache('job_listings_active_jobs');
    _cacheService.clearCache('job_listings_recent_jobs_10');
    _cacheService.clearCache('job_listings_recent_jobs_5');
    _cacheService.clearCache('job_listings_recommended_jobs_5');

    // Clear all employer-specific caches by clearing any cached job listings
    _cacheService.clearAllJobListingCaches();
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
    final updateData = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    if (title != null) updateData['title'] = title;
    if (description != null) updateData['description'] = description;
    if (payment != null) updateData['payment'] = payment;
    if (tags != null) updateData['tags'] = tags;
    if (isActive != null) updateData['isActive'] = isActive;

    await _firestore.collection(_collection).doc(jobId).update(updateData);

    // Invalidate caches after updating job
    invalidateJobCaches();
  }

  // Close job listing (mark as inactive)
  Future<void> closeJobListing(String jobId) async {
    await _firestore.collection(_collection).doc(jobId).update({
      'isActive': false,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    // Invalidate caches after closing job
    invalidateJobCaches();
  }

  // Delete job listing
  Future<void> deleteJobListing(String jobId) async {
    await _firestore.collection(_collection).doc(jobId).delete();

    // Invalidate caches after deleting job
    invalidateJobCaches();
  }

  // Get job listing by ID
  Future<JobListing?> getJobById(String jobId) async {
    final doc = await _firestore.collection(_collection).doc(jobId).get();
    if (doc.exists) {
      return JobListing.fromFirestore(doc);
    }
    return null;
  }
}
