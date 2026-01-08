import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:todo_app/core/utils/app_logger.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';
import 'package:todo_app/presentation/providers/widget_provider.dart';

/// Service for syncing widget actions with Supabase
/// Processes pending syncs from widget when app resumes
class WidgetSyncService {
  final Ref _ref;

  WidgetSyncService(this._ref);

  /// Process any pending syncs from widget actions
  /// Called when app resumes from background
  Future<void> processPendingSyncs() async {
    if (kIsWeb) return; // Widgets are Android only

    String? pendingSyncsRaw;
    try {
      // Get pending syncs from HomeWidget SharedPreferences
      // Android stores as comma-separated string: "todoId:isCompleted,todoId:isCompleted"
      pendingSyncsRaw = await HomeWidget.getWidgetData<String>('pending_syncs');
    } catch (e) {
      // If there's an error reading (e.g., old StringSet format), clear it
      logger.w('📱 WidgetSyncService: Error reading pending_syncs, clearing old format: $e');
      try {
        await HomeWidget.saveWidgetData('pending_syncs', '');
      } catch (_) {
        // Ignore clear errors
      }
      return;
    }

    try {
      logger.d('📱 WidgetSyncService: Checking pending syncs, raw: $pendingSyncsRaw');

      if (pendingSyncsRaw == null || pendingSyncsRaw.isEmpty) {
        logger.d('📱 WidgetSyncService: No pending syncs');
        return;
      }

      // Parse pending syncs (format: "todoId:isCompleted,todoId:isCompleted,...")
      final pendingSyncs = pendingSyncsRaw
          .split(',')
          .where((s) => s.trim().isNotEmpty && s.contains(':'))
          .toList();

      if (pendingSyncs.isEmpty) {
        logger.d('📱 WidgetSyncService: No valid pending syncs after parsing');
        return;
      }

      logger.d('📱 WidgetSyncService: Processing ${pendingSyncs.length} pending syncs');

      final todoActions = _ref.read(todoActionsProvider);

      for (final sync in pendingSyncs) {
        try {
          final parts = sync.trim().split(':');
          if (parts.length != 2) {
            logger.w('📱 WidgetSyncService: Invalid sync format: $sync');
            continue;
          }

          final todoId = int.tryParse(parts[0]);
          final isCompleted = parts[1] == 'true';

          if (todoId == null) {
            logger.w('📱 WidgetSyncService: Invalid todoId: ${parts[0]}');
            continue;
          }

          logger.d('📱 WidgetSyncService: Syncing todo $todoId (completed=$isCompleted)');

          // Toggle completion - this handles both local DB and Supabase sync
          await todoActions.toggleCompletion(todoId);

          logger.d('✅ WidgetSyncService: Synced todo $todoId');
        } catch (e) {
          logger.e('❌ WidgetSyncService: Failed to sync: $sync', error: e);
        }
      }

      // Clear pending syncs after processing
      await HomeWidget.saveWidgetData('pending_syncs', '');
      logger.d('✅ WidgetSyncService: Cleared pending syncs');

      // Refresh todos to update UI
      _ref.invalidate(todosProvider);
      logger.d('✅ WidgetSyncService: Refreshed todos');

    } catch (e, st) {
      logger.e('❌ WidgetSyncService: Error processing pending syncs', error: e, stackTrace: st);
    }
  }

  /// Check if widget needs full refresh and update it
  /// Called when app resumes to load next items after widget completion
  Future<void> checkAndRefreshWidget() async {
    if (kIsWeb) return;

    try {
      final needsRefresh = await HomeWidget.getWidgetData<bool>('pending_widget_refresh') ?? false;

      if (needsRefresh) {
        logger.d('📱 WidgetSyncService: Widget needs refresh, updating...');

        // Clear the flag first
        await HomeWidget.saveWidgetData<bool>('pending_widget_refresh', false);

        // Trigger full widget update with fresh data from database
        final widgetService = _ref.read(widgetServiceProvider);
        await widgetService.updateWidget();

        logger.d('✅ WidgetSyncService: Widget refreshed with next items');
      }
    } catch (e) {
      logger.e('❌ WidgetSyncService: Error checking widget refresh', error: e);
    }
  }
}

/// Provider for WidgetSyncService
final widgetSyncServiceProvider = Provider<WidgetSyncService>((ref) {
  return WidgetSyncService(ref);
});
