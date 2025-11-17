import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  double _radius = 100.0; // Default radius in meters
  bool _isLoadingLocation = false;
  String? _addressText;

  @override
  void initState() {
    super.initState();

    // Initialize with existing values if provided
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
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
    _mapController?.dispose();
    super.dispose();
  }

  /// Get current location and move map
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final position = await _locationService.getCurrentLocation();

      if (position != null) {
        final location = LatLng(position.latitude, position.longitude);

        setState(() {
          _selectedLocation = location;
        });

        // Move camera to current location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(location, 15.0),
        );

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

  /// Handle map tap to select location
  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });

    // Update address
    _updateAddress(position.latitude, position.longitude);
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
                           const LatLng(37.5665, 126.9780);

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 700),
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

            // Map
            SizedBox(
              height: 300,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: initialPosition,
                      zoom: 15.0,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    onTap: _onMapTap,
                    markers: _selectedLocation != null
                        ? {
                            Marker(
                              markerId: const MarkerId('selected'),
                              position: _selectedLocation!,
                            ),
                          }
                        : {},
                    circles: _selectedLocation != null
                        ? {
                            Circle(
                              circleId: const CircleId('radius'),
                              center: _selectedLocation!,
                              radius: _radius,
                              fillColor: AppColors.primaryBlue.withOpacity(0.2),
                              strokeColor: AppColors.primaryBlue,
                              strokeWidth: 2,
                            ),
                          }
                        : {},
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
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

            // Location info
            Padding(
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
                    },
                  ),
                ],
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
