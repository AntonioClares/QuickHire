import 'package:flutter/material.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/features/notifications/models/notification_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      onDismissed: (_) => onDismiss(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                notification.isRead
                    ? Palette.white
                    : Palette.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  notification.isRead
                      ? Colors.grey.shade200
                      : Palette.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getIconBackgroundColor(),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(_getIconData(), color: _getIconColor(), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  notification.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Palette.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeago.format(notification.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData() {
    switch (notification.type) {
      case NotificationType.jobApplication:
        return Icons.work_outline;
      case NotificationType.newMessage:
        return Icons.message_outlined;
      case NotificationType.applicationStatusUpdate:
        return Icons.update_outlined;
      case NotificationType.jobPosted:
        return Icons.post_add_outlined;
      case NotificationType.applicationAccepted:
        return Icons.check_circle_outline;
      case NotificationType.applicationRejected:
        return Icons.cancel_outlined;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case NotificationType.jobApplication:
        return Palette.primary;
      case NotificationType.newMessage:
        return Colors.blue;
      case NotificationType.applicationStatusUpdate:
        return Colors.orange;
      case NotificationType.jobPosted:
        return Colors.green;
      case NotificationType.applicationAccepted:
        return Colors.green;
      case NotificationType.applicationRejected:
        return Colors.red;
    }
  }

  Color _getIconBackgroundColor() {
    switch (notification.type) {
      case NotificationType.jobApplication:
        return Palette.primary.withOpacity(0.1);
      case NotificationType.newMessage:
        return Colors.blue.withOpacity(0.1);
      case NotificationType.applicationStatusUpdate:
        return Colors.orange.withOpacity(0.1);
      case NotificationType.jobPosted:
        return Colors.green.withOpacity(0.1);
      case NotificationType.applicationAccepted:
        return Colors.green.withOpacity(0.1);
      case NotificationType.applicationRejected:
        return Colors.red.withOpacity(0.1);
    }
  }
}
