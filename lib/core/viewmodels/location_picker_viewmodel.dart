import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../model/location_data.dart';
import '../services/location_service.dart';

// Provider for LocationService
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

// State for location picker
class LocationPickerState {
  final LocationData? selectedLocation;
  final LatLng? currentUserLocation;
  final bool isLoadingUserLocation;
  final bool isLoadingAddress;
  final String? error;

  const LocationPickerState({
    this.selectedLocation,
    this.currentUserLocation,
    this.isLoadingUserLocation = false,
    this.isLoadingAddress = false,
    this.error,
  });

  LocationPickerState copyWith({
    LocationData? selectedLocation,
    LatLng? currentUserLocation,
    bool? isLoadingUserLocation,
    bool? isLoadingAddress,
    String? error,
    bool clearError = false,
  }) {
    return LocationPickerState(
      selectedLocation: selectedLocation ?? this.selectedLocation,
      currentUserLocation: currentUserLocation ?? this.currentUserLocation,
      isLoadingUserLocation:
          isLoadingUserLocation ?? this.isLoadingUserLocation,
      isLoadingAddress: isLoadingAddress ?? this.isLoadingAddress,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ViewModel for location picker
class LocationPickerViewModel extends StateNotifier<LocationPickerState> {
  final LocationService _locationService;

  LocationPickerViewModel(this._locationService)
    : super(const LocationPickerState());

  // Get user's current location
  Future<void> getCurrentLocation() async {
    if (state.isLoadingUserLocation) return;

    state = state.copyWith(isLoadingUserLocation: true, error: null);

    try {
      final location = await _locationService.getCurrentLocation();
      if (location != null) {
        state = state.copyWith(
          currentUserLocation: location,
          isLoadingUserLocation: false,
        );
      } else {
        state = state.copyWith(
          error: 'Unable to get your current location',
          isLoadingUserLocation: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Error getting location: ${e.toString()}',
        isLoadingUserLocation: false,
      );
    }
  }

  // Handle map tap to select location
  Future<void> selectLocationFromMap(LatLng coordinates) async {
    if (state.isLoadingAddress) return;

    state = state.copyWith(isLoadingAddress: true, clearError: true);

    try {
      final locationData = await _locationService.getAddressFromCoordinates(
        coordinates,
      );
      if (locationData != null) {
        state = state.copyWith(
          selectedLocation: locationData,
          isLoadingAddress: false,
        );
      } else {
        state = state.copyWith(
          error:
              'Unable to get address for this location. Please select a location within Malaysia.',
          isLoadingAddress: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Error getting address: ${e.toString()}',
        isLoadingAddress: false,
      );
    }
  }

  // Clear selected location
  void clearSelectedLocation() {
    state = state.copyWith(selectedLocation: null);
  }

  // Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // Reset all state when page is disposed
  void reset() {
    try {
      state = const LocationPickerState();
    } catch (e) {
      // Ignore errors if state is no longer available
    }
  }

  // Set initial location if editing existing job
  void setInitialLocation(LocationData? location) {
    state = state.copyWith(selectedLocation: location);
  }
}

// Provider for the ViewModel
final locationPickerViewModelProvider = StateNotifierProvider.autoDispose<
  LocationPickerViewModel,
  LocationPickerState
>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return LocationPickerViewModel(locationService);
});
