import 'package:flutter/material.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/views/widgets/custom_loading_indicator.dart';
import 'package:quickhire/features/notifications/models/notification_model.dart';
import 'package:quickhire/features/notifications/services/notification_service.dart';
import 'package:quickhire/features/notifications/views/widgets/notification_item.dart';
import 'package:quickhire/core/navigation/views/widgets/custom_dialog.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final headerHeight = size.height * 0.195;

    return Scaffold(
      backgroundColor: Palette.background,
      body: CustomScrollView(
        slivers: [
          // Header section
          SliverAppBar(
            expandedHeight: headerHeight,
            backgroundColor: Palette.primary,
            pinned: false,
            floating: false,
            snap: false,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(color: Palette.primary),
                child: SafeArea(
                  child: Stack(
                    children: [
                      // Back button
                      Positioned(
                        top: 10,
                        left: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                color: Color(0xFF5E616F),
                                size: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Header texts - centered and responsive
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 35,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Notifications',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: size.width < 350 ? 26 : 30,
                                fontWeight: FontWeight.bold,
                                color: Palette.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Stay updated with your activities',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: size.width < 350 ? 14 : 16,
                                    color: Palette.white.withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StreamBuilder<List<NotificationModel>>(
                                  stream:
                                      NotificationService.getNotificationsStream(),
                                  builder: (context, snapshot) {
                                    final hasUnread =
                                        snapshot.hasData &&
                                        snapshot.data!.any(
                                          (notification) =>
                                              !notification.isRead,
                                        );

                                    if (!hasUnread)
                                      return const SizedBox.shrink();

                                    return GestureDetector(
                                      onTap: _markAllAsRead,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Palette.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Text(
                                          'Mark all read',
                                          style: TextStyle(
                                            color: Palette.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Container(
              color: Palette.background,
              child: StreamBuilder<List<NotificationModel>>(
                stream: NotificationService.getNotificationsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(50.0),
                      child: Center(child: CustomLoadingIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(50.0),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading notifications',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please try again later',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final notifications = snapshot.data ?? [];

                  if (notifications.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(50.0),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You\'ll see notifications here when you have them',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder:
                        (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return NotificationItem(
                        notification: notification,
                        onTap: () => _onNotificationTap(notification),
                        onDismiss: () => _onNotificationDismiss(notification),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    try {
      await NotificationService.markAllAsRead();
    } catch (e) {
      if (mounted) {
        CustomDialog.show(
          context: context,
          title: 'Error',
          message: 'Failed to mark notifications as read',
          icon: Icons.error_outline,
          iconColor: Colors.red,
          buttonText: 'OK',
        );
      }
    }
  }

  Future<void> _onNotificationTap(NotificationModel notification) async {
    // Mark as read if not already read
    if (!notification.isRead) {
      await NotificationService.markAsRead(notification.id);
    }

    // Handle navigation based on notification type
    switch (notification.type) {
      case NotificationType.jobApplication:
      case NotificationType.applicationStatusUpdate:
      case NotificationType.applicationAccepted:
      case NotificationType.applicationRejected:
        // Navigate to job details or applications page
        // Implementation depends on your routing structure
        break;
      case NotificationType.newMessage:
        // Navigate to message conversation
        // final conversationId = notification.data['conversationId'];
        // context.push('/messages/$conversationId');
        break;
      case NotificationType.jobPosted:
        // Navigate to job details
        break;
    }
  }

  Future<void> _onNotificationDismiss(NotificationModel notification) async {
    try {
      await NotificationService.deleteNotification(notification.id);
    } catch (e) {
      if (mounted) {
        CustomDialog.show(
          context: context,
          title: 'Error',
          message: 'Failed to dismiss notification',
          icon: Icons.error_outline,
          iconColor: Colors.red,
          buttonText: 'OK',
        );
      }
    }
  }
}
