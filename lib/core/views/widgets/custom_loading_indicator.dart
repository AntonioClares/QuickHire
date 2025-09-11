import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:quickhire/core/theme/color_palette.dart';

/// A custom loading indicator for the application.
///
/// This widget can be easily replaced with an animated GIF or custom animation
/// in the future, while maintaining the same interface.
class CustomLoadingIndicator extends StatelessWidget {
  /// The size of the loading indicator.
  /// Defaults to 40.0.
  final double size;

  /// The color of the loading indicator.
  /// Defaults to Palette.primary.
  final Color color;

  /// The stroke width of the loading indicator.
  /// Defaults to 4.0.
  final double strokeWidth;

  const CustomLoadingIndicator({
    super.key,
    this.size = 40.0,
    this.color = Palette.primary,
    this.strokeWidth = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background logo
          Image.asset(
            'assets/images/app_logo_bag.png',
            width: size * 1.2,
            height: size * 1.2,
          ),
          // Loading animation moved down a bit
          Positioned(
            top: size * 0.10, // Moves animation down by 15% of the size
            child: Lottie.asset(
              'assets/animations/loading_animation.json',
              width: size,
              height: size,
            ),
          ),
        ],
      ),
    );
  }
}
