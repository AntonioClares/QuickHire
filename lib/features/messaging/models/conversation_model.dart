import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Conversation {
  final String id;
  final String? name;
  final String? profilePicture;
  final String lastMessage;
  final DateTime timestamp;
  final bool isRead;
  final List<String> participants;
  final String? lastMessageSenderId;
  final Map<String, bool> typingStatus;
  final Map<String, bool> readStatus;

  Conversation({
    required this.id,
    this.name,
    this.profilePicture,
    required this.lastMessage,
    required this.timestamp,
    required this.isRead,
    required this.participants,
    this.lastMessageSenderId,
    this.typingStatus = const {},
    this.readStatus = const {},
  });

  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final currentUser = FirebaseAuth.instance.currentUser;
    final readStatusMap = Map<String, bool>.from(data['readStatus'] ?? {});

    // Determine if current user has read this conversation
    bool isReadByCurrentUser;
    if (currentUser != null && readStatusMap.containsKey(currentUser.uid)) {
      isReadByCurrentUser = readStatusMap[currentUser.uid] ?? true;
    } else {
      // Fallback to old isRead field for backward compatibility
      isReadByCurrentUser = data['isRead'] ?? true;
    }

    return Conversation(
      id: doc.id,
      name: data['name'],
      profilePicture: data['profilePicture'],
      lastMessage: data['lastMessage'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: isReadByCurrentUser,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessageSenderId: data['lastMessageSenderId'],
      typingStatus: Map<String, bool>.from(data['typingStatus'] ?? {}),
      readStatus: readStatusMap,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'profilePicture': profilePicture,
      'lastMessage': lastMessage,
      'timestamp': Timestamp.fromDate(timestamp),
      'participants': participants,
      'lastMessageSenderId': lastMessageSenderId,
      'typingStatus': typingStatus,
      'readStatus': readStatus,
    };
  }

  Conversation copyWith({
    String? id,
    String? name,
    String? profilePicture,
    String? lastMessage,
    DateTime? timestamp,
    bool? isRead,
    List<String>? participants,
    String? lastMessageSenderId,
    Map<String, bool>? typingStatus,
    Map<String, bool>? readStatus,
  }) {
    return Conversation(
      id: id ?? this.id,
      name: name ?? this.name,
      profilePicture: profilePicture ?? this.profilePicture,
      lastMessage: lastMessage ?? this.lastMessage,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      participants: participants ?? this.participants,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      typingStatus: typingStatus ?? this.typingStatus,
      readStatus: readStatus ?? this.readStatus,
    );
  }
}

class Message {
  final String id;
  final String senderId;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;

  Message({
    required this.id,
    required this.senderId,
    required this.message,
    required this.timestamp,
    required this.isRead,
    this.type = MessageType.text,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == (data['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'type': type.toString().split('.').last,
    };
  }
}

enum MessageType { text, image, file }
