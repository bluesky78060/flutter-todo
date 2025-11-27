import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/core/widget/widget_models.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/domain/repositories/todo_repository.dart';

/// Service to manage home screen widget updates and configuration
class WidgetService {
  final TodoRepository todoRepository;
  final SharedPreferences preferences;

  static const String _viewTypeKey = 'widget_view_type';
  static const String _enabledKey = 'widget_enabled';
  static const String _lastUpdateKey = 'widget_last_update';

  WidgetService({
    required this.todoRepository,
    required this.preferences,
  });

  /// Get current widget configuration
  WidgetConfig getWidgetConfig() {
    final viewTypeStr = preferences.getString(_viewTypeKey);
    final isEnabled = preferences.getBool(_enabledKey) ?? true;
    final lastUpdateStr = preferences.getString(_lastUpdateKey);

    final viewType = viewTypeStr != null
        ? WidgetViewType.values.byName(viewTypeStr)
        : WidgetViewType.today;

    final lastUpdated = lastUpdateStr != null
        ? DateTime.parse(lastUpdateStr)
        : DateTime.now();

    return WidgetConfig(
      viewType: viewType,
      isEnabled: isEnabled,
      lastUpdated: lastUpdated,
    );
  }

  /// Set widget view type preference
  Future<void> setWidgetViewType(WidgetViewType viewType) async {
    await preferences.setString(_viewTypeKey, viewType.name);
    await _updateLastModified();
  }

  /// Set widget enabled state
  Future<void> setWidgetEnabled(bool enabled) async {
    await preferences.setBool(_enabledKey, enabled);
    await _updateLastModified();
  }

  /// Update last modification timestamp
  Future<void> _updateLastModified() async {
    await preferences.setString(_lastUpdateKey, DateTime.now().toIso8601String());
  }

  /// Get calendar data for the current month
  Future<CalendarData> getCalendarData() async {
    try {
      final result = await todoRepository.getTodos();
      final todos = result.fold(
        (failure) => <Todo>[],
        (todos) => todos,
      );
      return CalendarData.fromTodos(todos, DateTime.now());
    } catch (e) {
      // Return empty calendar data on error
      return CalendarData(
        month: DateTime.now(),
        dayTaskCounts: {},
        daysWithTasks: [],
        completedDays: [],
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Get today's todo data
  Future<TodoListData> getTodaysTodos() async {
    try {
      final result = await todoRepository.getTodos();
      final todos = result.fold(
        (failure) => <Todo>[],
        (todos) => todos,
      );
      return TodoListData.fromTodos(todos);
    } catch (e) {
      // Return empty todo list data on error
      return TodoListData(
        date: DateTime.now(),
        todos: [],
        completedCount: 0,
        pendingCount: 0,
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Update widget display based on current configuration
  Future<void> updateWidget() async {
    try {
      final config = getWidgetConfig();

      if (!config.isEnabled) {
        // Clear widget if disabled
        await HomeWidget.setAppGroupId('group.dodo.widget');
        await HomeWidget.saveWidgetData<String>('view_type', 'none');
        return;
      }

      // Update widget based on view type
      if (config.viewType == WidgetViewType.calendar) {
        await _updateCalendarWidget();
      } else {
        await _updateTodoListWidget();
      }

      // Save last update time
      await _updateLastModified();
    } catch (e) {
      print('Error updating widget: $e');
    }
  }

  /// Update calendar widget display
  Future<void> _updateCalendarWidget() async {
    try {
      await HomeWidget.setAppGroupId('group.dodo.widget');

      final calendarData = await getCalendarData();
      await HomeWidget.saveWidgetData<String>(
        'view_type',
        'calendar',
      );
      await HomeWidget.saveWidgetData<String>(
        'calendar_data',
        '',
      );

      // Notify native widget
      await HomeWidget.updateWidget(
        name: 'TodoCalendarWidget',
        iOSName: 'TodoCalendarWidget',
      );
    } catch (e) {
      print('Error updating calendar widget: $e');
    }
  }

  /// Update today's todo list widget display
  Future<void> _updateTodoListWidget() async {
    try {
      await HomeWidget.setAppGroupId('group.dodo.widget');

      final todoData = await getTodaysTodos();
      await HomeWidget.saveWidgetData<String>(
        'view_type',
        'todo_list',
      );
      await HomeWidget.saveWidgetData<String>(
        'todo_data',
        '',
      );

      // Notify native widget
      await HomeWidget.updateWidget(
        name: 'TodoListWidget',
        iOSName: 'TodoListWidget',
      );
    } catch (e) {
      print('Error updating todo list widget: $e');
    }
  }

  /// Refresh widget data (for background updates)
  Future<void> refreshWidget() async {
    await updateWidget();
  }

  /// Get next available update time
  DateTime getNextUpdateTime({Duration interval = const Duration(minutes: 30)}) {
    final config = getWidgetConfig();
    final lastUpdate = config.lastUpdated ?? DateTime.now();
    return lastUpdate.add(interval);
  }

  /// Check if widget should be updated (based on time interval)
  bool shouldUpdateWidget({Duration interval = const Duration(minutes: 15)}) {
    final config = getWidgetConfig();
    final lastUpdate = config.lastUpdated ?? DateTime.now();
    final now = DateTime.now();
    return now.difference(lastUpdate) >= interval;
  }

  /// Disable all widgets
  Future<void> disableAllWidgets() async {
    try {
      await HomeWidget.setAppGroupId('group.dodo.widget');
      await HomeWidget.saveWidgetData<String>('view_type', 'none');
      await setWidgetEnabled(false);
    } catch (e) {
      print('Error disabling widgets: $e');
    }
  }

  /// Clear widget data on logout
  Future<void> clearWidgetData() async {
    try {
      await HomeWidget.setAppGroupId('group.dodo.widget');
      await HomeWidget.saveWidgetData<String>('view_type', 'none');
      await HomeWidget.saveWidgetData<String>('calendar_data', '');
      await HomeWidget.saveWidgetData<String>('todo_data', '');
    } catch (e) {
      print('Error clearing widget data: $e');
    }
  }

  /// Reset widget configuration to defaults
  Future<void> resetConfiguration() async {
    await preferences.remove(_viewTypeKey);
    await preferences.remove(_enabledKey);
    await preferences.remove(_lastUpdateKey);
    await clearWidgetData();
  }
}
