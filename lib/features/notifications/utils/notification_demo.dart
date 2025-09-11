import 'package:flutter/material.dart';
import 'package:quickhire/features/notifications/services/notification_service.dart';
import 'package:quickhire/features/notifications/models/notification_model.dart';

/// Demo utility for testing notifications in development
/// This should be removed in production
class NotificationDemo {
  static Future<void> createTestNotifications() async {
    try {
      // Demo job application notification
      await NotificationService.createNotification(
        userId: 'demo-employer-id',
        type: NotificationType.jobApplication,
        title: 'New Job Application',
        message: 'John Doe has applied for your Flutter Developer position',
        data: {
          'jobId': 'demo-job-id',
          'applicationId': 'demo-app-id',
          'applicantName': 'John Doe',
        },
      );

      // Demo message notification
      await NotificationService.createNotification(
        userId: 'demo-user-id',
        type: NotificationType.newMessage,
        title: 'New Message',
        message: 'Sarah: Hi, I\'m interested in discussing the position...',
        data: {'conversationId': 'demo-conversation-id', 'senderName': 'Sarah'},
      );

      // Demo application accepted notification
      await NotificationService.createNotification(
        userId: 'demo-applicant-id',
        type: NotificationType.applicationAccepted,
        title: 'Application Accepted!',
        message:
            'Congratulations! Your application for Senior Developer has been accepted.',
        data: {
          'jobId': 'demo-job-id-2',
          'applicationId': 'demo-app-id-2',
          'jobTitle': 'Senior Developer',
        },
      );

      print('Demo notifications created successfully!');
    } catch (e) {
      print('Error creating demo notifications: $e');
    }
  }

  static Widget buildDemoButton() {
    return FloatingActionButton(
      onPressed: createTestNotifications,
      child: const Icon(Icons.notifications_active),
      backgroundColor: Colors.orange,
    );
  }
}
