import 'package:flutter/material.dart';
import 'package:quickhire/core/theme/color_palette.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final Function()? onButtonPressed;
  final Function()? onDismissed;
  final IconData icon;
  final Color iconColor;

  const CustomDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = "OK",
    this.onButtonPressed,
    this.onDismissed,
    this.icon = Icons.error_outline,
    this.iconColor = Colors.red,
  });

  static void show({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = "OK",
    Function()? onButtonPressed,
    Function()? onDismissed,
    IconData icon = Icons.error_outline,
    Color iconColor = Colors.red,
  }) {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => CustomDialog(
            title: title,
            message: message,
            buttonText: buttonText,
            onButtonPressed: onButtonPressed,
            onDismissed: onDismissed,
            icon: icon,
            iconColor: iconColor,
          ),
      barrierDismissible: true,
    ).then((_) {
      if (onDismissed != null) {
        onDismissed();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (onDismissed != null) {
          onDismissed!();
        }
        return true;
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: contentBox(context),
      ),
    );
  }

  Widget contentBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon at the top
          Icon(icon, color: iconColor, size: 48),
          const SizedBox(height: 16),

          // Title
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Message
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: Color(0xFF5E616F)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Button
          ElevatedButton(
            onPressed: () {
              if (onButtonPressed != null) {
                onButtonPressed!();
              } else {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.primary,
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
