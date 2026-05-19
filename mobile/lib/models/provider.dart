import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ServiceProvider {
  final String id;
  final String name;
  final String serviceType;
  final String location;
  final double rating;
  final int pricePerHour;
  final bool availability;
  final double distance;
  // Optional lat/lng from backend (future-proof)
  final double? latitude;
  final double? longitude;

  ServiceProvider({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.location,
    required this.rating,
    required this.pricePerHour,
    required this.availability,
    required this.distance,
    this.latitude,
    this.longitude,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      serviceType: json['service_type'] ?? '',
      location: json['location'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      pricePerHour: json['price_per_hour'] ?? 0,
      availability: json['availability'] ?? false,
      distance: (json['distance'] ?? 0.0).toDouble(),
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
    );
  }

  /// Resolve the best available LatLng for this provider.
  /// Uses explicit lat/lng from backend if present, otherwise falls back to
  /// the client-side neighbourhood lookup for demo/mock data.
  LatLng? get resolvedLatLng {
    if (latitude != null && longitude != null) {
      return LatLng(latitude!, longitude!);
    }
    return _locationLookup[location.trim()];
  }

  /// Compute distance between two coordinates in kilometers using Haversine algorithm.
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 + 
              cos(lat1 * p) * cos(lat2 * p) * 
              (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Get the closest registered neighborhood to the user's lat/lng.
  static String getClosestNeighborhood(double userLat, double userLng) {
    String closestName = 'Clifton, Karachi'; // fallback
    double minDistance = double.infinity;

    _locationLookup.forEach((name, coords) {
      if (name == 'Karachi' || name == 'Islamabad' || name == 'Lahore' || name == 'Rawalpindi') {
        // Skip broad city fallbacks to prefer specific neighborhoods
        return;
      }
      final distance = calculateDistance(userLat, userLng, coords.latitude, coords.longitude);
      if (distance < minDistance) {
        minDistance = distance;
        closestName = name;
      }
    });

    return closestName;
  }

  /// Get LatLng coordinates for a specific neighborhood name.
  static LatLng getNeighborhoodLatLng(String name) {
    return _locationLookup[name.trim()] ?? const LatLng(24.8112, 67.0267); // Clifton Karachi default fallback
  }

  /// Client-side neighbourhood → LatLng lookup for Karachi & Islamabad.
  /// Used as a fallback when the backend doesn't return explicit coordinates.
  static final Map<String, LatLng> _locationLookup = {
    // Karachi
    'DHA, Karachi':                LatLng(24.7956, 67.0671),
    'DHA Phase 6, Karachi':        LatLng(24.7892, 67.0750),
    'Gulshan-e-Iqbal, Karachi':    LatLng(24.9136, 67.0977),
    'Johar, Karachi':              LatLng(24.9215, 67.1246),
    'North Nazimabad, Karachi':    LatLng(24.9440, 67.0397),
    'Clifton, Karachi':            LatLng(24.8112, 67.0267),
    'Saddar, Karachi':             LatLng(24.8607, 67.0104),
    'Karachi':                     LatLng(24.8607, 67.0011),
    // Islamabad / Rawalpindi
    'G-13':                        LatLng(33.6995, 72.9697),
    'G-13, Islamabad':             LatLng(33.6995, 72.9697),
    'F-10, Islamabad':             LatLng(33.7099, 73.0218),
    'F-7, Islamabad':              LatLng(33.7255, 73.0589),
    'Blue Area, Islamabad':        LatLng(33.7156, 73.0691),
    'Islamabad':                   LatLng(33.6844, 73.0479),
    'Rawalpindi':                  LatLng(33.5651, 73.0169),
    // Lahore
    'DHA, Lahore':                 LatLng(31.4720, 74.3936),
    'Gulberg, Lahore':             LatLng(31.5120, 74.3478),
    'Lahore':                      LatLng(31.5497, 74.3436),
  };
}
