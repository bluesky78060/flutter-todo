/// Web platform implementation for Naver Map using JavaScript SDK.
///
/// This file provides the web-specific Naver Map implementation using
/// the Naver Maps JavaScript API instead of the Flutter SDK (which
/// doesn't support web).
///
/// Architecture:
/// - Creates an HTML div element for the map container
/// - Communicates with naver_map_bridge.js via postMessage API
/// - Registers view factory for HtmlElementView integration
///
/// Message types (to JavaScript):
/// - `naver_map_init`: Initialize map in div with center and zoom
/// - `naver_map_update_overlays`: Update marker and circle overlay
/// - `naver_map_move_camera`: Move map camera to position
/// - `naver_search`: Search for places using Naver Local Search API
///
/// Message types (from JavaScript):
/// - `naver_map_ready`: Map initialization complete
/// - `naver_map_tap`: User tapped on map (lat/lng)
/// - `naver_map_error`: Error occurred during map operation
/// - `naver_search_result`: Search results returned
///
/// See also:
/// - [naver_map_platform.dart] for mobile stub
/// - [LocationPickerDialog] where this is used
/// - web/naver_map_bridge.js for JavaScript implementation
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

/// Web-specific Naver Map widget using JavaScript SDK.
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

  /// `removeEventListener` 에 같은 JS 객체를 넘겨야 하므로 보관한다.
  /// `.toJS` 는 호출할 때마다 새 JS 함수를 만들기 때문에 인라인으로 쓰면 해제할 수 없다.
  JSFunction? _messageListener;
  static final Map<int, Completer<List<Map<String, dynamic>>>> _pendingSearches = {};

  @override
  void initState() {
    super.initState();
    _registerViewFactory();
    _setupMessageListener();
  }

  @override
  void dispose() {
    // 해제하지 않으면 window 가 이 State 를 계속 붙잡아 누수가 생기고,
    // 폐기된 위젯의 onMapReady/onMapTap 이 계속 호출된다.
    final listener = _messageListener;
    if (listener != null) {
      web.window.removeEventListener('message', listener);
      _messageListener = null;
    }
    super.dispose();
  }

  void _setupMessageListener() {
    // Listen for messages from JavaScript bridge.
    //
    // `window.onmessage` 대입이 아니라 addEventListener 를 쓴다. 대입 방식은
    // 지도 인스턴스가 둘 이상일 때 서로의 핸들러를 덮어쓴다.
    final listener = _onBridgeMessage.toJS;
    _messageListener = listener;
    web.window.addEventListener('message', listener);
  }

  /// JS 브리지 메시지 처리.
  ///
  /// 레거시 `dart:html` 의 `onMessage.listen` 은 Stream/Zone 경로를 타서 콜백
  /// 예외가 JS 경계 밖으로 새지 않았지만, `package:web` + `.toJS` 콜백은 그렇지
  /// 않다. 그래서 본문 전체를 try/catch 로 감싼다.
  void _onBridgeMessage(web.MessageEvent event) {
    // dispose 이후 큐에 남아 있던 메시지가 도착할 수 있다.
    if (!mounted) return;

    try {
      // JS 값을 Dart 자료구조로 변환한다. 레거시 dart:html 은 이 변환을
      // 자동으로 해줬지만 package:web 은 JSAny 를 그대로 넘긴다.
      final data = event.data.dartify();
      if (data is! Map) return;

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
        // JS number 는 dartify() 후 JS 컴파일에서는 int/double, Wasm 에서는
        // double 로 온다. num 으로 받아 명시적으로 정규화해야 안전하다.
        final lat = (data['lat'] as num).toDouble();
        final lng = (data['lng'] as num).toDouble();
        debugPrint('🗺️ Map tapped: $lat, $lng');
        widget.onMapTap?.call(NLatLng(lat, lng));
      } else if (type == 'naver_map_error') {
        final error = data['error'];
        debugPrint('❌ Map error: $error');
      } else if (type == 'naver_search_result') {
        final requestId = (data['requestId'] as num).toInt();
        final results = (data['results'] as List?) ?? const [];
        final completer = _pendingSearches.remove(requestId);
        if (completer != null && !completer.isCompleted) {
          // Ensure items are maps
          final normalized = results
              .map<Map<String, dynamic>>(
                  (e) => Map<String, dynamic>.from(e as Map))
              .toList();
          completer.complete(normalized);
        }
      }
    } catch (e, stackTrace) {
      // 여기서 던지면 JS 경계를 넘어 처리되지 않은 예외가 된다.
      debugPrint('❌ Naver Map bridge message handling failed: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void _registerViewFactory() {
    // Register the view factory for the map div
    // ignore: undefined_prefixed_name
    try {
      ui_web.platformViewRegistry.registerViewFactory(
        _mapDivId,
        (int viewId) {
          debugPrint('🗺️ Creating map div: $_mapDivId');
          final mapDiv = web.document.createElement('div') as web.HTMLDivElement
            ..id = _mapDivId
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.backgroundColor = '#e0e0e0'; // Gray background to show div exists

          // Initialize map after a delay to ensure div is mounted and SDK is loaded
          Future.delayed(const Duration(milliseconds: 1000), () {
            // 이 지연 중에 위젯이 폐기될 수 있다. 그대로 두면 폐기된 State 가
            // postMessage 를 보낸다.
            if (!mounted) return;
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

  void _initializeMap(web.HTMLDivElement mapDiv) {
    try {
      debugPrint('🗺️ Sending postMessage: naver_map_init($_mapDivId)');

      // Send command to JS via postMessage
      web.window.postMessage({
        'channel': 'naver_map_bridge',
        'type': 'naver_map_init',
        'payload': {
          'divId': _mapDivId,
          'centerLat': widget.initialCenter.latitude,
          'centerLng': widget.initialCenter.longitude,
          'zoom': widget.initialZoom.toInt(),
        }
      }.jsify(), '*'.toJS);

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
      web.window.postMessage({
        'channel': 'naver_map_bridge',
        'type': 'naver_map_update_overlays',
        'payload': {
          'divId': _mapDivId,
          'lat': position.latitude,
          'lng': position.longitude,
          'radiusMeters': radiusMeters,
        }
      }.jsify(), '*'.toJS);

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
      web.window.postMessage({
        'channel': 'naver_map_bridge',
        'type': 'naver_map_move_camera',
        'payload': {
          'divId': _mapDivId,
          'lat': position.latitude,
          'lng': position.longitude,
        }
      }.jsify(), '*'.toJS);

      debugPrint('✅ Camera moved to: $position');
    } catch (e) {
      debugPrint('❌ Error calling moveNaverMapCamera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      viewType: _mapDivId,
    );
  }
}
