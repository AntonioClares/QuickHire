import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for user profiles to avoid repeated queries
  final Map<String, UserProfile> _profileCache = {};

  /// Get user profile by UID
  Future<UserProfile?> getUserProfile(String uid) async {
    // Return cached profile if available
    if (_profileCache.containsKey(uid)) {
      return _profileCache[uid];
    }

    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        final profile = UserProfile.fromFirestore(doc);
        _profileCache[uid] = profile; // Cache the result
        return profile;
      }

      return null;
    } catch (e) {
      print('Error fetching user profile for $uid: $e');
      return null;
    }
  }

  /// Get multiple user profiles at once (more efficient)
  Future<Map<String, UserProfile>> getUserProfiles(List<String> uids) async {
    final Map<String, UserProfile> profiles = {};
    final List<String> uncachedUids = [];

    // Check cache first
    for (final uid in uids) {
      if (_profileCache.containsKey(uid)) {
        profiles[uid] = _profileCache[uid]!;
      } else {
        uncachedUids.add(uid);
      }
    }

    // Fetch uncached profiles
    if (uncachedUids.isNotEmpty) {
      try {
        final chunks = _chunkList(
          uncachedUids,
          10,
        ); // Firestore 'in' query limit

        for (final chunk in chunks) {
          final querySnapshot =
              await _firestore
                  .collection('users')
                  .where(FieldPath.documentId, whereIn: chunk)
                  .get();

          for (final doc in querySnapshot.docs) {
            if (doc.exists && doc.data().isNotEmpty) {
              final profile = UserProfile.fromFirestore(doc);
              profiles[doc.id] = profile;
              _profileCache[doc.id] = profile; // Cache the result
            }
          }
        }
      } catch (e) {
        print('Error fetching user profiles: $e');
      }
    }

    return profiles;
  }

  /// Clear cache for a specific user (useful when user data changes)
  void clearUserCache(String uid) {
    _profileCache.remove(uid);
  }

  /// Clear all cached user profiles
  void clearAllCache() {
    _profileCache.clear();
  }

  /// Helper method to chunk a list into smaller lists
  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (int i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(
          i,
          i + chunkSize > list.length ? list.length : i + chunkSize,
        ),
      );
    }
    return chunks;
  }
}

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String? profilePicture;
  final String? userType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.profilePicture,
    this.userType,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserProfile(
      uid: doc.id,
      name: data['name'] ?? 'Unknown User',
      email: data['email'] ?? '',
      profilePicture: data['imageUrl'],
      userType: data['type'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'profilePicture': profilePicture,
      'userType': userType,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  String toString() {
    return 'UserProfile{uid: $uid, name: $name, email: $email}';
  }
}
