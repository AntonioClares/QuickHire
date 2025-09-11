import 'package:flutter/material.dart';
import 'package:quickhire/core/theme/color_palette.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final int? width;
  final int? height;
  final bool transparent;
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = Palette.primary,
    this.foregroundColor = Palette.white,
    this.transparent = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width?.toDouble() ?? 330,
      height: height?.toDouble() ?? 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          shadowColor: WidgetStateProperty.all(Palette.transparent),
          backgroundColor: WidgetStateProperty.all(backgroundColor),
          foregroundColor: WidgetStateProperty.all(foregroundColor),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          overlayColor:
              transparent ? WidgetStateProperty.all(Palette.transparent) : null,
        ),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
