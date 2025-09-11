import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/features/notifications/services/notification_service.dart';

class AnimatedHeader extends StatelessWidget {
  final bool isVisible;
  final double height;
  final String userName;
  final bool isLoading;
  final VoidCallback? onNotificationTap;

  const AnimatedHeader({
    super.key,
    required this.isVisible,
    required this.height,
    required this.userName,
    required this.isLoading,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          height: isVisible ? height : 0,
          width: double.infinity,
          color: Palette.primary,
        ),
        AnimatedSlide(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          offset: isVisible ? Offset.zero : const Offset(0, -1),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        "Welcome,",
                        style: TextStyle(fontSize: 16, color: Palette.white),
                      ),
                      Skeletonizer(
                        enabled: isLoading,
                        child: Text(
                          userName,
                          style: TextStyle(
                            fontSize: 32,
                            color: Palette.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: GestureDetector(
                      onTap: onNotificationTap,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Palette.white.withAlpha(60),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Stack(
                          children: [
                            const Center(
                              child: Icon(
                                Icons.notifications_outlined,
                                color: Palette.white,
                              ),
                            ),
                            StreamBuilder<int>(
                              stream:
                                  NotificationService.getUnreadCountStream(),
                              builder: (context, snapshot) {
                                final unreadCount = snapshot.data ?? 0;
                                if (unreadCount == 0) {
                                  return const SizedBox.shrink();
                                }

                                return Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 20,
                                      minHeight: 20,
                                    ),
                                    child: Text(
                                      unreadCount > 99 ? '99+' : '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
