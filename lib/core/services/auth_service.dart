import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:quickhire/core/services/cache_service.dart';
import 'package:quickhire/features/job_application/repositories/job_application_repository.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

/// Model class to hold user data from Firestore
class UserData {
  final String uid;
  final String name;
  final String? imageUrl;
  final String? type;
  final DateTime? createdAt;

  UserData({
    required this.uid,
    required this.name,
    this.imageUrl,
    this.type,
    this.createdAt,
  });

  factory UserData.fromFirestore(Map<String, dynamic> data) {
    return UserData(
      uid: data['uid'] ?? '',
      name: data['name'] ?? 'User',
      imageUrl: data['imageUrl'],
      type: data['type'],
      createdAt: data['createdAt']?.toDate(),
    );
  }
}

class AuthService extends ChangeNotifier {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final CacheService _cacheService = CacheService();

  // Cache for user names to avoid repeated API calls
  final Map<String, String> _userNameCache = {};

  // Cache for user documents with timestamps
  final Map<String, Map<String, dynamic>> _userDocumentCache = {};
  final Map<String, DateTime> _documentCacheTimestamps = {};
  static const Duration _documentCacheDuration = Duration(minutes: 30);

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  /// Check if document cache is still valid
  bool _isDocumentCacheValid(String uid) {
    final timestamp = _documentCacheTimestamps[uid];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _documentCacheDuration;
  }

  /// Cache user document data
  void _cacheUserDocument(String uid, Map<String, dynamic> userData) {
    _userDocumentCache[uid] = userData;
    _documentCacheTimestamps[uid] = DateTime.now();

    // Also cache in persistent storage
    _cacheService.cacheUserProfile(uid, userData);
  }

  /// Get cached user document
  Map<String, dynamic>? _getCachedUserDocument(String uid) {
    // Check memory cache first
    if (_isDocumentCacheValid(uid)) {
      return _userDocumentCache[uid];
    }

    // Check persistent cache
    final cachedData = _cacheService.getCachedUserProfile(uid);
    if (cachedData != null) {
      // Restore to memory cache
      _userDocumentCache[uid] = cachedData;
      _documentCacheTimestamps[uid] = DateTime.now();
      return cachedData;
    }

    return null;
  }

  /// Creates or updates user document in Firestore
  Future<void> _createOrUpdateUserDocument(
    User user, {
    String? displayName,
  }) async {
    final userRef = firestore.collection('users').doc(user.uid);

    // Check if document already exists
    final docSnapshot = await userRef.get();

    final userData = {
      'uid': user.uid,
      'name':
          displayName ??
          user.displayName ??
          user.email?.split('@')[0] ??
          'User',
      'imageUrl': user.photoURL,
      'createdAt': docSnapshot.exists ? null : FieldValue.serverTimestamp(),
    };

    // Remove null values
    userData.removeWhere((key, value) => value == null);

    if (docSnapshot.exists) {
      // Update existing document (only name and imageUrl)
      final updateData = <String, dynamic>{};
      if (userData['name'] != null) updateData['name'] = userData['name'];
      if (userData['imageUrl'] != null)
        updateData['imageUrl'] = userData['imageUrl'];

      if (updateData.isNotEmpty) {
        await userRef.update(updateData);
      }
    } else {
      // Create new document
      await userRef.set(userData);
    }
  }

  /// Gets user document from Firestore with simple caching optimization
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDocument(
    String uid,
  ) async {
    final doc = await firestore.collection('users').doc(uid).get();

    // Cache the document data if it exists for other methods to use
    if (doc.exists && doc.data() != null) {
      _cacheUserDocument(uid, doc.data()!);
    }

    return doc;
  }

  /// Gets user name by UID with enhanced caching
  Future<String> getUserNameByUid(String uid) async {
    // Return cached name if available and fresh
    if (_userNameCache.containsKey(uid)) {
      return _userNameCache[uid]!;
    }

    // Try to get from persistent cache first
    final cachedUserData = _getCachedUserDocument(uid);
    if (cachedUserData != null) {
      final userName = cachedUserData['name'] ?? 'User';
      _userNameCache[uid] = userName;
      return userName;
    }

    try {
      final userDoc = await firestore.collection('users').doc(uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        final userName = userData['name'] ?? 'User';

        // Cache both the name and full document data
        _userNameCache[uid] = userName;
        _cacheUserDocument(uid, userData);

        return userName;
      } else {
        // Return UID as fallback if user document doesn't exist
        _userNameCache[uid] = uid;
        return uid;
      }
    } catch (e) {
      debugPrint('Error fetching user name for UID $uid: $e');
      // Return UID as fallback on error
      _userNameCache[uid] = uid;
      return uid;
    }
  }

