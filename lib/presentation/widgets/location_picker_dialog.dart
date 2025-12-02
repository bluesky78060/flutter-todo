/// Location picker dialog for geofence-based reminders.
///
/// Provides an interactive map interface for selecting a location and
/// configuring a geofence radius for location-based todo reminders.
///
/// Features:
/// - Naver Map integration (native SDK on mobile, JavaScript SDK on web)
/// - Place search with autocomplete via Naver Local Search API
/// - Current location detection
/// - Interactive marker placement by tapping on map
/// - Configurable geofence radius (50m - 1000m)
/// - Address reverse geocoding
///
/// Returns a [LocationPickerResult] containing:
/// - Latitude and longitude coordinates
/// - Location name (user input or from search)
/// - Geofence radius in meters
///
/// Platform handling:
/// - Mobile (iOS/Android): Uses flutter_naver_map package
/// - Web: Uses JavaScript SDK via naver_map_platform.web.dart
///
/// See also:
/// - [TodoFormDialog] where location picker is triggered
/// - [GeofenceWorkManagerService] for background geofence monitoring
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:todo_app/core/services/location_service.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';
// Conditional import for web vs mobile
import 'package:todo_app/presentation/widgets/naver_map_platform.dart'
    if (dart.library.html) 'package:todo_app/presentation/widgets/naver_map_platform.web.dart';

/// Result returned when location is selected from the picker.
class LocationPickerResult {
  final double latitude;
  final double longitude;
  final String? name;
  final double radius; // in meters

  const LocationPickerResult({
    required this.latitude,
    required this.longitude,
    this.name,
    this.radius = 100.0,
  });
}

