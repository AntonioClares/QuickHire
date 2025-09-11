import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  jobApplication,
  newMessage,
  applicationStatusUpdate,
  jobPosted,
  applicationAccepted,
  applicationRejected,
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => NotificationType.jobApplication,
      ),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.toString(),
      'title': title,
      'message': message,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

extension NotificationTypeExtension on NotificationType {
  String get icon {
    switch (this) {
      case NotificationType.jobApplication:
        return 'work';
      case NotificationType.newMessage:
        return 'message';
      case NotificationType.applicationStatusUpdate:
        return 'update';
      case NotificationType.jobPosted:
        return 'post';
      case NotificationType.applicationAccepted:
        return 'check';
      case NotificationType.applicationRejected:
        return 'close';
    }
  }

  String get displayName {
    switch (this) {
      case NotificationType.jobApplication:
        return 'Job Application';
      case NotificationType.newMessage:
        return 'New Message';
      case NotificationType.applicationStatusUpdate:
        return 'Application Update';
      case NotificationType.jobPosted:
        return 'Job Posted';
      case NotificationType.applicationAccepted:
        return 'Application Accepted';
      case NotificationType.applicationRejected:
        return 'Application Rejected';
    }
  }
}