  /// Gets user data stream from Firestore
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserDocumentStream(
    String uid,
  ) {
    return firestore.collection('users').doc(uid).snapshots();
  }

  /// Updates user type in Firestore
  Future<bool> updateUserType(String userType) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      await firestore.collection('users').doc(user.uid).update({
        'type': userType,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Failed to update user type: $e');
      return false;
    }
  }

  /// Checks if user has selected a user type
  Future<bool> hasUserType() async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final userDoc = await getUserDocument(user.uid);
      final userData = userDoc.data();

      return userData != null &&
          userData.containsKey('type') &&
          userData['type'] != null &&
          userData['type'].toString().isNotEmpty;
    } catch (e) {
      print('Error checking user type: $e');
      return false;
    }
  }

  /// Gets the user's selected type
  Future<String?> getUserType() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final userDoc = await getUserDocument(user.uid);
      final userData = userDoc.data();

      return userData?['type'];
    } catch (e) {
      print('Error getting user type: $e');
      return null;
    }
  }

  /// Retrieves comprehensive user data from Firestore with timeout
  ///
  /// This method fetches the user's complete profile data from Firestore
  /// and returns it as a structured UserData object.
  ///
  /// Returns null if user is not authenticated or document doesn't exist.
  /// Throws TimeoutException if the operation takes longer than specified timeout.
  Future<UserData?> getCurrentUserData({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final docSnapshot = await firestore
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(timeout);

      if (!docSnapshot.exists || docSnapshot.data() == null) {
        // If document doesn't exist, create it first
        await _createOrUpdateUserDocument(user);

        // Try to fetch again after creation
        final newDocSnapshot = await firestore
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(timeout);

        if (!newDocSnapshot.exists || newDocSnapshot.data() == null) {
          return null;
        }

        return UserData.fromFirestore(newDocSnapshot.data()!);
      }

      return UserData.fromFirestore(docSnapshot.data()!);
    } catch (e) {
      // Log error but don't throw - let caller handle null return
      print('Error fetching user data: $e');
      return null;
    }
  }

  /// Gets just the user's display name from Firestore with timeout
  ///
  /// This is a convenience method for when you only need the name.
  /// Returns 'User' as fallback if name cannot be retrieved.
  Future<String> getCurrentUserName({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final userData = await getCurrentUserData(timeout: timeout);
      return userData?.name ?? 'User';
    } catch (e) {
      print('Error fetching user name: $e');
      return 'User';
    }
  }

  /// Stream version of getCurrentUserData for real-time updates
  Stream<UserData?> getCurrentUserDataStream() {
    final user = currentUser;
    if (user == null) return Stream.value(null);

    return firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) {
            return null;
          }
          return UserData.fromFirestore(snapshot.data()!);
        })
        .handleError((error) {
          print('Error in user data stream: $error');
          return null;
        });
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final userCredential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Update user document on sign in
    if (userCredential.user != null) {
      await _createOrUpdateUserDocument(userCredential.user!);
    }

    return userCredential;
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Create user document after account creation
    if (userCredential.user != null) {
      await _createOrUpdateUserDocument(userCredential.user!);
    }

    return userCredential;
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        throw FirebaseAuthException(
          code: 'sign_in_canceled',
          message: 'Google sign-in was canceled',
        );
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final userCredential = await firebaseAuth.signInWithCredential(
        credential,
      );

      // Create or update user document with Google data
      if (userCredential.user != null) {
        await _createOrUpdateUserDocument(userCredential.user!);
      }

      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'google_sign_in_failed',
        message: 'Google sign-in failed: ${e.toString()}',
      );
    }
  }

  Future<void> signOut() async {
    final currentUserId = currentUser?.uid;

    try {
      // Clear internal caches before signing out
      _userNameCache.clear();
      _userDocumentCache.clear();
      _documentCacheTimestamps.clear();

      // Clear user-specific caches from CacheService if we have a user ID
      if (currentUserId != null) {
        await _cacheService.clearUserCaches(currentUserId);
      }

      // Clear all cached data from CacheService
      await _cacheService.clearAllCaches();

      // Clear all job application in-memory caches
      JobApplicationRepository().clearAllCaches();

      // Sign out from both Firebase and Google
      await Future.wait([firebaseAuth.signOut(), googleSignIn.signOut()]);

      // Wait a moment to ensure sign out is fully processed
      await Future.delayed(const Duration(milliseconds: 200));

      // Verify sign out was successful
      if (currentUser != null) {
        throw Exception('Sign out was not completed successfully');
      }

      // Notify listeners of auth state change
      notifyListeners();
    } catch (e) {
      print('Error during sign out: $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateUsername(String username) async {
    await currentUser!.updateDisplayName(username);

    // Update user document in Firestore as well
    if (currentUser != null) {
      await _createOrUpdateUserDocument(currentUser!, displayName: username);
    }
  }

  /// Updates user profile image
  Future<void> updateUserImage(String imageUrl) async {
    await currentUser!.updatePhotoURL(imageUrl);

    // Update user document in Firestore as well
    if (currentUser != null) {
      await firestore.collection('users').doc(currentUser!.uid).update({
        'imageUrl': imageUrl,
      });
    }
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    final uid = currentUser!.uid;

    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await currentUser!.reauthenticateWithCredential(credential);

    // Delete user document from Firestore before deleting auth account
    await firestore.collection('users').doc(uid).delete();

    await currentUser!.delete();
    await firebaseAuth.signOut();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }

  // Helper method to check if user is signed in with Google
  bool isSignedInWithGoogle() {
    final user = currentUser;
    if (user == null) return false;

    return user.providerData.any(
      (provider) => provider.providerId == GoogleAuthProvider.PROVIDER_ID,
    );
  }

  /// Clears the user name cache and document cache
  void clearUserNameCache() {
    _userNameCache.clear();
    _userDocumentCache.clear();
    _documentCacheTimestamps.clear();
  }

  /// Updates user name with 7-day restriction
  Future<bool> updateUserName(String newName) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final userRef = firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final lastNameChange = userData['lastNameChange'] as Timestamp?;

      // Check if 7 days have passed since last name change
      if (lastNameChange != null) {
        final daysSinceLastChange =
            DateTime.now().difference(lastNameChange.toDate()).inDays;
        if (daysSinceLastChange < 7) {
          return false; // Cannot change name yet
        }
      }

      // Update the name and lastNameChange timestamp
      await userRef.update({
        'name': newName,
        'lastNameChange': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Clear the name cache for this user
      _userNameCache.remove(user.uid);

      return true;
    } catch (e) {
      debugPrint('Error updating user name: $e');
      return false;
    }
  }

  /// Updates user profile image
  Future<bool> updateUserProfileImage(String? imageUrl) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final userRef = firestore.collection('users').doc(user.uid);
      await userRef.update({
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error updating user profile image: $e');
      return false;
    }
  }

  /// Checks if user can change their name (7-day restriction)
  Future<bool> canChangeUserName() async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final userDoc = await getUserDocument(user.uid);
      if (!userDoc.exists) return true; // New user can change name

      final userData = userDoc.data()!;
      final lastNameChange = userData['lastNameChange'] as Timestamp?;

      if (lastNameChange == null) return true; // Never changed name before

      final daysSinceLastChange =
          DateTime.now().difference(lastNameChange.toDate()).inDays;
      return daysSinceLastChange >= 7;
    } catch (e) {
      debugPrint('Error checking name change eligibility: $e');
      return false;
    }
  }

  /// Gets number of days until user can change name again
  Future<int> getDaysUntilNameChange() async {
    final user = currentUser;
    if (user == null) return 0;

    try {
      final userDoc = await getUserDocument(user.uid);
      if (!userDoc.exists) return 0;

      final userData = userDoc.data()!;
      final lastNameChange = userData['lastNameChange'] as Timestamp?;

      if (lastNameChange == null) return 0;

      final daysSinceLastChange =
          DateTime.now().difference(lastNameChange.toDate()).inDays;
      return daysSinceLastChange >= 7 ? 0 : 7 - daysSinceLastChange;
    } catch (e) {
      debugPrint('Error calculating days until name change: $e');
      return 0;
    }
  }
}
