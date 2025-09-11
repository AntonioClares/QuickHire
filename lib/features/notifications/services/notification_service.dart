import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quickhire/features/notifications/models/notification_model.dart';
import 'package:quickhire/core/services/cache_service.dart';

class NotificationService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static final _cacheService = CacheService();

  // Collection reference
  static CollectionReference get _notificationsCollection =>
      _firestore.collection('notifications');

  // Cache for unread count with timestamps
  static final Map<String, int> _unreadCountCache = {};
  static final Map<String, DateTime> _unreadCountTimestamps = {};
  static const Duration _unreadCountCacheDuration = Duration(minutes: 2);

  /// Check if unread count cache is still valid
  static bool _isUnreadCountCacheValid(String userId) {
    final timestamp = _unreadCountTimestamps[userId];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _unreadCountCacheDuration;
  }

  /// Cache unread count
  static void _cacheUnreadCount(String userId, int count) {
    _unreadCountCache[userId] = count;
    _unreadCountTimestamps[userId] = DateTime.now();
    _cacheService.cacheNotificationCount(userId, count);
  }

  /// Get cached unread count
  static int? _getCachedUnreadCount(String userId) {
    // Check memory cache first
    if (_isUnreadCountCacheValid(userId)) {
      return _unreadCountCache[userId];
    }

    // Check persistent cache
    final cachedCount = _cacheService.getCachedNotificationCount(userId);
    if (cachedCount != null) {
      _unreadCountCache[userId] = cachedCount;
      _unreadCountTimestamps[userId] = DateTime.now();
      return cachedCount;
    }

    return null;
  }

  // Create a new notification
  static Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _notificationsCollection.add({
        'userId': userId,
        'type': type.toString(),
        'title': title,
        'message': message,
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating notification: $e');
      rethrow;
    }
  }

  // Get notifications for current user
  static Stream<List<NotificationModel>> getNotificationsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _notificationsCollection
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();
        });
  }

  // Get unread notification count with caching
  static Stream<int> getUnreadCountStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _notificationsCollection
        .where('userId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          final count = snapshot.docs.length;
          // Cache the result for future quick access
          _cacheUnreadCount(currentUser.uid, count);
          return count;
        });
  }

  // Mark notification as read with cache invalidation
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
      });

      // Invalidate cache after marking as read
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        _invalidateUnreadCountCache(currentUser.uid);
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  // Mark all notifications as read with cache invalidation
  static Future<void> markAllAsRead() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final batch = _firestore.batch();
      final querySnapshot =
          await _notificationsCollection
              .where('userId', isEqualTo: currentUser.uid)
              .where('isRead', isEqualTo: false)
              .get();

      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      // Clear cache after marking all as read
      _invalidateUnreadCountCache(currentUser.uid);
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Invalidate unread count cache for a user
  static void _invalidateUnreadCountCache(String userId) {
    _unreadCountCache.remove(userId);
    _unreadCountTimestamps.remove(userId);
    // Also clear from persistent cache
    _cacheService.clearCache('notification_count_$userId');
  }

  // Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  // Helper methods for specific notification types

  // Job application notification (for employers)
  static Future<void> notifyJobApplication({
    required String employerId,
    required String applicantName,
    required String jobTitle,
    required String jobId,
    required String applicationId,
  }) async {
    await createNotification(
      userId: employerId,
      type: NotificationType.jobApplication,
      title: 'New Job Application',
      message: '$applicantName has applied for your job: $jobTitle',
      data: {
        'jobId': jobId,
        'applicationId': applicationId,
        'applicantName': applicantName,
      },
    );
  }

  // Application success notification (for employees)
  static Future<void> notifyApplicationSuccess({
    required String applicantId,
    required String jobTitle,
    required String companyName,
    required String jobId,
  }) async {
    await createNotification(
      userId: applicantId,
      type: NotificationType.applicationStatusUpdate,
      title: 'Application Submitted',
      message:
          'You have successfully applied for the "$jobTitle" listed by $companyName.',
      data: {'jobId': jobId, 'jobTitle': jobTitle, 'companyName': companyName},
    );
  }

  // Application status update notification
  static Future<void> notifyApplicationStatusUpdate({
    required String applicantId,
    required String jobTitle,
    required String status,
    required String jobId,
    required String applicationId,
  }) async {
    final isAccepted = status.toLowerCase() == 'accepted';
    await createNotification(
      userId: applicantId,
      type:
          isAccepted
              ? NotificationType.applicationAccepted
              : NotificationType.applicationRejected,
      title: isAccepted ? 'Application Accepted!' : 'Application Update',
      message:
          isAccepted
              ? 'Congratulations! Your application for $jobTitle has been accepted.'
              : 'Your application for $jobTitle has been updated: $status',
      data: {
        'jobId': jobId,
        'applicationId': applicationId,
        'status': status,
        'jobTitle': jobTitle,
      },
    );
  }

  // New message notification
  static Future<void> notifyNewMessage({
    required String recipientId,
    required String senderName,
    required String conversationId,
    String? messagePreview,
  }) async {
    await createNotification(
      userId: recipientId,
      type: NotificationType.newMessage,
      title: 'New Message',
      message:
          messagePreview != null
              ? '$senderName: $messagePreview'
              : 'You have a new message from $senderName',
      data: {'conversationId': conversationId, 'senderName': senderName},
    );
  }
}
