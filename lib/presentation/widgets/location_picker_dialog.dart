import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:todo_app/core/services/location_service.dart';
import 'package:todo_app/core/theme/app_colors.dart';

/// Result returned when location is selected
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
class LocationPickerDialog extends StatefulWidget {
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
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  final LocationService _locationService = LocationService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  NaverMapController? _mapController;
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
            content: Text('검색 중: "$query"'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.blue,
          ),
        );
      }

      final results = await _locationService.searchPlaces(query);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });

        // Show result count
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${results.length}개 장소 찾음'),
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
            content: Text('검색 실패: $e'),
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

    // Move camera to selected location
    final cameraUpdate = NCameraUpdate.scrollAndZoomTo(
      target: location,
      zoom: 16.0,
    );
    _mapController?.updateCamera(cameraUpdate);

    // Update marker and circle
    _updateMapOverlays();
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

        // Move camera to current location
        final cameraUpdate = NCameraUpdate.scrollAndZoomTo(
          target: location,
          zoom: 15.0,
        );
        _mapController?.updateCamera(cameraUpdate);

        // Update marker and circle
        await _updateMapOverlays();

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

  /// Update marker and circle overlays on the map
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
      color: AppColors.primaryBlue.withOpacity(0.2),
      outlineColor: AppColors.primaryBlue,
      outlineWidth: 2,
    );
    _circles.add(circle);

    // Add overlays to map
    await _mapController!.clearOverlays();
    await _mapController!.addOverlayAll(_markers);
    await _mapController!.addOverlayAll(_circles);
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
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'search_location'.tr(),
                  prefixIcon: IconButton(
                    icon: const Icon(Icons.search),
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
                              icon: const Icon(Icons.clear),
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
                      leading: const Icon(Icons.place, color: AppColors.primaryBlue),
                      title: Text(
                        result.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        result.address,
                        style: const TextStyle(fontSize: 12, color: AppColors.textGray),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _selectSearchResult(result),
                    );
                  },
                ),
              ),

            // Map (only on mobile) or info message (on web)
            if (kIsWeb)
              // Web: Show info message instead of map
              Container(
                height: 250,
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 48,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '웹 버전에서는 주소 검색으로 위치를 지정할 수 있습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '위 검색창에서 장소 또는 주소를 검색하세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textGray.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '지도 기능과 위치 추적은 모바일 앱에서만 사용 가능합니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textGray.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              )
            else
              // Mobile: Show map
              SizedBox(
                height: 250,
                child: Stack(
                  children: [
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
                            : const Icon(Icons.my_location),
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
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textGray,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Location name input
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'location_name'.tr(),
                        hintText: 'location_name'.tr(),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.label),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Radius slider
                    Text(
                      '${'geofence_radius'.tr()}: ${_radius.toInt()}m',
                      style: const TextStyle(
                        fontSize: 14,
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
                        // Update circle radius
                        _updateMapOverlays();
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