/// Dialog for picking a location on a map
class LocationPickerDialog extends ConsumerStatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialName;
  final double? initialRadius;

  const LocationPickerDialog({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialName,
    this.initialRadius,
  });

  @override
  ConsumerState<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends ConsumerState<LocationPickerDialog> {
  final LocationService _locationService = LocationService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  NaverMapController? _mapController;
  dynamic _webMapState; // For web map (NaverMapWeb state)
  NLatLng? _selectedLocation;
  double _radius = 100.0; // Default radius in meters
  bool _isLoadingLocation = false;
  bool _isSearching = false;
  String? _addressText;
  final Set<NMarker> _markers = {};
  final Set<NCircleOverlay> _circles = {};
  List<PlaceSearchResult> _searchResults = [];

  @override
  void initState() {
    super.initState();

    // Initialize with existing values if provided
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = NLatLng(widget.initialLatitude!, widget.initialLongitude!);
    }

    if (widget.initialName != null) {
      _nameController.text = widget.initialName!;
    }

    if (widget.initialRadius != null) {
      _radius = widget.initialRadius!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Search for places
  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Show loading toast
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Searching: "$query"'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.blue,
          ),
        );
      }

      // Both web and mobile use LocationService now
      // LocationService has web-specific implementation via naver_map_bridge.js
      final results = await _locationService.searchPlaces(query);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });

        // Show result count
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${results.length} places found'),
            duration: const Duration(seconds: 2),
            backgroundColor: results.isEmpty ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Select a place from search results
  void _selectSearchResult(PlaceSearchResult result) {
    if (result.latitude == null || result.longitude == null) return;

    final location = NLatLng(result.latitude!, result.longitude!);

    setState(() {
      _selectedLocation = location;
      _addressText = result.address;
      _nameController.text = result.name;
      _searchResults = [];
      _searchController.clear();
    });

    // Move camera and update overlays (platform-specific)
    if (kIsWeb) {
      _webMapState?.moveCamera(location);
      _updateWebMapOverlays();
    } else {
      final cameraUpdate = NCameraUpdate.scrollAndZoomTo(
        target: location,
        zoom: 16.0,
      );
      _mapController?.updateCamera(cameraUpdate);
      _updateMapOverlays();
    }
  }

  /// Get current location and move map
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final position = await _locationService.getCurrentLocation();

      if (position != null) {
        final location = NLatLng(position.latitude, position.longitude);

        setState(() {
          _selectedLocation = location;
        });

        // Move camera and update overlays (platform-specific)
        if (kIsWeb) {
          _webMapState?.moveCamera(location);
          _updateWebMapOverlays();
        } else {
          final cameraUpdate = NCameraUpdate.scrollAndZoomTo(
            target: location,
            zoom: 15.0,
          );
          _mapController?.updateCamera(cameraUpdate);
          await _updateMapOverlays();
        }

        // Get address for current location
        await _updateAddress(position.latitude, position.longitude);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('location_error'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('location_error'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  /// Update address text from coordinates
  Future<void> _updateAddress(double lat, double lon) async {
    final address = await _locationService.getAddressFromCoordinates(lat, lon);
    if (address != null && mounted) {
      setState(() {
        _addressText = address;
        // Auto-fill name if empty
        if (_nameController.text.isEmpty) {
          _nameController.text = address;
        }
      });
    }
  }

  /// Update marker and circle overlays on the map (mobile)
  Future<void> _updateMapOverlays() async {
    if (_selectedLocation == null || _mapController == null) return;

    // Clear existing overlays
    _markers.clear();
    _circles.clear();

    // Create new marker
    final marker = NMarker(
      id: 'selected',
      position: _selectedLocation!,
    );
    _markers.add(marker);

    // Create new circle
    final circle = NCircleOverlay(
      id: 'radius',
      center: _selectedLocation!,
      radius: _radius,
      color: AppColors.primary.withOpacity(0.2),
      outlineColor: AppColors.primary,
      outlineWidth: 2,
    );
    _circles.add(circle);

    // Add overlays to map
    await _mapController!.clearOverlays();
    await _mapController!.addOverlayAll(_markers);
    await _mapController!.addOverlayAll(_circles);
  }

  /// Update marker and circle overlays on web map
  void _updateWebMapOverlays() {
    if (_selectedLocation == null || _webMapState == null) return;

    // Call web map's updateOverlays method
    _webMapState.updateOverlays(_selectedLocation!, _radius);
  }

  /// Handle map tap to select location
  void _onMapTap(NPoint point, NLatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
    });

    // Update overlays
    _updateMapOverlays();

    // Update address
    _updateAddress(latLng.latitude, latLng.longitude);
  }

  /// Save selected location
  void _saveLocation() {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('select_location'.tr()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = LocationPickerResult(
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
      name: _nameController.text.isNotEmpty ? _nameController.text : _addressText,
      radius: _radius,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    // Default location (Seoul, South Korea)
    final initialPosition = _selectedLocation ??
                           const NLatLng(37.5665, 126.9780);

    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.85, // 85% of screen height
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'select_location'.tr(),
                    style: TextStyle(
                      fontSize: AppColors.scaledFontSize(20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Search bar (uses proxy server on web to bypass CORS)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'search_location'.tr(),
                  prefixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                      if (_searchController.text.isNotEmpty) {
                        _searchPlaces(_searchController.text);
                      }
                    },
                  ),
                  suffixIcon: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                              });
                            },
                          )
                        : null,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: _searchPlaces,
              textInputAction: TextInputAction.search,
            ),
          ),

            const SizedBox(height: 8),

            // Search results
            if (_searchResults.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    return ListTile(
                      leading: Icon(Icons.place, color: AppColors.primary),
                      title: Text(
                        result.name,
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        result.address,
                        style: TextStyle(fontSize: AppColors.scaledFontSize(12), color: AppColors.getTextSecondary(isDarkMode)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _selectSearchResult(result),
                    );
                  },
                ),
              ),

            // Map - Platform-specific implementation
            SizedBox(
              height: 250,
              child: Stack(
                children: [
                  // Web: Use NaverMapWeb (JavaScript SDK)
                  // Mobile: Use NaverMap (Flutter SDK)
                  if (kIsWeb)
                    NaverMapWeb(
                      initialCenter: initialPosition,
                      initialZoom: 15.0,
                      onMapTap: (latLng) {
                        setState(() {
                          _selectedLocation = latLng;
                        });
                        _updateAddress(latLng.latitude, latLng.longitude);
                      },
                      onMapReady: (webMapState) {
                        // Store web map state reference for updates
                        _webMapState = webMapState;
                        if (_selectedLocation != null) {
                          _updateWebMapOverlays();
                        }
                      },
                    )
                  else
                    NaverMap(
                      options: NaverMapViewOptions(
                        initialCameraPosition: NCameraPosition(
                          target: initialPosition,
                          zoom: 15.0,
                        ),
                        locationButtonEnable: false,
                        indoorEnable: true,
                        consumeSymbolTapEvents: false,
                      ),
                      onMapReady: (controller) async {
                        _mapController = controller;

                        // Add initial marker and circle if location is set
                        if (_selectedLocation != null) {
                          await _updateMapOverlays();
                        }
                      },
                      onMapTapped: _onMapTap,
                    ),

                  // Current location button
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      mini: true,
                      onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                      child: _isLoadingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.my_location),
                    ),
                  ),
                ],
              ),
            ),

            // Location info - make scrollable
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Address
                    if (_addressText != null) ...[
                      Text(
                        _addressText!,
                        style: TextStyle(
                          fontSize: AppColors.scaledFontSize(14),
                          color: AppColors.getTextSecondary(isDarkMode),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],

                    // Location name input
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'location_name'.tr(),
                        hintText: 'location_name'.tr(),
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Radius slider
                    Text(
                      '${'geofence_radius'.tr()}: ${_radius.toInt()}m',
                      style: TextStyle(
                        fontSize: AppColors.scaledFontSize(14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Slider(
                      value: _radius,
                      min: 50,
                      max: 1000,
                      divisions: 19,
                      label: '${_radius.toInt()}m',
                      onChanged: (value) {
                        setState(() {
                          _radius = value;
                        });
                        // Update circle radius (platform-specific)
                        if (kIsWeb) {
                          _updateWebMapOverlays();
                        } else {
                          _updateMapOverlays();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('cancel'.tr()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveLocation,
                      child: Text('save'.tr()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
