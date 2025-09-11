import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'location_data.dart';

class JobListing {
  final String id;
  final String posterUid;
  final DateTime createdAt;
  final String description;
  final bool isActive;
  final String location; // Keep for backward compatibility
  final LocationData?
  locationData; // New field for coordinates and structured address
  final String payment;
  final List<String> tags;
  final String title;
  final String type;
  final DateTime updatedAt;

  JobListing({
    required this.id,
    required this.posterUid,
    required this.createdAt,
    required this.description,
    required this.isActive,
    required this.location,
    this.locationData,
    required this.payment,
    required this.tags,
    required this.title,
    required this.type,
    required this.updatedAt,
  });

  factory JobListing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse location data if available
    LocationData? locationData;
    if (data['location_data'] != null) {
      try {
        locationData = LocationData.fromJson(
          data['location_data'] as Map<String, dynamic>,
        );
      } catch (e) {
        print('Error parsing location data: $e');
      }
    }

    return JobListing(
      id: doc.id,
      posterUid: data['poster_uid'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      description: data['description'] ?? '',
      isActive: data['isActive'] ?? true,
      location: data['location'] ?? '',
      locationData: locationData,
      payment: data['payment'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      title: data['title'] ?? '',
      type: data['type'] ?? '',
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final data = {
      'poster_uid': posterUid,
      'createdAt': Timestamp.fromDate(createdAt),
      'description': description,
      'isActive': isActive,
      'location': location,
      'payment': payment,
      'tags': tags,
      'title': title,
      'type': type,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };

    // Add location data if available
    if (locationData != null) {
      data['location_data'] = locationData!.toJson();
    }

    return data;
  }

  // Helper method to get display location
  String get displayLocation => locationData?.address ?? location;

  // Helper method to get coordinates if available
  LatLng? get coordinates => locationData?.coordinates;
}
