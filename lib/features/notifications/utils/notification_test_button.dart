import 'package:flutter/material.dart';
import 'package:quickhire/features/notifications/views/pages/notifications_page.dart';

/// Simple test widget to verify notification navigation works
/// This can be temporarily added to the employer home page to test
class NotificationTestButton extends StatelessWidget {
  const NotificationTestButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100,
      right: 20,
      child: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.orange,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificationsPage()),
          );
        },
        child: const Icon(Icons.notifications, color: Colors.white),
      ),
    );
  }
}
