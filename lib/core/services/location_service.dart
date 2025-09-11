import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../model/location_data.dart';

class LocationService {
  // Nominatim is free OpenStreetMap geocoding service
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';

  // Get current user location
  Future<LatLng?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  // Reverse geocoding - get address from coordinates
  Future<LocationData?> getAddressFromCoordinates(LatLng coordinates) async {
    try {
      final url = Uri.parse(
        '$_nominatimBaseUrl/reverse?format=json&lat=${coordinates.latitude}&lon=${coordinates.longitude}&zoom=18&addressdetails=1',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['address'] != null) {
          final address = data['address'] as Map<String, dynamic>;

          // Extract relevant address components
          String city =
              address['city'] ??
              address['town'] ??
              address['village'] ??
              address['suburb'] ??
              '';

          String state = address['state'] ?? '';
          String country = address['country'] ?? '';

          // Debug: Print the country value to help troubleshoot
          print('Detected country: "$country"');
          print('Detected city: "$city"');
          print('Detected state: "$state"');
          print(
            'Coordinates: ${coordinates.latitude}, ${coordinates.longitude}',
          );

          // Check if location is in Malaysia
          // If country is provided and not Malaysia, reject
          // If country is empty/unclear, check if coordinates are within Malaysia bounds
          if (country.isNotEmpty && !_isMalaysia(country)) {
            print('Location rejected: Not in Malaysia (country: "$country")');
            return null;
          } else if (country.isEmpty && !_isWithinMalaysiaBounds(coordinates)) {
            print(
              'Location rejected: No country info and coordinates outside Malaysia bounds',
            );
            return null;
          }

          // Format the display address (City, State format)
          String displayAddress = '';
          if (city.isNotEmpty && state.isNotEmpty) {
            displayAddress = '$city, $state';
          } else if (city.isNotEmpty) {
            displayAddress = city;
          } else if (state.isNotEmpty) {
            displayAddress = state;
          } else {
            displayAddress = data['display_name'] ?? 'Unknown Location';
          }

          print('Location accepted: "$displayAddress"');

          return LocationData(
            coordinates: coordinates,
            address: displayAddress,
            city: city.isNotEmpty ? city : null,
            state: state.isNotEmpty ? state : null,
            country: country.isNotEmpty ? country : null,
          );
        } else {
          // Fallback: No address data, but check if coordinates are in Malaysia
          print('No address data available, checking coordinates...');
          if (_isWithinMalaysiaBounds(coordinates)) {
            print('Location accepted based on coordinates: Malaysia bounds');
            return LocationData(
              coordinates: coordinates,
              address: data['display_name'] ?? 'Malaysia',
              city: null,
              state: null,
              country: 'Malaysia',
            );
          } else {
            print('Location rejected: Coordinates outside Malaysia bounds');
            return null;
          }
        }
      }
    } catch (e) {
      print('Error in reverse geocoding: $e');
    }
    return null;
  }

  // Forward geocoding - get coordinates from address (for future search functionality)
  Future<List<LocationData>> searchLocations(String query) async {
    try {
      // Limit search to Malaysia
      final url = Uri.parse(
        '$_nominatimBaseUrl/search?format=json&q=$query&countrycodes=my&limit=5&addressdetails=1',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);

        List<LocationData> locations = [];

        for (var result in results) {
          final lat = double.tryParse(result['lat']?.toString() ?? '');
          final lon = double.tryParse(result['lon']?.toString() ?? '');

          if (lat != null && lon != null) {
            final address = result['address'] as Map<String, dynamic>?;

            String city =
                address?['city'] ??
                address?['town'] ??
                address?['village'] ??
                address?['suburb'] ??
                '';

            String state = address?['state'] ?? '';
            String country = address?['country'] ?? '';

            // Validate location is in Malaysia (same logic as reverse geocoding)
            final coordinates = LatLng(lat, lon);
            if (country.isNotEmpty && !_isMalaysia(country)) {
              continue; // Skip this result
            } else if (country.isEmpty &&
                !_isWithinMalaysiaBounds(coordinates)) {
              continue; // Skip this result
            }

            // Format display address
            String displayAddress = '';
            if (city.isNotEmpty && state.isNotEmpty) {
              displayAddress = '$city, $state';
            } else {
              displayAddress = result['display_name'] ?? 'Unknown Location';
            }

            locations.add(
              LocationData(
                coordinates: LatLng(lat, lon),
                address: displayAddress,
                city: city.isNotEmpty ? city : null,
                state: state.isNotEmpty ? state : null,
                country: country.isNotEmpty ? country : null,
              ),
            );
          }
        }

        return locations;
      }
    } catch (e) {
      print('Error searching locations: $e');
    }
    return [];
  }

  // Helper method to check if coordinates are within Malaysia's bounds
  bool _isWithinMalaysiaBounds(LatLng coordinates) {
    return coordinates.latitude >= malaysiaBounds.south &&
        coordinates.latitude <= malaysiaBounds.north &&
        coordinates.longitude >= malaysiaBounds.west &&
        coordinates.longitude <= malaysiaBounds.east;
  }

  // Helper method to check if the country represents Malaysia
  bool _isMalaysia(String country) {
    final countryLower = country.toLowerCase().trim();

    // List of possible country name variations for Malaysia
    const malaysiaVariations = [
      'malaysia',
      'مليسيا', // Arabic
      'my', // ISO country code
      'mys', // ISO 3-letter code
      'malaisie', // French
      'malasia', // Spanish
      'malásia', // Portuguese
      'малайзия', // Russian
      'マレーシア', // Japanese
      '말레이시아', // Korean
      '马来西亚', // Chinese Simplified
      '馬來西亞', // Chinese Traditional
    ];

    return malaysiaVariations.contains(countryLower);
  }

  // Malaysia bounds for map constraints
  static const LatLng malaysiaCenter = LatLng(4.2105, 101.9758);
  static final LatLngBounds malaysiaBounds = LatLngBounds(
    const LatLng(0.8539, 99.6404), // Southwest corner
    const LatLng(7.3534, 119.2670), // Northeast corner
  );
}
