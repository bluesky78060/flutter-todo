/// Home screen widget state management providers using Riverpod.
///
/// Provides Android home screen widget functionality including:
/// - Calendar widget with daily todo count
/// - Todo list widget with today's tasks
/// - Widget configuration and update management
///
/// Key providers:
/// - [widgetServiceProvider]: Service for widget data and updates
/// - [widgetConfigProvider]: Current widget configuration
/// - [widgetCalendarDataProvider]: Calendar data for widget display
/// - [widgetTodoListDataProvider]: Today's todos for widget display
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/widget/widget_models.dart';
import 'package:todo_app/core/widget/widget_service.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';

/// Provides the widget service for home screen widget operations.
final widgetServiceProvider = Provider<WidgetService>((ref) {
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  final todoRepository = ref.watch(todoRepositoryProvider);

  return WidgetService(
    todoRepository: todoRepository,
    preferences: sharedPreferences,
  );
});

/// Widget configuration provider
final widgetConfigProvider = Provider<WidgetConfig>((ref) {
  final service = ref.watch(widgetServiceProvider);
  return service.getWidgetConfig();
});

/// Calendar data provider
final widgetCalendarDataProvider = FutureProvider<CalendarData>((ref) async {
  final service = ref.watch(widgetServiceProvider);
  return service.getCalendarData();
});

/// Today's todo list data provider
final widgetTodoListDataProvider = FutureProvider<TodoListData>((ref) async {
  final service = ref.watch(widgetServiceProvider);
  return service.getTodaysTodos();
});

/// Widget view type provider (for UI state)
final widgetViewTypeProvider = Provider<WidgetViewType>((ref) {
  final config = ref.watch(widgetConfigProvider);
  return config.viewType;
});

/// Widget enabled state provider
final widgetEnabledProvider = Provider<bool>((ref) {
  final config = ref.watch(widgetConfigProvider);
  return config.isEnabled;
});

/// Provider for updating widget view type
final updateWidgetViewTypeProvider = FutureProvider.family<void, WidgetViewType>((
  ref,
  viewType,
) async {
  final service = ref.watch(widgetServiceProvider);
  await service.setWidgetViewType(viewType);

  // Invalidate providers to refresh UI
  ref.invalidate(widgetConfigProvider);
  ref.invalidate(widgetViewTypeProvider);

  // Update the widget display
  await service.updateWidget();
});

/// Provider for toggling widget enabled state
final toggleWidgetEnabledProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(widgetServiceProvider);
  final config = ref.watch(widgetConfigProvider);

  final newState = !config.isEnabled;
  await service.setWidgetEnabled(newState);

  // Invalidate providers to refresh UI
  ref.invalidate(widgetConfigProvider);
  ref.invalidate(widgetEnabledProvider);

  // Update the widget display
  if (newState) {
    await service.updateWidget();
  } else {
    await service.disableAllWidgets();
  }
});

/// Provider for manually updating widget
final manualWidgetUpdateProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(widgetServiceProvider);
  await service.updateWidget();

  // Refresh data providers
  ref.invalidate(widgetCalendarDataProvider);
  ref.invalidate(widgetTodoListDataProvider);
});

/// Provider to check if widget needs update
final widgetNeedsUpdateProvider = Provider<bool>((ref) {
  final service = ref.watch(widgetServiceProvider);
  return service.shouldUpdateWidget();
});

/// Provider for widget update notification
final widgetUpdateNotifierProvider = AsyncNotifierProvider<
    WidgetUpdateNotifier,
    void>(() {
  return WidgetUpdateNotifier();
});

/// Notifier for handling widget updates
class WidgetUpdateNotifier extends AsyncNotifier<void> {
  late WidgetService _service;

  @override
  Future<void> build() async {
    _service = ref.watch(widgetServiceProvider);
  }

  /// Trigger manual widget update
  Future<void> updateWidget() async {
    state = const AsyncValue.loading();
    try {
      await _service.updateWidget();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Trigger refresh of all widget data
  Future<void> refreshAllData() async {
    state = const AsyncValue.loading();
    try {
      await _service.refreshWidget();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Clear widget data
  Future<void> clearWidgetData() async {
    try {
      await _service.clearWidgetData();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
