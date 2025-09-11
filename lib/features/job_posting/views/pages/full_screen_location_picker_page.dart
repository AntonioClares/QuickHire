import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:quickhire/core/model/location_data.dart';
import 'package:quickhire/core/services/location_service.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/views/widgets/custom_loading_indicator.dart';
import 'package:quickhire/core/viewmodels/location_picker_viewmodel.dart';

class FullScreenLocationPickerPage extends ConsumerStatefulWidget {
  final LocationData? initialLocation;

  const FullScreenLocationPickerPage({super.key, this.initialLocation});

  @override
  ConsumerState<FullScreenLocationPickerPage> createState() =>
      _FullScreenLocationPickerPageState();
}

class _FullScreenLocationPickerPageState
    extends ConsumerState<FullScreenLocationPickerPage> {
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

  void _confirmSelection() {
    final selectedLocation =
        ref.read(locationPickerViewModelProvider).selectedLocation;
    if (selectedLocation != null) {
      context.pop(selectedLocation);
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
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Header section that matches account information page
          SliverAppBar(
            expandedHeight: 160.0,
            backgroundColor: Palette.primary,
            pinned: false,
            floating: false,
            snap: false,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(color: Palette.primary),
                child: SafeArea(
                  child: Stack(
                    children: [
                      // Back button
                      Positioned(
                        top: 10,
                        left: 16,
                        child: GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                color: Color(0xFF5E616F),
                                size: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Header texts - centered and responsive
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 35,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Select Location',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width < 350
                                        ? 26
                                        : 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap on the map to choose your job location',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width < 350
                                        ? 14
                                        : 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Map content
          SliverFillRemaining(
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
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
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
                  top: 16,
                  right: 16,
                  child: Column(
                    children: [
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
                        ),
                      ),
                    ],
                  ),
                ),

                // Selected location info
                if (state.selectedLocation != null)
                  Positioned(
                    bottom: 100, // Leave space for confirm button
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selected Location',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF5E616F),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // Error message
                if (state.error != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              state.error!,
                              style: TextStyle(
                                fontSize: 14,
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
                                          locationPickerViewModelProvider
                                              .notifier,
                                        )
                                        .clearError(),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Confirm button with SafeArea bottom padding
                if (state.selectedLocation != null)
                  Positioned(
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                    left: 16,
                    right: 16,
                    child: ElevatedButton(
                      onPressed: _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.primary,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm Location',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
