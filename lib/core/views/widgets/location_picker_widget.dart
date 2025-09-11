import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/color_palette.dart';
import '../../model/location_data.dart';
import '../../viewmodels/location_picker_viewmodel.dart';
import '../../services/location_service.dart';
import 'custom_loading_indicator.dart';
import '../../../features/job_posting/views/pages/full_screen_location_picker_page.dart';

class LocationPickerWidget extends ConsumerStatefulWidget {
  final LocationData? initialLocation;
  final Function(LocationData) onLocationSelected;

  const LocationPickerWidget({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  ConsumerState<LocationPickerWidget> createState() =>
      _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends ConsumerState<LocationPickerWidget> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Set initial location if provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialLocation != null) {
        ref
            .read(locationPickerViewModelProvider.notifier)
            .setInitialLocation(widget.initialLocation);
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    // Clear any existing errors when user taps on map
    ref.read(locationPickerViewModelProvider.notifier).clearError();
    ref
        .read(locationPickerViewModelProvider.notifier)
        .selectLocationFromMap(point);
  }

  void _moveToCurrentLocation() {
    ref.read(locationPickerViewModelProvider.notifier).getCurrentLocation();
  }

  void _moveMapToLocation(LatLng location) {
    _mapController.move(location, 15.0);
  }

  Future<void> _openFullScreenPicker() async {
    final result = await Navigator.of(context).push<LocationData>(
      MaterialPageRoute(
        builder:
            (context) => FullScreenLocationPickerPage(
              initialLocation:
                  ref.read(locationPickerViewModelProvider).selectedLocation ??
                  widget.initialLocation,
            ),
      ),
    );

    if (result != null) {
      // Update the local state and notify parent
      ref
          .read(locationPickerViewModelProvider.notifier)
          .setInitialLocation(result);
      widget.onLocationSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(locationPickerViewModelProvider);

    // Listen for location changes to move map
    ref.listen<LocationPickerState>(locationPickerViewModelProvider, (
      previous,
      next,
    ) {
      if (next.currentUserLocation != null &&
          previous?.currentUserLocation != next.currentUserLocation) {
        _moveMapToLocation(next.currentUserLocation!);
      }

      if (next.selectedLocation != null &&
          previous?.selectedLocation != next.selectedLocation) {
        _moveMapToLocation(next.selectedLocation!.coordinates);
        // Notify parent about selection
        widget.onLocationSelected(next.selectedLocation!);
      }
    });

    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Map
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter:
                    widget.initialLocation?.coordinates ??
                    LocationService.malaysiaCenter,
                initialZoom: 10.0,
                minZoom: 6.0,
                maxZoom: 18.0,
                cameraConstraint: CameraConstraint.contain(
                  bounds: LocationService.malaysiaBounds,
                ),
                onTap: _handleMapTap,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                // Map tiles
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.quickhire.app',
                  maxZoom: 18,
                ),

                // Current user location marker
                if (state.currentUserLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: state.currentUserLocation!,
                        width: 20,
                        height: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),

                // Selected location marker
                if (state.selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: state.selectedLocation!.coordinates,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Palette.primary,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // Loading overlay for address resolution
            if (state.isLoadingAddress)
              Container(
                color: Colors.black26,
                child: const Center(child: CustomLoadingIndicator()),
              ),

            // Controls overlay
            Positioned(
              top: 12,
              right: 12,
              child: Column(
                children: [
                  // Expand to full screen button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.fullscreen,
                        color: Palette.primary,
                      ),
                      onPressed: _openFullScreenPicker,
                      tooltip: 'Expand map',
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Current location button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon:
                          state.isLoadingUserLocation
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Palette.primary,
                                ),
                              )
                              : const Icon(
                                Icons.my_location,
                                color: Palette.primary,
                              ),
                      onPressed:
                          state.isLoadingUserLocation
                              ? null
                              : _moveToCurrentLocation,
                      tooltip: 'Current location',
                    ),
                  ),
                ],
              ),
            ),

            // Selected location info
            if (state.selectedLocation != null)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Palette.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.selectedLocation!.address,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed:
                            () =>
                                ref
                                    .read(
                                      locationPickerViewModelProvider.notifier,
                                    )
                                    .clearSelectedLocation(),
                      ),
                    ],
                  ),
                ),
              ),

            // Error message
            if (state.error != null)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.error!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed:
                            () =>
                                ref
                                    .read(
                                      locationPickerViewModelProvider.notifier,
                                    )
                                    .clearError(),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
