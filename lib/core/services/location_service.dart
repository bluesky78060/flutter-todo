import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

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

  /// Get address from coordinates using Naver Reverse Geocoding API
  /// This provides more accurate Korean addresses than Google's geocoding
  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // Naver Reverse Geocoding API
      final url = Uri.parse(
        'https://naveropenapi.apigw.ntruss.com/map-reversegeocode/v2/gc'
        '?coords=$longitude,$latitude'
        '&orders=roadaddr,addr'
        '&output=json',
      );

      final response = await http.get(
        url,
        headers: {
          'X-NCP-APIGW-API-KEY-ID': 'rzx12utf2x',
          'X-NCP-APIGW-API-KEY': 'TWErCJbPnbFflibumhN3MfjJSz1tDsKXqX5Vff1C',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List?;

        if (results != null && results.isNotEmpty) {
          final result = results.first;
          final region = result['region'];
          final land = result['land'];

          // Build address from region and land data
          final addressParts = <String>[];

          // Add area names (시/도, 시/군/구, 읍/면/동)
          if (region['area1']?['name'] != null) {
            addressParts.add(region['area1']['name']);
          }
          if (region['area2']?['name'] != null) {
            addressParts.add(region['area2']['name']);
          }
          if (region['area3']?['name'] != null) {
            addressParts.add(region['area3']['name']);
          }

          // Add specific location if available
          if (land?['name'] != null) {
            addressParts.add(land['name']);
          }
          if (land?['number1'] != null) {
            addressParts.add(land['number1']);
          }

          final address = addressParts.join(' ');

          if (kDebugMode) {
            print('📍 Naver Address: $address');
          }

          return address.isNotEmpty ? address : null;
        }
      }

      if (kDebugMode) {
        print('⚠️ Naver API failed, falling back to Google Geocoding');
      }

      // Fallback to Google's geocoding if Naver fails
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
        print('📍 Google Fallback Address: $address');
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

  /// Search for places and addresses using Naver Local Search API
  /// Tries multiple search strategies to find both businesses and addresses
  Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      // Strategy 1: Direct search
      print('🔍 Strategy 1: Direct "$query"');
      var results = await _searchLocalAPI(query);
      if (results.isNotEmpty) {
        print('✅ Found ${results.length} results');
        return results;
      }

      // Strategy 2: Try with region prefixes for addresses
      // Common Korean regions
      final regions = [
        '서울', '부산', '대구', '인천', '광주', '대전', '울산', '세종',
        '경기', '강원', '충북', '충남', '전북', '전남', '경북', '경남', '제주'
      ];

      // Check if query looks like an address (contains 로, 길, 가, etc.)
      if (query.contains('로') || query.contains('길') || query.contains('가')) {
        for (final region in regions) {
          final searchQuery = '$region $query';
          print('🔍 Strategy 2: "$searchQuery"');
          results = await _searchLocalAPI(searchQuery);
          if (results.isNotEmpty) {
            print('✅ Found ${results.length} results');
            return results;
          }
        }
      }

      // Strategy 3: Try with detailed region combinations
      // For addresses like "문단길15", try "봉화 문단길", "봉화군 문단길" etc.
      final detailedRegions = [
        '봉화', '봉화군', '경북 봉화', '경상북도 봉화',
        '진천', '진천군', '충북 진천', '충청북도 진천',
      ];

      if (query.contains('문단길')) {
        for (final region in detailedRegions) {
          final searchQuery = '$region ${query.replaceAll(RegExp(r'\d+'), '')}';
          print('🔍 Strategy 3: "$searchQuery"');
          results = await _searchLocalAPI(searchQuery);
          if (results.isNotEmpty) {
            print('✅ Found ${results.length} results');
            return results;
          }
        }
      }

      // Strategy 4: Try removing numbers and searching
      final queryWithoutNumbers = query.replaceAll(RegExp(r'\d+'), '').trim();
      if (queryWithoutNumbers != query && queryWithoutNumbers.isNotEmpty) {
        print('🔍 Strategy 4: Without numbers "$queryWithoutNumbers"');
        results = await _searchLocalAPI(queryWithoutNumbers);
        if (results.isNotEmpty) {
          print('✅ Found ${results.length} results');
          return results;
        }
      }

      // Strategy 5: Try Geocoding API for address search
      print('🔍 Strategy 5: Geocoding API "$query"');
      results = await _searchGeocodingAPI(query);
      if (results.isNotEmpty) {
        print('✅ Found ${results.length} results with Geocoding');
        return results;
      }

      print('⚠️ No results found for: $query');
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error searching places: $e');
      }
      return [];
    }
  }

  /// Search using Naver Local Search API (for businesses/places)
  Future<List<PlaceSearchResult>> _searchLocalAPI(String query) async {
    try {
      final url = Uri.parse(
        'https://openapi.naver.com/v1/search/local.json'
        '?query=${Uri.encodeComponent(query)}'
        '&display=10'
        '&start=1'
        '&sort=random',
      );

      final response = await http.get(
        url,
        headers: {
          'X-Naver-Client-Id': 'quSL_7O8Nb5bh6hK4Kj2',
          'X-Naver-Client-Secret': 'raJroLJaYw',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List?;

        // Debug: Always print response for troubleshooting
        print('🔍 Naver Local Search API Response:');
        print('   Status: 200');
        print('   Items count: ${items?.length ?? 0}');
        if (items != null && items.isNotEmpty) {
          print('   First item title: ${items[0]['title']}');
          print('   First item mapx: ${items[0]['mapx']}');
          print('   First item mapy: ${items[0]['mapy']}');
        }

        if (items != null && items.isNotEmpty) {
          final allResults = items.map((item) {
            // Remove HTML tags from title and address
            final title = _removeHtmlTags(item['title'] as String? ?? '');
            final address = item['roadAddress'] as String? ?? item['address'] as String? ?? '';

            // Parse coordinates (Naver uses KATECH coordinates, need conversion)
            // Note: Naver API returns coordinates as strings, not integers
            final mapx = int.tryParse(item['mapx']?.toString() ?? '');
            final mapy = int.tryParse(item['mapy']?.toString() ?? '');

            double? latitude;
            double? longitude;

            if (mapx != null && mapy != null) {
              // Naver API returns coordinates multiplied by 10^7
              // Divide by 10^7 to get actual WGS84 coordinates
              longitude = mapx / 10000000.0;
              latitude = mapy / 10000000.0;
              print('   Converted coords: lat=$latitude, lon=$longitude');
            } else {
              print('   ⚠️ Missing coordinates for: $title');
            }

            return PlaceSearchResult(
              name: title,
              address: address,
              latitude: latitude,
              longitude: longitude,
              category: item['category'] as String? ?? '',
            );
          }).toList();

          final results = allResults.where((result) =>
            result.latitude != null && result.longitude != null
          ).toList();

          print('🔍 Local Search - Total results: ${allResults.length}, Valid coords: ${results.length}');

          return results;
        }
      }

      print('⚠️ Local search returned no results');
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in local search: $e');
      }
      return [];
    }
  }


  /// Search using Google Geocoding (via geocoding package)
  Future<List<PlaceSearchResult>> _searchGeocodingAPI(String query) async {
    try {
      if (kDebugMode) {
        print('🗺️ Using Google Geocoding for: "$query"');
      }

      // Use geocoding package (Google Geocoding)
      final locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        final results = <PlaceSearchResult>[];

        for (final location in locations) {
          // Get address details from coordinates
          try {
            final placemarks = await placemarkFromCoordinates(
              location.latitude,
              location.longitude,
            );

            if (placemarks.isNotEmpty) {
              final placemark = placemarks.first;
              final addressParts = [
                if (placemark.street?.isNotEmpty ?? false) placemark.street,
                if (placemark.subLocality?.isNotEmpty ?? false) placemark.subLocality,
                if (placemark.locality?.isNotEmpty ?? false) placemark.locality,
                if (placemark.subAdministrativeArea?.isNotEmpty ?? false) placemark.subAdministrativeArea,
                if (placemark.administrativeArea?.isNotEmpty ?? false) placemark.administrativeArea,
              ].where((part) => part != null && part.isNotEmpty).join(' ');

              final displayAddress = addressParts.isNotEmpty ? addressParts : query;

              if (kDebugMode) {
                print('   📍 $displayAddress at (${location.latitude}, ${location.longitude})');
              }

              results.add(PlaceSearchResult(
                name: displayAddress,
                address: displayAddress,
                latitude: location.latitude,
                longitude: location.longitude,
                category: '주소',
              ));
            }
          } catch (e) {
            // If reverse geocoding fails, still add the location with the query as address
            if (kDebugMode) {
              print('   📍 $query at (${location.latitude}, ${location.longitude})');
            }

            results.add(PlaceSearchResult(
              name: query,
              address: query,
              latitude: location.latitude,
              longitude: location.longitude,
              category: '주소',
            ));
          }
        }

        if (kDebugMode) {
          print('✅ Found ${results.length} geocoding results');
        }
        return results;
      }

      if (kDebugMode) {
        print('⚠️ No geocoding results found');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Geocoding exception: $e');
      }
      return [];
    }
  }

  /// Remove HTML tags from string
  String _removeHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }
}

/// Result from place search
class PlaceSearchResult {
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final String category;

  const PlaceSearchResult({
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.category = '',
  });
}
