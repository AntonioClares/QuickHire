import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quickhire/core/services/cache_service.dart';

class UserSearchService {
  static final UserSearchService _instance = UserSearchService._internal();
  factory UserSearchService() => _instance;
  UserSearchService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheService _cacheService = CacheService();

  // Cache for search results
  final Map<String, List<UserProfile>> _searchCache = {};
  final Map<String, DateTime> _searchCacheTimestamps = {};
  static const Duration _searchCacheDuration = Duration(minutes: 10);

  /// Check if search cache is still valid
  bool _isSearchCacheValid(String query) {
    final timestamp = _searchCacheTimestamps[query];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _searchCacheDuration;
  }

  /// Cache search results
  void _cacheSearchResults(String query, List<UserProfile> results) {
    _searchCache[query] = results;
    _searchCacheTimestamps[query] = DateTime.now();
  }

  // Search users by name with caching and pagination (case-insensitive)
  Future<List<UserProfile>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    // Convert query to lowercase for case-insensitive search
    final lowercaseQuery = query.toLowerCase();

    // Check cache first
    if (_isSearchCacheValid(lowercaseQuery)) {
      return _searchCache[lowercaseQuery] ?? [];
    }

    try {
      // Optimized approach: Use startAt and endAt for prefix matching
      // This is more efficient than loading all users and filtering client-side
      final users = <UserProfile>[];

      // Try exact prefix matching first (more efficient)
      try {
        final prefixQuery =
            await _firestore
                .collection('users')
                .where('name', isGreaterThanOrEqualTo: query)
                .where('name', isLessThanOrEqualTo: query + '\uf8ff')
                .limit(10)
                .get();

        for (var doc in prefixQuery.docs) {
          if (doc.id == currentUser.uid) continue;
          users.add(UserProfile.fromFirestore(doc));
        }
      } catch (e) {
        print('Prefix search failed, falling back to full search: $e');
      }

      // If prefix search didn't yield enough results, fall back to broader search
      if (users.length < 5) {
        final snapshot =
            await _firestore
                .collection('users')
                .limit(50) // Reduced limit for better performance
                .get();

        for (var doc in snapshot.docs) {
          // Skip current user and already found users
          if (doc.id == currentUser.uid || users.any((u) => u.id == doc.id))
            continue;

          final data = doc.data();
          final userName = (data['name'] as String?)?.toLowerCase() ?? '';

          // Skip users without names
          if (userName.isEmpty) continue;

          // Check if the name contains our search query
          if (userName.contains(lowercaseQuery)) {
            users.add(UserProfile.fromFirestore(doc));
            if (users.length >= 10) break; // Limit total results
          }
        }
      }

      // Sort by relevance (exact matches first, then partial matches)
      users.sort((a, b) {
        final aName = a.name.toLowerCase();
        final bName = b.name.toLowerCase();

        final aStartsWith = aName.startsWith(lowercaseQuery);
        final bStartsWith = bName.startsWith(lowercaseQuery);

        if (aStartsWith && !bStartsWith) return -1;
        if (!aStartsWith && bStartsWith) return 1;

        return aName.compareTo(bName);
      });

      final finalResults = users.take(10).toList();

      // Cache the results
      _cacheSearchResults(lowercaseQuery, finalResults);

      return finalResults;
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Get user profile by ID with caching
  Future<UserProfile?> getUserProfile(String userId) async {
    // Check if we have this user cached from a recent search
    for (final searchResults in _searchCache.values) {
      final cachedUser = searchResults.where((u) => u.id == userId).firstOrNull;
      if (cachedUser != null) {
        return cachedUser;
      }
    }

    // Check persistent cache via cache service
    final cachedData = _cacheService.getCachedUserProfile(userId);
    if (cachedData != null) {
      return UserProfile(
        id: userId,
        name: cachedData['name'] ?? 'Unknown User',
        profilePicture: cachedData['profilePicture'],
        email: cachedData['email'],
        role: cachedData['role'],
      );
    }

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final profile = UserProfile.fromFirestore(doc);

        // Cache the user data for future use
        if (doc.data() != null) {
          _cacheService.cacheUserProfile(userId, doc.data()!);
        }

        return profile;
      }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  /// Clear search cache
  void clearSearchCache() {
    _searchCache.clear();
    _searchCacheTimestamps.clear();
  }
}

class UserProfile {
  final String id;
  final String name;
  final String? profilePicture;
  final String? email;
  final String? role;

  UserProfile({
    required this.id,
    required this.name,
    this.profilePicture,
    this.email,
    this.role,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      name: data['name'] ?? 'Unknown User',
      profilePicture: data['profilePicture'],
      email: data['email'],
      role: data['role'],
    );
  }
}
