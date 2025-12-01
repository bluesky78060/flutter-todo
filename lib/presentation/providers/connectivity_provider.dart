/// Connectivity and sync state management providers.
///
/// Handles network connectivity monitoring and data synchronization
/// state with automatic retry logic.
///
/// Key providers:
/// - [connectivityServiceProvider]: Network monitoring service
/// - [isOnlineProvider]: Stream of online/offline status
/// - [syncStateProvider]: Current sync operation state
/// - [lastSyncTimeStringProvider]: Human-readable last sync time
library;

import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/services/connectivity_service.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';

/// Provides the connectivity service singleton.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provides a stream of network connection status.
final isOnlineProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  // Start with current status, then listen for changes
  return Stream.value(service.isOnline).asyncExpand((_) {
    return service.connectionStream;
  });
});

/// Provides the current online status synchronously.
///
/// Assumes online during loading or error states.
final isOnlineStateProvider = Provider<bool>((ref) {
  final asyncValue = ref.watch(isOnlineProvider);
  return asyncValue.when(
    data: (isOnline) => isOnline,
    loading: () => true, // Assume online while loading
    error: (_, __) => true, // Assume online on error
  );
});

/// Sync operation status values.
enum SyncStatus {
  idle,
  syncing,
  success,
  failed,
}

/// Immutable state class for sync operations.
///
/// Tracks sync status, last sync time, error messages, and retry count.
class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncTime;
  final String? errorMessage;
  final int retryCount;

  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncTime,
    this.errorMessage,
    this.retryCount = 0,
  });

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncTime,
    String? errorMessage,
    int? retryCount,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errorMessage: errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  bool get isSyncing => status == SyncStatus.syncing;
  bool get hasFailed => status == SyncStatus.failed;
  bool get canRetry => retryCount < 3;
}

/// Notifier for managing sync state with automatic retry logic.
///
/// Features:
/// - Progressive retry delays (5s, 15s, 30s)
/// - Maximum 3 retry attempts
/// - Persists last sync time to SharedPreferences
/// - Manual retry support
class SyncStateNotifier extends Notifier<SyncState> {
  Timer? _retryTimer;
  static const _lastSyncKey = 'last_sync_time';
  static const _maxRetries = 3;
  static const _retryDelaySeconds = [5, 15, 30]; // Progressive delays

  @override
  SyncState build() {
    // Load last sync time on initialization
    _loadLastSyncTime();
    // Clean up timer when disposed
    ref.onDispose(() {
      _retryTimer?.cancel();
    });
    return const SyncState();
  }

  Future<void> _loadLastSyncTime() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final timestamp = prefs.getInt(_lastSyncKey);
      if (timestamp != null) {
        state = state.copyWith(
          lastSyncTime: DateTime.fromMillisecondsSinceEpoch(timestamp),
        );
      }
    } catch (e) {
      // Ignore errors loading last sync time
    }
  }

  Future<void> _saveLastSyncTime(DateTime time) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setInt(_lastSyncKey, time.millisecondsSinceEpoch);
    } catch (e) {
      // Ignore errors saving last sync time
    }
  }

  /// Start sync operation
  void startSync() {
    state = state.copyWith(
      status: SyncStatus.syncing,
      errorMessage: null,
    );
  }

  /// Mark sync as successful
  Future<void> syncSuccess() async {
    final now = DateTime.now();
    await _saveLastSyncTime(now);
    _cancelRetry();
    state = state.copyWith(
      status: SyncStatus.success,
      lastSyncTime: now,
      errorMessage: null,
      retryCount: 0,
    );

    // Reset to idle after brief success indicator
    Future.delayed(const Duration(seconds: 2), () {
      if (state.status == SyncStatus.success) {
        state = state.copyWith(status: SyncStatus.idle);
      }
    });
  }

  /// Mark sync as failed with optional retry
  void syncFailed(String error, {bool shouldRetry = true}) {
    final newRetryCount = state.retryCount + 1;

    state = state.copyWith(
      status: SyncStatus.failed,
      errorMessage: error,
      retryCount: newRetryCount,
    );

    // Schedule retry if enabled and under max retries
    if (shouldRetry && newRetryCount < _maxRetries) {
      _scheduleRetry(newRetryCount);
    }
  }

  /// Schedule automatic retry
  void _scheduleRetry(int retryCount) {
    _cancelRetry();
    final delayIndex = (retryCount - 1).clamp(0, _retryDelaySeconds.length - 1);
    final delay = Duration(seconds: _retryDelaySeconds[delayIndex]);

    _retryTimer = Timer(delay, () {
      // Check if still online before retry
      final isOnline = ref.read(isOnlineStateProvider);
      if (isOnline && state.status == SyncStatus.failed) {
        // Trigger retry by invalidating todos provider
        // This will be handled by the TodoActions
        ref.invalidate(retryTriggerProvider);
      }
    });
  }

  /// Cancel pending retry
  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  /// Manual retry
  void manualRetry() {
    if (state.canRetry) {
      state = state.copyWith(retryCount: 0);
      ref.invalidate(retryTriggerProvider);
    }
  }

  /// Reset sync state
  void reset() {
    _cancelRetry();
    state = const SyncState();
  }
}

/// Provides the sync state notifier for managing sync operations.
final syncStateProvider =
    NotifierProvider<SyncStateNotifier, SyncState>(SyncStateNotifier.new);

/// Provider that triggers retry when invalidated.
final retryTriggerProvider = Provider<int>((ref) => 0);

/// Provides a human-readable string for the last sync time.
///
/// Returns localized strings like "Just now", "5 minutes ago", "Yesterday".
final lastSyncTimeStringProvider = Provider<String?>((ref) {
  final syncState = ref.watch(syncStateProvider);
  final lastSync = syncState.lastSyncTime;

  if (lastSync == null) return null;

  final now = DateTime.now();
  final diff = now.difference(lastSync);

  if (diff.inSeconds < 60) {
    return 'time_just_now'.tr();
  } else if (diff.inMinutes < 60) {
    return 'time_minutes_ago'.tr(namedArgs: {'count': '${diff.inMinutes}'});
  } else if (diff.inHours < 24) {
    return 'time_hours_ago'.tr(namedArgs: {'count': '${diff.inHours}'});
  } else if (diff.inDays == 1) {
    return 'yesterday'.tr();
  } else if (diff.inDays < 7) {
    return 'time_days_ago'.tr(namedArgs: {'count': '${diff.inDays}'});
  } else {
    // Format as date
    return 'time_date_format'.tr(namedArgs: {'month': '${lastSync.month}', 'day': '${lastSync.day}'});
  }
});
