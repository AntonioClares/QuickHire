import 'package:latlong2/latlong.dart';

class LocationData {
  final LatLng coordinates;
  final String address;
  final String? city;
  final String? state;
  final String? country;

  const LocationData({
    required this.coordinates,
    required this.address,
    this.city,
    this.state,
    this.country,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      coordinates: LatLng(
        json['coordinates']['latitude'] as double,
        json['coordinates']['longitude'] as double,
      ),
      address: json['address'] as String,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coordinates': {
        'latitude': coordinates.latitude,
        'longitude': coordinates.longitude,
      },
      'address': address,
      'city': city,
      'state': state,
      'country': country,
    };
  }

  @override
  String toString() => address;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationData &&
          runtimeType == other.runtimeType &&
          coordinates == other.coordinates &&
          address == other.address;

  @override
  int get hashCode => coordinates.hashCode ^ address.hashCode;
}
