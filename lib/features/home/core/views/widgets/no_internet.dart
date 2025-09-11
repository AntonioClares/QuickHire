import 'package:flutter/material.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/views/widgets/custom_loading_indicator.dart';

class NoInternet extends StatelessWidget {
  final bool isCheckingConnection;

  const NoInternet({super.key, this.isCheckingConnection = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/icons/no_internet.png',
            width: 100,
            height: 100,
            color: Palette.subtitle,
          ),
          const SizedBox(height: 24),
          Text(
            'No Internet Connection',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Palette.subtitle,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Please check your connection and pull to refresh',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Palette.subtitle.withValues(alpha: 0.7),
              ),
            ),
          ),
          if (isCheckingConnection) ...[
            const SizedBox(height: 24),
            const CustomLoadingIndicator(),
          ],
        ],
      ),
    );
  }
}
