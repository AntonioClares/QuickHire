import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/color_palette.dart';
import '../../model/location_data.dart';

class StaticMapWidget extends StatelessWidget {
  final LocationData? locationData;
  final String fallbackAddress;
  final double height;

  const StaticMapWidget({
    super.key,
    this.locationData,
    required this.fallbackAddress,
    this.height = 200,
  });

  Future<void> _openInMaps() async {
    // Check if we have valid coordinates
    if (locationData?.coordinates != null) {
      final lat = locationData!.coordinates.latitude;
      final lng = locationData!.coordinates.longitude;

      List<String> mapUrls = [];

      if (Platform.isAndroid) {
        // Android-specific URLs with better coordinate handling
        mapUrls = [
          // Google Maps with coordinates (Android prefers this format)
          'geo:$lat,$lng?q=$lat,$lng',
          // Google Maps web fallback with coordinates only
          'https://maps.google.com/?q=$lat,$lng',
          // Intent-based Google Maps (Android specific)
          'https://maps.google.com/maps?daddr=$lat,$lng',
        ];
      } else if (Platform.isIOS) {
        // iOS-specific URLs
        mapUrls = [
          // Apple Maps (iOS native)
          'https://maps.apple.com/?q=$lat,$lng',
          // Google Maps for iOS
          'https://maps.google.com/?q=$lat,$lng',
        ];
      } else {
        // Web/other platforms fallback
        mapUrls = [
          'https://maps.google.com/?q=$lat,$lng',
          'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng&zoom=15',
        ];
      }

      bool launched = false;
      for (String url in mapUrls) {
        try {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            launched = true;
            break;
          }
        } catch (e) {
          continue;
        }
      }

      if (!launched) {
        // Last resort: use coordinate-based search instead of address
        try {
          final coordinateSearch =
              Platform.isAndroid
                  ? 'geo:$lat,$lng?q=$lat,$lng'
                  : 'https://maps.apple.com/?q=$lat,$lng';
          final uri = Uri.parse(coordinateSearch);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          // Final fallback to address search
          _openByAddressSearch();
        }
      }
    } else {
      // Fallback when no coordinates available - search by address
      _openByAddressSearch();
    }
  }

  Future<void> _openByAddressSearch() async {
    try {
      final address = Uri.encodeComponent(
        locationData?.address ?? fallbackAddress,
      );

      String searchUrl;
      if (Platform.isAndroid) {
        // Use geo: scheme for Android when possible
        searchUrl = 'geo:0,0?q=$address';
      } else {
        // Use web URLs for iOS and other platforms
        searchUrl = 'https://maps.google.com/maps?q=$address';
      }

      final uri = Uri.parse(searchUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Do nothing if launch fails
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we have valid coordinates AND valid address
    if (locationData?.coordinates == null ||
        locationData?.address == null ||
        locationData!.address.isEmpty) {
      // Show fallback when no coordinates available
      return _buildFallbackWidget();
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Static map
            FlutterMap(
              options: MapOptions(
                initialCenter: locationData!.coordinates,
                initialZoom: 15.0,
                // Disable all interactions
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                // Map tiles
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.quickhire.app',
                ),

                // Location marker
                MarkerLayer(
                  markers: [
                    Marker(
                      point: locationData!.coordinates,
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

            // Overlay with tap to open in maps
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openInMaps,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

            // "Open in Maps" button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: _openInMaps,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new, size: 14, color: Palette.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Open',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Palette.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Address overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  locationData!.address,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackWidget() {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Palette.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: () => _openByAddressSearch(),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, color: Palette.primary, size: 48),
              const SizedBox(height: 8),
              Text(
                fallbackAddress,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Palette.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_new, size: 14, color: Palette.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Open in Maps',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Palette.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
