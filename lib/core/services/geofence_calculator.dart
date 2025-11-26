import 'dart:math' as math;

/// GeofenceCalculator provides mathematical utilities for geofencing
class GeofenceCalculator {
  static const double _earthRadiusMeters = 6371000;

  /// Calculate distance using Haversine formula (meters)
  static double calculateHaversineDistance({
    required double userLatitude,
    required double userLongitude,
    required double targetLatitude,
    required double targetLongitude,
  }) {
    final lat1Rad = _degreesToRadians(userLatitude);
    final lat2Rad = _degreesToRadians(targetLatitude);
    final deltaLat = _degreesToRadians(targetLatitude - userLatitude);
    final deltaLon = _degreesToRadians(targetLongitude - userLongitude);

    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);

    final c = 2 * math.asin(math.sqrt(a));
    return _earthRadiusMeters * c;
  }

  /// Simple Euclidean distance (faster, less accurate)
  static double calculateEuclideanDistance({
    required double userLatitude,
    required double userLongitude,
    required double targetLatitude,
    required double targetLongitude,
  }) {
    const double meterPerDegreeLat = 111320.0;
    final double meterPerDegreeLon =
        111320.0 * math.cos(_degreesToRadians(userLatitude));

    final double latDiff = (targetLatitude - userLatitude) * meterPerDegreeLat;
    final double lonDiff =
        (targetLongitude - userLongitude) * meterPerDegreeLon;

    return math.sqrt(latDiff * latDiff + lonDiff * lonDiff);
  }

  /// Check if user is within geofence
  static bool isWithinGeofence({
    required double userLatitude,
    required double userLongitude,
    required double targetLatitude,
    required double targetLongitude,
    required double radiusMeters,
  }) {
    final distance = calculateHaversineDistance(
      userLatitude: userLatitude,
      userLongitude: userLongitude,
      targetLatitude: targetLatitude,
      targetLongitude: targetLongitude,
    );
    return distance <= radiusMeters;
  }

  /// Format distance to string
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)}km';
    }
  }

  static double _degreesToRadians(double degrees) =>
      degrees * math.pi / 180.0;

  static double _radiansToDegrees(double radians) =>
      radians * 180.0 / math.pi;

  /// Calculate bearing between two points (0-360 degrees)
  static double calculateBearing({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) {
    final lat1 = _degreesToRadians(fromLatitude);
    final lat2 = _degreesToRadians(toLatitude);
    final deltaLon = _degreesToRadians(toLongitude - fromLongitude);

    final y = math.sin(deltaLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLon);

    final bearing = math.atan2(y, x);
    return (_radiansToDegrees(bearing) + 360) % 360;
  }

  /// Get distance category
  static String getDistanceCategory(double meters) {
    if (meters < 100) return 'Very close';
    if (meters < 500) return 'Close';
    if (meters < 1000) return 'Nearby';
    if (meters < 5000) return 'Far';
    return 'Very far';
  }
}
