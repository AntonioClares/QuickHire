import 'package:flutter/material.dart';
import 'package:quickhire/core/views/widgets/custom_loading_indicator.dart';
import 'package:quickhire/core/views/widgets/loading_overlay.dart';

/// Service to manage loading states throughout the app.

class LoadingService {
  /// Private constructor to prevent instantiation (Singleton)

  LoadingService._();

  /// Shows a loading overlay on top of the current screen.
  ///
  /// Returns a function that can be called to hide the overlay.

  static Future<void> Function() showLoading(
    BuildContext context, {
    Widget? loadingWidget,
    bool barrierDismissible = false,
  }) {
    // Create an overlay entry
    final OverlayState overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder:
          (context) => WillPopScope(
            onWillPop: () async => barrierDismissible,
            child: LoadingOverlay(
              loadingWidget: loadingWidget ?? const CustomLoadingIndicator(),
            ),
          ),
    );

    // Add the overlay entry to the overlay
    overlayState.insert(overlayEntry);

    // Return a function to hide the overlay
    return () async {
      overlayEntry.remove();
    };
  }

  /// Utility method to show loading during an async operation.
  ///
  /// Example usage:
  ///
  /// await LoadingService.runWithLoading(
  ///   context,
  ///   () => yourAsyncOperation(),
  /// );
  ///

  static Future<T> runWithLoading<T>(
    BuildContext context,
    Future<T> Function() asyncOperation, {
    Widget? loadingWidget,
  }) async {
    final hideLoading = showLoading(context, loadingWidget: loadingWidget);

    try {
      final result = await asyncOperation();
      hideLoading();
      return result;
    } catch (e) {
      hideLoading();
      rethrow;
    }
  }
}
