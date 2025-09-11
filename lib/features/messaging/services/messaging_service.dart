import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quickhire/core/services/auth_service.dart';
import 'package:quickhire/features/messaging/models/conversation_model.dart';
import 'package:quickhire/features/notifications/services/notification_service.dart';
import 'package:quickhire/core/services/user_profile_service.dart';
import 'package:quickhire/core/services/cache_service.dart';

class MessagingService {
  static final MessagingService _instance = MessagingService._internal();
  factory MessagingService() => _instance;
  MessagingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final UserProfileService _userProfileService = UserProfileService();
  final CacheService _cacheService = CacheService();

  // Cache for user data to reduce repeated queries
  final Map<String, Map<String, dynamic>> _userDataCache = {};
  final Map<String, DateTime> _userDataCacheTimestamps = {};
  static const Duration _userDataCacheDuration = Duration(minutes: 30);

  /// Check if user data cache is still valid
  bool _isUserDataCacheValid(String uid) {
    final timestamp = _userDataCacheTimestamps[uid];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _userDataCacheDuration;
  }

  /// Get cached or fetch user data efficiently
  Future<Map<String, dynamic>?> _getUserDataOptimized(String uid) async {
    // Check memory cache first
    if (_isUserDataCacheValid(uid)) {
      return _userDataCache[uid];
    }

    // Check persistent cache
    final cachedData = _cacheService.getCachedUserProfile(uid);
    if (cachedData != null) {
      _userDataCache[uid] = cachedData;
      _userDataCacheTimestamps[uid] = DateTime.now();
      return cachedData;
    }

    // Fetch from Firestore as last resort
    try {
      final userDoc = await _authService.getUserDocument(uid);
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        _userDataCache[uid] = userData;
        _userDataCacheTimestamps[uid] = DateTime.now();
        _cacheService.cacheUserProfile(uid, userData);
        return userData;
      }
    } catch (e) {
      print('Error fetching user data for $uid: $e');
    }

