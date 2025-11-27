import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Network connectivity service for monitoring online/offline status
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  // Stream controller for connectivity status
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;

  /// Stream of online/offline status
  Stream<bool> get connectionStream => _connectionStatusController.stream;

  /// Current online status
  bool get isOnline => _isOnline;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Get initial status
    await _checkConnectivity();

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _updateConnectionStatus(results);
      },
    );
  }

  /// Check current connectivity status
  Future<bool> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _updateConnectionStatus(results);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false;
    }
  }

  /// Update connection status based on results
  bool _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;

    // Check if any connection is available (not none)
    _isOnline = results.any((result) => result != ConnectivityResult.none);

    // Only emit if status changed
    if (wasOnline != _isOnline) {
      _connectionStatusController.add(_isOnline);
      debugPrint('Connectivity changed: ${_isOnline ? "Online" : "Offline"}');
    }

    return _isOnline;
  }

  /// Force check connectivity
  Future<bool> checkConnectivity() async {
    return await _checkConnectivity();
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _connectionStatusController.close();
  }
}
