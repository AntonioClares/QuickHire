import 'package:flutter/material.dart';
import 'package:quickhire/core/views/widgets/custom_loading_indicator.dart';

/// A loading overlay that darkens the background and displays a loading indicator
/// in a white container.
///
/// This component can be used across the app to show loading states.
class LoadingOverlay extends StatelessWidget {
  /// The widget to display in the center of the overlay.
  /// If null, a default CircularProgressIndicator will be shown.
  final Widget? loadingWidget;

  /// The color of the background overlay.
  /// Defaults to Colors.black.
  final Color backgroundColor;

  /// The size of the white container.
  /// Defaults to 100x100.
  final double containerSize;

  /// The border radius of the white container.
  /// Defaults to 16.
  final double borderRadius;

  const LoadingOverlay({
    super.key,
    this.loadingWidget,
    this.backgroundColor = Colors.black,
    this.containerSize = 100.0,
    this.borderRadius = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Darkened background overlay
        Positioned.fill(
          child: Container(color: backgroundColor.withAlpha(100)),
        ),

        // Centered white container with loading indicator
        Center(
          child: Container(
            width: containerSize,
            height: containerSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: loadingWidget ?? const CustomLoadingIndicator(),
            ),
          ),
        ),
      ],
    );
  }
}
