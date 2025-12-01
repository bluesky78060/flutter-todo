/// Offline status and sync indicator widgets.
///
/// Provides visual feedback for network connectivity and sync state.
///
/// Widgets included:
/// - [OfflineBanner]: Full-width banner shown when offline
/// - [SyncStatusIndicator]: Compact sync status with retry option
/// - [ConnectionStatusWidget]: Combined status for app bar integration
///
/// States tracked:
/// - Online/offline connectivity
/// - Sync in progress, success, or failed
/// - Last sync timestamp
/// - Retry capability
///
/// See also:
/// - [isOnlineStateProvider] for connectivity state
/// - [syncStateProvider] for sync status management
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/presentation/providers/connectivity_provider.dart';

/// Banner widget showing offline status with warning styling.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineStateProvider);

    if (isOnline) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade700,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(
              FluentIcons.wifi_off_24_regular,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tr('offline_mode'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    tr('offline_mode_description'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

/// Sync status indicator widget
class SyncStatusIndicator extends ConsumerWidget {
  final bool showLastSync;

  const SyncStatusIndicator({
    super.key,
    this.showLastSync = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);
    final lastSyncString = ref.watch(lastSyncTimeStringProvider);
    final isOnline = ref.watch(isOnlineStateProvider);

    // Don't show if offline
    if (!isOnline) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sync status icon
        _buildStatusIcon(syncState),
        if (showLastSync && lastSyncString != null) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              lastSyncString,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        // Retry button if failed
        if (syncState.hasFailed && syncState.canRetry) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              ref.read(syncStateProvider.notifier).manualRetry();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    FluentIcons.arrow_sync_24_regular,
                    size: 14,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    tr('retry'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusIcon(SyncState state) {
    switch (state.status) {
      case SyncStatus.syncing:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        );
      case SyncStatus.success:
        return const Icon(
          FluentIcons.checkmark_circle_24_filled,
          size: 16,
          color: Colors.green,
        );
      case SyncStatus.failed:
        return const Icon(
          FluentIcons.error_circle_24_filled,
          size: 16,
          color: Colors.red,
        );
      case SyncStatus.idle:
        return Icon(
          FluentIcons.cloud_checkmark_24_regular,
          size: 16,
          color: Colors.grey.shade400,
        );
    }
  }
}

/// Combined connection status widget for app bar
class ConnectionStatusWidget extends ConsumerWidget {
  const ConnectionStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineStateProvider);
    final syncState = ref.watch(syncStateProvider);
    final lastSyncString = ref.watch(lastSyncTimeStringProvider);

    return Tooltip(
      message: isOnline
          ? (lastSyncString != null
              ? '${tr('last_sync')}: $lastSyncString'
              : tr('connected'))
          : tr('offline_mode'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getBackgroundColor(isOnline, syncState),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(isOnline, syncState),
            if (!isOnline || syncState.hasFailed) ...[
              const SizedBox(width: 4),
              Text(
                isOnline
                    ? (syncState.hasFailed ? tr('sync_failed') : '')
                    : tr('offline'),
                style: TextStyle(
                  fontSize: 11,
                  color: _getTextColor(isOnline, syncState),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(bool isOnline, SyncState syncState) {
    if (!isOnline) {
      return Colors.orange.shade100;
    }
    if (syncState.hasFailed) {
      return Colors.red.shade100;
    }
    return Colors.transparent;
  }

  Color _getTextColor(bool isOnline, SyncState syncState) {
    if (!isOnline) {
      return Colors.orange.shade700;
    }
    if (syncState.hasFailed) {
      return Colors.red.shade700;
    }
    return Colors.grey;
  }

  Widget _buildIcon(bool isOnline, SyncState syncState) {
    if (!isOnline) {
      return Icon(
        FluentIcons.cloud_off_24_regular,
        size: 16,
        color: Colors.orange.shade700,
      );
    }

    switch (syncState.status) {
      case SyncStatus.syncing:
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.blue,
          ),
        );
      case SyncStatus.failed:
        return Icon(
          FluentIcons.cloud_dismiss_24_regular,
          size: 16,
          color: Colors.red.shade700,
        );
      case SyncStatus.success:
        return const Icon(
          FluentIcons.cloud_checkmark_24_regular,
          size: 16,
          color: Colors.green,
        );
      case SyncStatus.idle:
        return Icon(
          FluentIcons.cloud_24_regular,
          size: 16,
          color: Colors.grey.shade500,
        );
    }
  }
}
