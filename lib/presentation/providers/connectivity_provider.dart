import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/core/services/connectivity_service.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';

/// Connectivity service singleton provider
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Network connection status stream provider
final isOnlineProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  // Start with current status, then listen for changes
  return Stream.value(service.isOnline).asyncExpand((_) {
    return service.connectionStream;
  });
});

/// Current online status (sync getter)
final isOnlineStateProvider = Provider<bool>((ref) {
  final asyncValue = ref.watch(isOnlineProvider);
  return asyncValue.when(
    data: (isOnline) => isOnline,
    loading: () => true, // Assume online while loading
    error: (_, __) => true, // Assume online on error
  );
});

/// Sync status enum
enum SyncStatus {
  idle,
  syncing,
  success,
  failed,
}

/// Sync state model
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

/// Sync state notifier using Notifier (Riverpod 3.x)
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

/// Sync state provider
final syncStateProvider =
    NotifierProvider<SyncStateNotifier, SyncState>(SyncStateNotifier.new);

/// Retry trigger provider (invalidated to trigger retry)
final retryTriggerProvider = Provider<int>((ref) => 0);

/// Last sync time formatted string
final lastSyncTimeStringProvider = Provider<String?>((ref) {
  final syncState = ref.watch(syncStateProvider);
  final lastSync = syncState.lastSyncTime;

  if (lastSync == null) return null;

  final now = DateTime.now();
  final diff = now.difference(lastSync);

  if (diff.inSeconds < 60) {
    return '방금 전';
  } else if (diff.inMinutes < 60) {
    return '${diff.inMinutes}분 전';
  } else if (diff.inHours < 24) {
    return '${diff.inHours}시간 전';
  } else if (diff.inDays == 1) {
    return '어제';
  } else if (diff.inDays < 7) {
    return '${diff.inDays}일 전';
  } else {
    // Format as date
    return '${lastSync.month}/${lastSync.day}';
  }
});
