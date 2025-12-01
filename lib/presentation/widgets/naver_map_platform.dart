/// Platform stub for Naver Map web widget (mobile platforms).
///
/// This file provides a stub implementation for non-web platforms
/// (iOS and Android) where the actual Naver Map Flutter SDK is used
/// instead of the JavaScript SDK.
///
/// This stub is imported conditionally via dart.library.html:
/// - On web: Uses naver_map_platform.web.dart (JavaScript SDK)
/// - On mobile: Uses this file (stub that returns error message)
///
/// The actual map rendering on mobile uses the native [NaverMap]
/// widget from flutter_naver_map package in [LocationPickerDialog].
///
/// See also:
/// - [naver_map_platform.web.dart] for web implementation
/// - [LocationPickerDialog] for the map usage
library;

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

/// Stub implementation for non-web platforms.
/// This widget is only used when compiling for iOS/Android.
class NaverMapWeb extends StatelessWidget {
  final NLatLng initialCenter;
  final double initialZoom;
  final Function(NLatLng)? onMapTap;
  final Function(dynamic)? onMapReady;

  const NaverMapWeb({
    super.key,
    required this.initialCenter,
    this.initialZoom = 15.0,
    this.onMapTap,
    this.onMapReady,
  });

  @override
  Widget build(BuildContext context) {
    // This should never be called on mobile platforms
    return const Center(
      child: Text('NaverMapWeb is only available on web platform'),
    );
  }

  // Stub methods for API compatibility
  void updateOverlays(NLatLng position, double radiusMeters) {}
  void moveCamera(NLatLng position) {}
}
