import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

/// Stub implementation for non-web platforms
/// This file is only used when compiling for iOS/Android
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
