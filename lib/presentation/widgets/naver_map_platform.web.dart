import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

/// Web-specific Naver Map widget using JavaScript SDK
class NaverMapWeb extends StatefulWidget {
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
  State<NaverMapWeb> createState() => _NaverMapWebState();
}

class _NaverMapWebState extends State<NaverMapWeb> {
  final String _mapDivId = 'naver-map-${DateTime.now().millisecondsSinceEpoch}';
  bool _isMapReady = false;
  static int _requestCounter = 0;
  static final Map<int, Completer<List<Map<String, dynamic>>>> _pendingSearches = {};

  @override
  void initState() {
    super.initState();
    _registerViewFactory();
    _setupMessageListener();
  }

  void _setupMessageListener() {
    // Listen for messages from JavaScript bridge
    html.window.onMessage.listen((event) {
      final data = event.data;
      if (data is Map) {
        // Filter channel to avoid intercepting unrelated messages
        final channel = data['channel'];
        if (channel != null && channel != 'naver_map_bridge') {
          return;
        }

        final type = data['type'];
        final divId = data['divId'];

        // Only process messages for this map instance
        if (divId != _mapDivId) return;

        if (type == 'naver_map_ready') {
          debugPrint('✅ Naver Map ready: $_mapDivId');
          _isMapReady = true;
          widget.onMapReady?.call(this);
        } else if (type == 'naver_map_tap') {
          final lat = data['lat'] as double;
          final lng = data['lng'] as double;
          debugPrint('🗺️ Map tapped: $lat, $lng');
          widget.onMapTap?.call(NLatLng(lat, lng));
        } else if (type == 'naver_map_error') {
          final error = data['error'];
          debugPrint('❌ Map error: $error');
        } else if (type == 'naver_search_result') {
          final int requestId = data['requestId'] as int;
          final results = (data['results'] as List?) ?? const [];
          final completer = _pendingSearches.remove(requestId);
          if (completer != null && !completer.isCompleted) {
            // Ensure items are maps
            final normalized = results.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
            completer.complete(normalized);
          }
        }
      }
    });
  }

  void _registerViewFactory() {
    // Register the view factory for the map div
    // ignore: undefined_prefixed_name
    try {
      ui_web.platformViewRegistry.registerViewFactory(
        _mapDivId,
        (int viewId) {
          debugPrint('🗺️ Creating map div: $_mapDivId');
          final mapDiv = html.DivElement()
            ..id = _mapDivId
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.backgroundColor = '#e0e0e0'; // Gray background to show div exists

          // Initialize map after a delay to ensure div is mounted and SDK is loaded
          Future.delayed(const Duration(milliseconds: 1000), () {
            debugPrint('🗺️ Attempting to initialize map in div: $_mapDivId');
            _initializeMap(mapDiv);
          });

          return mapDiv;
        },
      );
      debugPrint('✅ View factory registered: $_mapDivId');
    } catch (e) {
      debugPrint('❌ Error registering view factory: $e');
    }
  }

  void _initializeMap(html.DivElement mapDiv) {
    try {
      debugPrint('🗺️ Sending postMessage: naver_map_init($_mapDivId)');

      // Send command to JS via postMessage
      html.window.postMessage({
        'channel': 'naver_map_bridge',
        'type': 'naver_map_init',
        'payload': {
          'divId': _mapDivId,
          'centerLat': widget.initialCenter.latitude,
          'centerLng': widget.initialCenter.longitude,
          'zoom': widget.initialZoom.toInt(),
        }
      }, '*');

      debugPrint('✅ JavaScript bridge called successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error calling JavaScript bridge: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Update marker and circle on the map
  void updateOverlays(NLatLng position, double radiusMeters) {
    if (!_isMapReady) {
      debugPrint('⚠️ Map not ready yet');
      return;
    }

    try {
      debugPrint('🗺️ Sending postMessage: naver_map_update_overlays($_mapDivId)');

      // Send command to JS via postMessage
      html.window.postMessage({
        'channel': 'naver_map_bridge',
        'type': 'naver_map_update_overlays',
        'payload': {
          'divId': _mapDivId,
          'lat': position.latitude,
          'lng': position.longitude,
          'radiusMeters': radiusMeters,
        }
      }, '*');

      debugPrint('✅ Updated map overlays: $position, radius: $radiusMeters m');
    } catch (e) {
      debugPrint('❌ Error calling updateNaverMapOverlays: $e');
    }
  }

  /// Move camera to position
  void moveCamera(NLatLng position) {
    if (!_isMapReady) return;

    try {
      debugPrint('🗺️ Sending postMessage: naver_map_move_camera($_mapDivId)');

      // Send command to JS via postMessage
      html.window.postMessage({
        'channel': 'naver_map_bridge',
        'type': 'naver_map_move_camera',
        'payload': {
          'divId': _mapDivId,
          'lat': position.latitude,
          'lng': position.longitude,
        }
      }, '*');

      debugPrint('✅ Camera moved to: $position');
    } catch (e) {
      debugPrint('❌ Error calling moveNaverMapCamera: $e');
    }
  }

  /// Search for places using Naver Local Search API
  static Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    debugPrint('🔍 Searching for: $query');

    final requestId = ++_requestCounter;
    final completer = Completer<List<Map<String, dynamic>>>();
    _pendingSearches[requestId] = completer;

    // Send postMessage to JS
    html.window.postMessage({
      'channel': 'naver_map_bridge',
      'type': 'naver_search',
      'payload': {
        'requestId': requestId,
        'query': query,
      }
    }, '*');

    // Timeout fallback
    Future.delayed(const Duration(seconds: 10), () {
      final pending = _pendingSearches.remove(requestId);
      if (pending != null && !pending.isCompleted) {
        debugPrint('⏳ Search timed out for requestId=$requestId');
        pending.complete(<Map<String, dynamic>>[]);
      }
    });

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      viewType: _mapDivId,
    );
  }
}
