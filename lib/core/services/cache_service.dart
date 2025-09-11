import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Central caching service to reduce Firebase reads
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Cache durations for different data types
  static const Duration userProfileCacheDuration = Duration(hours: 6);
  static const Duration jobListingCacheDuration = Duration(
    minutes: 5,
  ); // Shorter for better refresh
  static const Duration applicationCountCacheDuration = Duration(minutes: 15);
  static const Duration notificationCountCacheDuration = Duration(minutes: 5);

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Check if cached data is still valid
  bool _isCacheValid(String key, Duration maxAge) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;

    return DateTime.now().difference(timestamp) < maxAge;
  }

  /// Cache user profile data
  Future<void> cacheUserProfile(
    String uid,
    Map<String, dynamic> userData,
  ) async {
    await initialize();
    final key = 'user_profile_$uid';

    // Store in memory cache (original data with Timestamps)
    _memoryCache[key] = userData;
    _cacheTimestamps[key] = DateTime.now();

    // Prepare data for persistent cache (convert Timestamps to strings)
    final processedData = _prepareDataForCache(userData);

    // Store in persistent cache
    await _prefs!.setString(key, jsonEncode(processedData));
    await _prefs!.setString(
      '${key}_timestamp',
      DateTime.now().toIso8601String(),
    );
  }

  /// Get cached user profile
  Map<String, dynamic>? getCachedUserProfile(String uid) {
    final key = 'user_profile_$uid';

    // Check memory cache first
    if (_isCacheValid(key, userProfileCacheDuration)) {
      return _memoryCache[key] as Map<String, dynamic>?;
    }

    // Check persistent cache
    final cachedData = _prefs?.getString(key);
    final timestampStr = _prefs?.getString('${key}_timestamp');

    if (cachedData != null && timestampStr != null) {
      final timestamp = DateTime.parse(timestampStr);
      if (DateTime.now().difference(timestamp) < userProfileCacheDuration) {
        final processedData = jsonDecode(cachedData) as Map<String, dynamic>;
        // Restore Timestamps from ISO strings
        final userData = _restoreDataFromCache(processedData);
        // Restore to memory cache
        _memoryCache[key] = userData;
        _cacheTimestamps[key] = timestamp;
        return userData;
      }
    }

    return null;
  }

  /// Cache job listings with tags
  Future<void> cacheJobListings(
    String cacheKey,
    List<Map<String, dynamic>> jobListings,
  ) async {
    await initialize();
    final key = 'job_listings_$cacheKey';

    _memoryCache[key] = jobListings;
    _cacheTimestamps[key] = DateTime.now();

    // Prepare job listings for persistent cache
    final processedListings =
        jobListings.map((job) => _prepareDataForCache(job)).toList();

    await _prefs!.setString(key, jsonEncode(processedListings));
    await _prefs!.setString(
      '${key}_timestamp',
      DateTime.now().toIso8601String(),
    );
  }

  /// Get cached job listings
  List<Map<String, dynamic>>? getCachedJobListings(String cacheKey) {
    final key = 'job_listings_$cacheKey';

    if (_isCacheValid(key, jobListingCacheDuration)) {
      return (_memoryCache[key] as List?)?.cast<Map<String, dynamic>>();
    }

    final cachedData = _prefs?.getString(key);
    final timestampStr = _prefs?.getString('${key}_timestamp');

    if (cachedData != null && timestampStr != null) {
      final timestamp = DateTime.parse(timestampStr);
      if (DateTime.now().difference(timestamp) < jobListingCacheDuration) {
        final processedListings =
            (jsonDecode(cachedData) as List).cast<Map<String, dynamic>>();
        // Restore Timestamps in job listings
        final jobListings =
            processedListings.map((job) => _restoreDataFromCache(job)).toList();
        _memoryCache[key] = jobListings;
        _cacheTimestamps[key] = timestamp;
        return jobListings;
      }
    }

    return null;
  }

  /// Cache application counts
  void cacheApplicationCount(String key, int count) {
    _memoryCache['app_count_$key'] = count;
    _cacheTimestamps['app_count_$key'] = DateTime.now();
  }

  /// Get cached application count
  int? getCachedApplicationCount(String key) {
    final cacheKey = 'app_count_$key';
    if (_isCacheValid(cacheKey, applicationCountCacheDuration)) {
      return _memoryCache[cacheKey] as int?;
    }
    return null;
  }

  /// Cache notification count
  void cacheNotificationCount(String userId, int count) {
    final key = 'notification_count_$userId';
    _memoryCache[key] = count;
    _cacheTimestamps[key] = DateTime.now();
  }

  /// Get cached notification count
  int? getCachedNotificationCount(String userId) {
    final key = 'notification_count_$userId';
    if (_isCacheValid(key, notificationCountCacheDuration)) {
      return _memoryCache[key] as int?;
    }
    return null;
  }

  /// Clear specific cache
  Future<void> clearCache(String key) async {
    await initialize();
    _memoryCache.remove(key);
    _cacheTimestamps.remove(key);
    await _prefs!.remove(key);
    await _prefs!.remove('${key}_timestamp');
  }

  /// Clear user-specific caches
  Future<void> clearUserCaches(String uid) async {
    await initialize();
    final keysToRemove = <String>[];

    for (final key in _memoryCache.keys) {
      if (key.contains(uid)) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      _memoryCache.remove(key);
      _cacheTimestamps.remove(key);
      await _prefs!.remove(key);
      await _prefs!.remove('${key}_timestamp');
    }
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    await initialize();
    _memoryCache.clear();
    _cacheTimestamps.clear();
    await _prefs!.clear();
  }

  /// Clear all job listing caches (including employer-specific ones)
  Future<void> clearAllJobListingCaches() async {
    await initialize();
    final keysToRemove = <String>[];

    // Find all job listing cache keys in memory
    for (final key in _memoryCache.keys) {
      if (key.startsWith('job_listings_')) {
        keysToRemove.add(key);
      }
    }

    // Remove from memory cache
    for (final key in keysToRemove) {
      _memoryCache.remove(key);
      _cacheTimestamps.remove(key);
    }

    // Clear from persistent cache
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    for (final key in allKeys) {
      if (key.startsWith('job_listings_')) {
        await prefs.remove(key);
        await prefs.remove('${key}_timestamp');
      }
    }
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'memory_cache_size': _memoryCache.length,
      'timestamps_count': _cacheTimestamps.length,
      'cached_items': _memoryCache.keys.toList(),
    };
  }

  /// Convert Timestamp objects to ISO strings for JSON serialization
  Map<String, dynamic> _prepareDataForCache(Map<String, dynamic> data) {
    final Map<String, dynamic> processedData = {};

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is Timestamp) {
        processedData[key] = {'_timestamp': value.toDate().toIso8601String()};
      } else if (value is Map<String, dynamic>) {
        processedData[key] = _prepareDataForCache(value);
      } else if (value is List) {
        processedData[key] = _prepareListForCache(value);
      } else {
        processedData[key] = value;
      }
    }

    return processedData;
  }

  /// Convert List items recursively
  List<dynamic> _prepareListForCache(List<dynamic> list) {
    return list.map((item) {
      if (item is Timestamp) {
        return {'_timestamp': item.toDate().toIso8601String()};
      } else if (item is Map<String, dynamic>) {
        return _prepareDataForCache(item);
      } else if (item is List) {
        return _prepareListForCache(item);
      } else {
        return item;
      }
    }).toList();
  }

  /// Convert ISO strings back to Timestamp objects
  Map<String, dynamic> _restoreDataFromCache(Map<String, dynamic> data) {
    final Map<String, dynamic> processedData = {};

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is Map<String, dynamic> && value.containsKey('_timestamp')) {
        processedData[key] = Timestamp.fromDate(
          DateTime.parse(value['_timestamp'] as String),
        );
      } else if (value is Map<String, dynamic>) {
        processedData[key] = _restoreDataFromCache(value);
      } else if (value is List) {
        processedData[key] = _restoreListFromCache(value);
      } else {
        processedData[key] = value;
      }
    }

    return processedData;
  }

  /// Restore List items recursively
  List<dynamic> _restoreListFromCache(List<dynamic> list) {
    return list.map((item) {
      if (item is Map<String, dynamic> && item.containsKey('_timestamp')) {
        return Timestamp.fromDate(DateTime.parse(item['_timestamp'] as String));
      } else if (item is Map<String, dynamic>) {
        return _restoreDataFromCache(item);
      } else if (item is List) {
        return _restoreListFromCache(item);
      } else {
        return item;
      }
    }).toList();
  }

  /// Test method to verify Timestamp conversion (for debugging)
  Map<String, dynamic> testTimestampConversion(Map<String, dynamic> testData) {
    final processed = _prepareDataForCache(testData);
    return _restoreDataFromCache(processed);
  }
}
