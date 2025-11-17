import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

/// LocationService handles all location-related operations
/// including permissions, location fetching, and geofencing
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permissions
  /// Returns true if permission is granted
  Future<bool> requestLocationPermission() async {
    try {
      // Check current permission status
      final status = await Permission.location.status;

      if (status.isGranted) {
        return true;
      }

      // Request permission
      final result = await Permission.location.request();

      if (kDebugMode) {
        print('📍 Location permission result: $result');
      }

      return result.isGranted;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error requesting location permission: $e');
      }
      return false;
    }
  }

  /// Request background location permission (required for geofencing)
  Future<bool> requestBackgroundLocationPermission() async {
    try {
      // First ensure foreground location permission is granted
      final foregroundGranted = await requestLocationPermission();
      if (!foregroundGranted) {
        return false;
      }

      // Check current background permission status
      final status = await Permission.locationAlways.status;

      if (status.isGranted) {
        return true;
      }

      // Request background permission
      final result = await Permission.locationAlways.request();

      if (kDebugMode) {
        print('📍 Background location permission result: $result');
      }

      return result.isGranted;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error requesting background location permission: $e');
      }
      return false;
    }
  }

  /// Get current location
  /// Returns Position if successful, null otherwise
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          print('❌ Location services are disabled');
        }
        return null;
      }

      // Check permission
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        if (kDebugMode) {
          print('❌ Location permission denied');
        }
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (kDebugMode) {
        print('📍 Current location: ${position.latitude}, ${position.longitude}');
      }

      return position;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting current location: $e');
      }
      return null;
    }
  }

  /// Get address from coordinates (reverse geocoding)
  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        return null;
      }

      final place = placemarks.first;
      final addressParts = <String>[];

      if (place.name != null && place.name!.isNotEmpty) {
        addressParts.add(place.name!);
      }
      if (place.locality != null && place.locality!.isNotEmpty) {
        addressParts.add(place.locality!);
      }
      if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
        addressParts.add(place.administrativeArea!);
      }

      final address = addressParts.join(', ');

      if (kDebugMode) {
        print('📍 Address: $address');
      }

      return address.isNotEmpty ? address : null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting address from coordinates: $e');
      }
      return null;
    }
  }

  /// Get coordinates from address (geocoding)
  Future<Location?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);

      if (locations.isEmpty) {
        return null;
      }

      final location = locations.first;

      if (kDebugMode) {
        print('📍 Coordinates for "$address": ${location.latitude}, ${location.longitude}');
      }

      return location;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting coordinates from address: $e');
      }
      return null;
    }
  }

  /// Calculate distance between two points in meters
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Check if current location is within geofence radius
  /// Returns true if within radius, false otherwise
  Future<bool> isWithinGeofence({
    required double targetLat,
    required double targetLon,
    required double radiusInMeters,
  }) async {
    try {
      final currentPosition = await getCurrentLocation();
      if (currentPosition == null) {
        return false;
      }

      final distance = calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        targetLat,
        targetLon,
      );

      final isWithin = distance <= radiusInMeters;

      if (kDebugMode) {
        print('📍 Distance to geofence: ${distance.toStringAsFixed(0)}m (radius: ${radiusInMeters}m)');
        print('📍 Within geofence: $isWithin');
      }

      return isWithin;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking geofence: $e');
      }
      return false;
    }
  }

  /// Open device location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Open app settings for permission management
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
