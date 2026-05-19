import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/provider.dart';

/// Utility service for Google Maps integration.
class MapService {
  // Default fallback: Karachi city centre
  static const LatLng kDefaultCenter = LatLng(24.8607, 67.0011);

  // Category → BitmapDescriptor hue mapping (Sahulat Oasis palette)
  static final Map<String, double> _categoryHues = {
    'electrician':   BitmapDescriptor.hueGreen,    // Forest Emerald
    'plumber':       BitmapDescriptor.hueCyan,      // Azure
    'ac_repair':     BitmapDescriptor.hueOrange,    // Amber/Terracotta
    'ac repair':     BitmapDescriptor.hueOrange,
    'tutor':         BitmapDescriptor.hueViolet,    // Purple
    'cleaning':      BitmapDescriptor.hueYellow,
  };

  /// Request location permission and return the current position, or null.
  static Future<LatLng?> getUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  /// Build a [Set<Marker>] for the given list of providers.
  /// [onTap] is called with the tapped provider.
  static Set<Marker> buildProviderMarkers(
    List<ServiceProvider> providers,
    void Function(ServiceProvider) onTap,
  ) {
    final markers = <Marker>{};
    for (final provider in providers) {
      final latLng = provider.resolvedLatLng;
      if (latLng == null) continue;

      final hue = _categoryHues[provider.serviceType.toLowerCase()] ??
          BitmapDescriptor.hueRed;

      markers.add(Marker(
        markerId: MarkerId(provider.id.isEmpty ? provider.name : provider.id),
        position: latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        infoWindow: InfoWindow(
          title: provider.name,
          snippet: '⭐ ${provider.rating}  •  Rs.${provider.pricePerHour}/hr',
        ),
        onTap: () => onTap(provider),
      ));
    }
    return markers;
  }

  /// Load a custom map style JSON from assets based on [themeMode].
  static Future<String> loadMapStyle(ThemeMode themeMode, BuildContext context) async {
    final brightness = themeMode == ThemeMode.system
        ? MediaQuery.platformBrightnessOf(context)
        : (themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light);

    final asset = brightness == Brightness.dark
        ? 'assets/map_style_dark.json'
        : 'assets/map_style_light.json';
    return rootBundle.loadString(asset);
  }

  /// Compute a [LatLngBounds] that contains all provider markers.
  /// Returns null if no providers have resolved positions.
  static LatLngBounds? computeBounds(List<ServiceProvider> providers) {
    final points = providers
        .map((p) => p.resolvedLatLng)
        .whereType<LatLng>()
        .toList();

    if (points.isEmpty) return null;
    if (points.length == 1) {
      final p = points.first;
      return LatLngBounds(
        southwest: LatLng(p.latitude - 0.01, p.longitude - 0.01),
        northeast: LatLng(p.latitude + 0.01, p.longitude + 0.01),
      );
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat - 0.005, minLng - 0.005),
      northeast: LatLng(maxLat + 0.005, maxLng + 0.005),
    );
  }

  /// Return a human-readable category label.
  static String categoryLabel(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'electrician': return 'Electrician';
      case 'plumber':     return 'Plumber';
      case 'ac_repair':
      case 'ac repair':  return 'AC Repair';
      case 'tutor':       return 'Tutor';
      case 'cleaning':    return 'Cleaning';
      default:            return serviceType;
    }
  }
}