    return null;
  }

  /// Batch process conversations with optimized user data fetching
  Future<List<Conversation>> _processConversationsBatch(
    List<QueryDocumentSnapshot> docs,
    String currentUserId,
  ) async {
    final conversations = <Conversation>[];
    final userIds = <String>{};

    // Collect all unique user IDs first
    for (var doc in docs) {
      try {
        final conversation = Conversation.fromFirestore(doc);
        final otherParticipantId = conversation.participants.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );
        if (otherParticipantId.isNotEmpty) {
          userIds.add(otherParticipantId);
        }
      } catch (e) {
        print('Error parsing conversation ${doc.id}: $e');
      }
    }

    // Batch fetch user profiles for all unique IDs
    final userProfiles = await _userProfileService.getUserProfiles(
      userIds.toList(),
    );

    // Process conversations with cached user data
    for (var doc in docs) {
      try {
        final conversation = Conversation.fromFirestore(doc);
        final otherParticipantId = conversation.participants.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );

        if (otherParticipantId.isNotEmpty) {
          final userProfile = userProfiles[otherParticipantId];
          if (userProfile != null) {
            final updatedConversation = conversation.copyWith(
              name: userProfile.name,
              profilePicture: userProfile.profilePicture,
            );
            conversations.add(updatedConversation);
          } else {
            // Add conversation with default name if user profile not found
            conversations.add(conversation.copyWith(name: 'Unknown User'));
          }
        } else {
          conversations.add(conversation);
        }
      } catch (e) {
        print('Error processing conversation ${doc.id}: $e');
      }
    }

    return conversations;
  }

  // Get conversations for current user with optimized user data fetching
  Stream<List<Conversation>> getConversations() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUser.uid)
        .snapshots()
        .asyncMap((snapshot) async {
          try {
            // Use batch processing for better performance
            final conversations = await _processConversationsBatch(
              snapshot.docs,
              currentUser.uid,
            );

            // Sort conversations by timestamp (most recent first)
            conversations.sort((a, b) => b.timestamp.compareTo(a.timestamp));

            return conversations;
          } catch (e) {
            print('Error processing conversations: $e');
            return <Conversation>[];
          }
        })
        .handleError((error) {
          print('Error in conversations stream: $error');
          return <Conversation>[];
        });
  }

  // Get messages for a conversation
  Stream<List<Message>> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList(),
        );
  }

  // Send a message
  Future<void> sendMessage(String conversationId, String message) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final messageData = Message(
      id: '',
      senderId: currentUser.uid,
      message: message,
      timestamp: DateTime.now(),
      isRead: false,
    );

    // Add message to conversation
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(messageData.toMap());

    // Get conversation participants to determine read status
    final conversationDoc =
        await _firestore.collection('conversations').doc(conversationId).get();

    if (conversationDoc.exists) {
      final data = conversationDoc.data() as Map<String, dynamic>;
      final participants = List<String>.from(data['participants'] ?? []);

      // Create readStatus map - current user has read it (since they sent it), others haven't
      final readStatus = <String, bool>{};
      for (String participantId in participants) {
        readStatus[participantId] = participantId == currentUser.uid;
      }

      // Update conversation with last message
      await _firestore.collection('conversations').doc(conversationId).update({
        'lastMessage': message,
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'lastMessageSenderId': currentUser.uid,
        'readStatus': readStatus,
      });

      // Send notification to other participants
      try {
        final otherParticipants = participants.where(
          (id) => id != currentUser.uid,
        );
        final senderProfile = await _userProfileService.getUserProfile(
          currentUser.uid,
        );
        final senderName = senderProfile?.name ?? 'Someone';

        for (String recipientId in otherParticipants) {
          await NotificationService.notifyNewMessage(
            recipientId: recipientId,
            senderName: senderName,
            conversationId: conversationId,
            messagePreview:
                message.length > 50
                    ? '${message.substring(0, 50)}...'
                    : message,
          );
        }
      } catch (e) {
        // Don't fail the message if notifications fail
        print('Error sending message notification: $e');
      }
    }
  }

  // Create or get conversation between two users
  Future<String> createOrGetConversation(String otherUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final participants = [currentUser.uid, otherUserId]..sort();

    // Check if conversation already exists
    final existingConversation =
        await _firestore
            .collection('conversations')
            .where('participants', isEqualTo: participants)
            .limit(1)
            .get();

    if (existingConversation.docs.isNotEmpty) {
      return existingConversation.docs.first.id;
    }

    // Create new conversation
    final readStatus = <String, bool>{};
    for (String participantId in participants) {
      readStatus[participantId] =
          true; // All participants have "read" empty conversation
    }

    final conversationData = {
      'participants': participants,
      'lastMessage': '',
      'timestamp': Timestamp.fromDate(DateTime.now()),
      'readStatus': readStatus,
      'typingStatus': <String, bool>{},
    };

    final docRef = await _firestore
        .collection('conversations')
        .add(conversationData);

    return docRef.id;
  }

  // Update typing status
  Future<void> updateTypingStatus(String conversationId, bool isTyping) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await _firestore.collection('conversations').doc(conversationId).update({
      'typingStatus.${currentUser.uid}': isTyping,
    });
  }

  // Get typing status for conversation
  Stream<Map<String, bool>> getTypingStatus(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            return Map<String, bool>.from(data['typingStatus'] ?? {});
          }
          return <String, bool>{};
        });
  }

  // Mark conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await _firestore.collection('conversations').doc(conversationId).update({
      'readStatus.${currentUser.uid}': true,
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final messages =
        await _firestore
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .where('senderId', isNotEqualTo: currentUser.uid)
            .where('isRead', isEqualTo: false)
            .get();

    final batch = _firestore.batch();
    for (var doc in messages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // Get unread conversations count for current user
  Stream<int> getUnreadConversationsCount() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Stream.value(0);

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUser.uid)
        .snapshots()
        .map((snapshot) {
          int unreadCount = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final readStatus = Map<String, bool>.from(data['readStatus'] ?? {});

            // Check if current user has unread messages
            if (readStatus[currentUser.uid] == false) {
              unreadCount++;
            }
          }
          return unreadCount;
        });
  }

  // Get unread message count for current user
  Stream<int> getUnreadMessageCount() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Stream.value(0);

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUser.uid)
        .snapshots()
        .map((snapshot) {
          int unreadCount = 0;

          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();
              final readStatus = Map<String, bool>.from(
                data['readStatus'] ?? {},
              );

              // Check if current user has unread messages in this conversation
              if (readStatus[currentUser.uid] == false) {
                unreadCount++;
              }
            } catch (e) {
              // Skip this conversation if there's an error parsing it
              continue;
            }
          }

          return unreadCount;
        })
        .handleError((error) {
          return 0;
        });
  }

  // Debug method to test basic Firestore connectivity
  Future<bool> testFirestoreConnection() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      // Try to read the conversations collection
      await _firestore
          .collection('conversations')
          .where('participants', arrayContains: currentUser.uid)
          .limit(1)
          .get();

      return true; // If we get here, connection works
    } catch (e) {
      print('Firestore connection test failed: $e');
      return false;
    }
  }

  // Migration method to add readStatus to existing conversations
  Future<void> migrateConversationsToReadStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final conversations =
        await _firestore
            .collection('conversations')
            .where('participants', arrayContains: currentUser.uid)
            .get();

    final batch = _firestore.batch();

    for (var doc in conversations.docs) {
      final data = doc.data();

      // Only migrate if readStatus doesn't exist
      if (!data.containsKey('readStatus')) {
        final participants = List<String>.from(data['participants'] ?? []);
        final readStatus = <String, bool>{};
        final isRead = data['isRead'] ?? true;

        // Set readStatus for all participants based on old isRead value
        for (String participantId in participants) {
          readStatus[participantId] = isRead;
        }

        batch.update(doc.reference, {'readStatus': readStatus});
      }
    }

    await batch.commit();
  }
}
